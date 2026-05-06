"""Bounded agent session runtime.

This is intentionally practical rather than magical. Provider routing is used
when configured; contextual fallback preserves the same policy/audit contracts.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from typing import Any

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.config import Settings
from lifeos_api.db.models import (
    AgentRun,
    AgentSession,
    Handoff,
    MemoryCandidate,
    Message,
    ProviderCallLog,
    ReviewItem,
)
from lifeos_api.services.agentic_router import _provider_config_from_runtime
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.command_bus import CommandBus, CommandRequest
from lifeos_api.services.policy_engine import decide_capture_action
from lifeos_api.services.runtime_config import get_agent_autonomy, get_router_mode
from lifeos_api.services.status_events import create_status_event
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now
from lifeos_providers.router import ProviderCompletion, ProviderRouter

AGENTS = {
    "orchestrator",
    "capture-router",
    "approval-manager",
    "memory-curator",
    "daily-planner",
    "work.generic",
    "finance",
    "health-fitness",
    "deen-prayer",
    "family-commitments",
    "research",
    "systems-devops",
}

DOMAIN_AGENT = {
    "work": "work.generic",
    "finance": "finance",
    "health": "health-fitness",
    "deen": "deen-prayer",
    "family": "family-commitments",
    "research": "research",
    "system": "systems-devops",
    "memory": "memory-curator",
    "planning": "daily-planner",
}

SENSITIVE_DOMAINS = {"finance", "health", "family"}
CORRECTION_RE = re.compile(r"\b(actually|correction|wrong|instead|should be|don't|do not|not this|no,)\b", re.I)
AMBIGUOUS_RE = re.compile(r"\b(handle it|important stuff|deal with this|move this)\b", re.I)


@dataclass
class RuntimePlan:
    kind: str
    agent_id: str = "orchestrator"
    domain: str = "planning"
    title: str = "LifeOS chat"
    confidence: float = 0.8
    sensitivity: str = "normal"
    risk_level: str = "safe_internal_read"
    reason: str = "contextual routing"
    final_message_md: str | None = None
    proposed_action: dict[str, Any] = field(default_factory=dict)
    clarifying_questions: list[str] = field(default_factory=list)
    missing_context: list[dict[str, Any]] = field(default_factory=list)
    provider_meta: dict[str, Any] = field(default_factory=dict)


async def run_agent_message(
    *,
    session: AsyncSession,
    settings: Settings,
    agent_session: AgentSession,
    message_md: str,
    source_platform: str,
    external_channel_id: str | None = None,
    external_thread_id: str | None = None,
    external_message_id: str | None = None,
    user_id: str | None = None,
    metadata: dict[str, Any] | None = None,
) -> dict[str, Any]:
    now = utc_now()
    metadata = metadata or {}
    prior_run_id = agent_session.last_run_id

    user_message = Message(
        id=new_id("msg"),
        session_id=agent_session.id,
        run_id=None,
        role="user",
        content_md=message_md,
        content_json=None,
        source_platform=source_platform,
        source_external_channel_id=external_channel_id,
        source_external_thread_id=external_thread_id,
        source_external_message_id=external_message_id,
        metadata_json=metadata,
        created_at=now,
    )
    session.add(user_message)

    run = AgentRun(
        id=new_id("run"),
        session_id=agent_session.id,
        root_capture_id=None,
        initiating_user_id=user_id,
        orchestrator_agent_id="orchestrator",
        active_agent_id=agent_session.agent_id or "orchestrator",
        status="running",
        status_summary="Message received",
        provider_used=None,
        model_used=None,
        cost_usd=0,
        token_usage_json={"input_tokens": 0, "output_tokens": 0},
        trace_id=new_id("trace"),
        iteration_cap=agent_session.iteration_cap or 5,
        current_iteration=0,
        cancel_requested=False,
        cancelled_at=None,
        result_json={},
        created_at=now,
        updated_at=now,
        finished_at=None,
    )
    session.add(run)
    await session.flush()
    user_message.run_id = run.id

    await create_status_event(
        session,
        run_id=run.id,
        event_type="run.created",
        title="Run created",
        visibility="web_only",
        detail_json={"session_id": agent_session.id, "iteration_cap": run.iteration_cap},
    )
    await create_status_event(
        session,
        run_id=run.id,
        event_type="message.received",
        title="Received message",
        visibility="discord_compact",
        detail_json={"message_id": user_message.id, "source_platform": source_platform},
    )

    if not await _start_iteration(session, run, "Understand request"):
        return await _finish_max_iterations(session, agent_session, run, user_message)

    plan = await _build_plan(
        session=session,
        settings=settings,
        run=run,
        agent_session=agent_session,
        message_md=message_md,
        prior_run_id=prior_run_id,
        source_platform=source_platform,
    )
    run.active_agent_id = plan.agent_id
    run.provider_used = plan.provider_meta.get("provider")
    run.model_used = plan.provider_meta.get("model")

    await create_status_event(
        session,
        run_id=run.id,
        event_type="intent.classified",
        title=f"Intent: {plan.kind}",
        visibility="discord_compact",
        detail_json={
            "agent_id": plan.agent_id,
            "domain": plan.domain,
            "confidence": plan.confidence,
            "risk_level": plan.risk_level,
            "reason": plan.reason,
        },
    )
    await create_status_event(
        session,
        run_id=run.id,
        event_type="agent.selected",
        title=f"Agent selected: {plan.agent_id}",
        visibility="discord_compact",
        detail_json={"agent_id": plan.agent_id},
    )
    await create_status_event(
        session,
        run_id=run.id,
        event_type="plan.created",
        title=plan.title,
        visibility="web_only",
        detail_json={"kind": plan.kind, "proposed_action": plan.proposed_action},
    )

    if plan.kind == "direct":
        result = _result(
            status="final",
            final_message_md=plan.final_message_md or "Done.",
            what_i_did_md="- Answered directly from session context.",
            status_summary="Answered directly",
        )
        return await _finish_run(session, agent_session, run, user_message, result)

    if plan.kind == "clarification":
        await create_status_event(
            session,
            run_id=run.id,
            event_type="clarification.required",
            title="Clarification required",
            visibility="discord_compact",
            detail_json={"questions": plan.clarifying_questions},
        )
        result = _result(
            status="needs_clarification",
            final_message_md=_clarification_message(plan),
            what_i_did_md="- Paused the run until you answer.",
            clarifying_questions=plan.clarifying_questions,
            status_summary="Needs clarification",
        )
        agent_session.paused_run_id = run.id
        return await _finish_run(session, agent_session, run, user_message, result, terminal_status="needs_clarification")

    if not await _start_iteration(session, run, "Act or escalate"):
        return await _finish_max_iterations(session, agent_session, run, user_message)

    handoff_payload = await _maybe_handoff(session, run, plan, message_md)
    if plan.kind == "correction":
        result = await _apply_correction(
            session=session,
            settings=settings,
            agent_session=agent_session,
            run=run,
            message_md=message_md,
            prior_run_id=prior_run_id,
            user_message_id=user_message.id,
        )
    elif plan.kind == "preference":
        result = await _create_preference_candidate(session, run, plan, message_md, user_message.id)
    elif plan.kind == "review":
        result = await _create_review(session, run, plan)
    else:
        result = await _apply_or_escalate(session, settings, run, plan)

    if handoff_payload:
        result["handoffs"] = [handoff_payload, *result.get("handoffs", [])]
    return await _finish_run(session, agent_session, run, user_message, result)


async def _start_iteration(session: AsyncSession, run: AgentRun, title: str) -> bool:
    if run.current_iteration >= run.iteration_cap:
        return False
    run.current_iteration += 1
    await create_status_event(
        session,
        run_id=run.id,
        event_type="agent.iteration_started",
        title=title,
        visibility="discord_compact",
        detail_json={"iteration": run.current_iteration, "iteration_cap": run.iteration_cap},
    )
    return True


async def _build_plan(
    *,
    session: AsyncSession,
    settings: Settings,
    run: AgentRun,
    agent_session: AgentSession,
    message_md: str,
    prior_run_id: str | None,
    source_platform: str,
) -> RuntimePlan:
    if CORRECTION_RE.search(message_md) and prior_run_id:
        await create_status_event(
            session,
            run_id=run.id,
            event_type="correction.received",
            title="Correction received",
            visibility="discord_compact",
            detail_json={"prior_run_id": prior_run_id},
        )
        return RuntimePlan(
            kind="correction",
            agent_id=agent_session.agent_id if agent_session.agent_id != "orchestrator" else "approval-manager",
            domain="preference",
            title="Correction received",
            risk_level="reversible_internal_write",
            confidence=0.86,
            reason="follow-up correction pattern",
        )

    smalltalk_plan = _smalltalk_plan(agent_session, message_md)
    if smalltalk_plan is not None:
        return smalltalk_plan

    provider_plan = await _plan_with_provider(
        session=session,
        settings=settings,
        run=run,
        agent_session=agent_session,
        message_md=message_md,
        source_platform=source_platform,
    )
    if provider_plan is not None:
        return provider_plan

    return _fallback_plan(agent_session, message_md)


async def _plan_with_provider(
    *,
    session: AsyncSession,
    settings: Settings,
    run: AgentRun,
    agent_session: AgentSession,
    message_md: str,
    source_platform: str,
) -> RuntimePlan | None:
    mode = await get_router_mode(session, settings.router_mode)
    if mode == "deterministic":
        return None
    log_id = new_id("pcall")
    await create_status_event(
        session,
        run_id=run.id,
        event_type="provider.call_started",
        title="Provider planning started",
        visibility="web_only",
        detail_json={"agent_id": "orchestrator"},
    )
    try:
        config = await _provider_config_from_runtime(session)
        completion = ProviderRouter(config=config).complete_json(
            "orchestrator",
            _planning_messages(agent_session=agent_session, message_md=message_md, source_platform=source_platform),
        )
        session.add(_provider_log(log_id, run.id, "orchestrator", completion, "succeeded"))
        await create_status_event(
            session,
            run_id=run.id,
            event_type="provider.call_finished",
            title="Provider planning finished",
            visibility="web_only",
            detail_json={"provider_call_log_id": log_id, "provider": completion.provider, "model": completion.model},
        )
        plan = _plan_from_provider_json(completion.content, message_md, agent_session)
        plan.provider_meta = {
            "provider": completion.provider,
            "model": completion.model,
            "provider_call_log_id": log_id,
            "fallback_used": False,
        }
        return plan
    except Exception as exc:  # noqa: BLE001 - chat should degrade to local policy
        session.add(
            ProviderCallLog(
                id=log_id,
                run_id=run.id,
                agent_id="orchestrator",
                provider_id="unavailable",
                model="orchestrator-planner",
                key_label=None,
                status="failed",
                latency_ms=0,
                input_tokens=0,
                output_tokens=0,
                cost_usd=0,
                error_json={"type": type(exc).__name__, "message": str(exc)[:1000]},
                created_at=utc_now(),
            )
        )
        await create_status_event(
            session,
            run_id=run.id,
            event_type="provider.fallback_used",
            title="Provider unavailable; contextual fallback used",
            visibility="discord_compact",
            detail_json={"error": str(exc)[:500]},
        )
        if mode == "agentic":
            return RuntimePlan(
                kind="direct",
                agent_id="orchestrator",
                title="Provider unavailable",
                final_message_md="Provider routing is required but unavailable. Check provider settings.",
                risk_level="safe_internal_read",
                confidence=0.0,
                provider_meta={"provider": "unavailable", "model": "orchestrator-planner", "fallback_used": True},
            )
        return None


def _planning_messages(
    *,
    agent_session: AgentSession,
    message_md: str,
    source_platform: str,
) -> list[dict[str, str]]:
    system = (
        "You are LifeOS Orchestrator. Return strict JSON only. "
        "Use escalation-gated autonomy: low-risk reversible actions can complete; "
        "ambiguous, sensitive, external, destructive, or hard-to-reverse actions need clarification/review. "
        "No keyword-only routing. Consider active agent, session, channel, risk, and user correction patterns."
    )
    payload = {
        "source_platform": source_platform,
        "active_agent_id": agent_session.agent_id,
        "session_title": agent_session.title,
        "message": message_md,
        "available_agents": sorted(AGENTS),
        "schema": {
            "kind": "direct|autonomous_action|review|clarification|preference",
            "agent_id": "orchestrator|work.generic|finance|health-fitness|deen-prayer|family-commitments|research|systems-devops|daily-planner|memory-curator|approval-manager",
            "domain": "planning|work|finance|health|deen|family|research|system|memory|preference",
            "title": "short title",
            "reason": "short routing reason",
            "confidence": 0.0,
            "sensitivity": "normal|finance|health|family|secret",
            "risk_level": "safe_internal_read|reversible_internal_write|durable_state_mutation|finance_mutation|external_side_effect|destructive_or_sensitive_action",
            "final_message_md": "for direct only",
            "clarifying_questions": [],
            "proposed_action": {"command_type": "life_item.create", "risk_level": "reversible_internal_write", "payload": {}},
        },
    }
    return [{"role": "system", "content": system}, {"role": "user", "content": json.dumps(payload)}]


def _plan_from_provider_json(content: str, message_md: str, agent_session: AgentSession) -> RuntimePlan:
    parsed = json.loads(content)
    agent_id = str(parsed.get("agent_id") or agent_session.agent_id or "orchestrator")
    if agent_id not in AGENTS:
        agent_id = "orchestrator"
    kind = str(parsed.get("kind") or "direct")
    if kind not in {"direct", "autonomous_action", "review", "clarification", "preference"}:
        kind = "direct"
    action = parsed.get("proposed_action") if isinstance(parsed.get("proposed_action"), dict) else {}
    if kind == "autonomous_action" and not action:
        action = _life_item_action(
            message_md,
            domain=str(parsed.get("domain") or "planning"),
            item_type="note",
            risk_level="reversible_internal_write",
        )
    return RuntimePlan(
        kind=kind,
        agent_id=agent_id,
        domain=str(parsed.get("domain") or _domain_for_agent(agent_id)),
        title=str(parsed.get("title") or "LifeOS chat")[:200],
        confidence=float(parsed.get("confidence") or 0.75),
        sensitivity=str(parsed.get("sensitivity") or "normal"),
        risk_level=str(parsed.get("risk_level") or action.get("risk_level") or "safe_internal_read"),
        reason=str(parsed.get("reason") or "provider plan"),
        final_message_md=parsed.get("final_message_md"),
        proposed_action=action,
        clarifying_questions=[str(item) for item in parsed.get("clarifying_questions", [])],
        missing_context=[{"question": str(item)} for item in parsed.get("clarifying_questions", [])],
    )


def _fallback_plan(agent_session: AgentSession, message_md: str) -> RuntimePlan:
    text = message_md.strip()
    lower = text.lower()
    active = agent_session.agent_id if agent_session.agent_id in AGENTS else "orchestrator"
    domain = _infer_domain(lower, active)
    agent_id = active if active != "orchestrator" else DOMAIN_AGENT.get(domain, "orchestrator")

    if AMBIGUOUS_RE.search(lower):
        return RuntimePlan(
            kind="clarification",
            agent_id=agent_id,
            domain=domain,
            title="Clarification needed",
            confidence=0.52,
            risk_level="durable_state_mutation",
            reason="goal/action ambiguous",
            clarifying_questions=[
                "Which domain should this belong to?",
                "Should I create a task, reminder, note, or send it to a specialist?",
            ],
        )

    if any(token in lower for token in ["summarize", "what is", "explain", "status"]):
        return RuntimePlan(
            kind="direct",
            agent_id=agent_id if agent_id != "orchestrator" else "orchestrator",
            domain=domain,
            title="Direct answer",
            final_message_md=(
                "I can handle this in the current session. "
                "No durable state change was needed for this message."
            ),
            reason="read-only/direct request",
        )

    if _looks_like_preference(lower):
        return RuntimePlan(
            kind="preference",
            agent_id="memory-curator",
            domain="preference",
            title="Preference candidate",
            confidence=0.84,
            risk_level="reversible_internal_write",
            reason="low-risk behavior preference",
        )

    if domain in SENSITIVE_DOMAINS or _looks_high_impact(lower):
        return RuntimePlan(
            kind="review",
            agent_id=agent_id,
            domain=domain,
            title=_title(text, f"{domain.title()} review"),
            confidence=0.78,
            sensitivity=domain if domain in SENSITIVE_DOMAINS else "normal",
            risk_level="finance_mutation" if domain == "finance" else "durable_state_mutation",
            reason="sensitive or high-impact domain",
            proposed_action=_life_item_action(
                text,
                domain=domain,
                item_type="review",
                risk_level="finance_mutation" if domain == "finance" else "durable_state_mutation",
            ),
        )

    item_type = "task" if any(token in lower for token in ["todo", "task", "remind", "follow up"]) else "note"
    return RuntimePlan(
        kind="autonomous_action",
        agent_id=agent_id,
        domain=domain,
        title=_title(text, "LifeOS note"),
        confidence=0.82,
        risk_level="reversible_internal_write",
        reason="low-risk reversible session action",
        proposed_action=_life_item_action(text, domain=domain, item_type=item_type, risk_level="reversible_internal_write"),
    )


def _smalltalk_plan(agent_session: AgentSession, message_md: str) -> RuntimePlan | None:
    text = " ".join(message_md.strip().lower().split())
    if not text:
        return RuntimePlan(
            kind="direct",
            agent_id=agent_session.agent_id if agent_session.agent_id in AGENTS else "orchestrator",
            domain="planning",
            title="Empty message",
            final_message_md="I got an empty message. Send me what you want LifeOS to handle.",
            reason="empty message",
        )
    if re.fullmatch(r"(hi|hey|hello|yo|salam|as-salamu alaykum|assalamu alaikum|thanks|thank you)[!. ]*", text):
        return RuntimePlan(
            kind="direct",
            agent_id=agent_session.agent_id if agent_session.agent_id in AGENTS else "orchestrator",
            domain="planning",
            title="Greeting",
            final_message_md=(
                "Hey. I am here.\n\n"
                "Send a task, note, question, or correction and I will route it through LifeOS."
            ),
            reason="smalltalk/no-op message",
        )
    return None


async def _maybe_handoff(
    session: AsyncSession,
    run: AgentRun,
    plan: RuntimePlan,
    message_md: str,
) -> dict[str, Any] | None:
    if plan.agent_id in {"orchestrator", "approval-manager", "memory-curator"}:
        return None
    now = utc_now()
    handoff = Handoff(
        id=new_id("hnd"),
        parent_run_id=run.id,
        from_agent_id="orchestrator",
        to_agent_id=plan.agent_id,
        reason=plan.reason,
        task_md=f"Handle session message:\n\n{message_md}",
        known_context=[{"kind": "session", "id": run.session_id}],
        context_refs=[{"kind": "message", "run_id": run.id}],
        constraints=[{"kind": "policy", "value": "escalate risky or ambiguous actions"}],
        expected_output_schema={"type": "agent_run_result"},
        result_json={},
        summary_md=None,
        risk_level=plan.risk_level,
        status="accepted",
        visibility="discord_compact",
        requires_user_visibility=True,
        discord_summary_posted=False,
        created_at=now,
        updated_at=now,
        completed_at=None,
    )
    session.add(handoff)
    await create_status_event(
        session,
        run_id=run.id,
        event_type="handoff.created",
        title=f"Orchestrator -> {plan.agent_id}",
        visibility="discord_compact",
        detail_json={"handoff_id": handoff.id, "reason": plan.reason},
    )
    await create_status_event(
        session,
        run_id=run.id,
        event_type="handoff.accepted",
        title=f"{plan.agent_id} accepted task",
        visibility="web_only",
        detail_json={"handoff_id": handoff.id},
    )
    handoff.status = "completed"
    handoff.summary_md = f"{plan.agent_id} produced a {plan.kind} plan."
    handoff.result_json = {"kind": plan.kind, "domain": plan.domain}
    handoff.completed_at = utc_now()
    handoff.updated_at = handoff.completed_at
    await create_status_event(
        session,
        run_id=run.id,
        event_type="handoff.completed",
        title=f"{plan.agent_id} completed task",
        visibility="discord_compact",
        detail_json={"handoff_id": handoff.id},
    )
    return {
        "handoff_id": handoff.id,
        "from_agent_id": handoff.from_agent_id,
        "to_agent_id": handoff.to_agent_id,
        "status": handoff.status,
        "summary_md": handoff.summary_md,
    }


async def _apply_or_escalate(
    session: AsyncSession,
    settings: Settings,
    run: AgentRun,
    plan: RuntimePlan,
) -> dict[str, Any]:
    autonomy = await get_agent_autonomy(session, plan.agent_id)
    policy = decide_capture_action(
        action=plan.proposed_action,
        confidence=plan.confidence,
        sensitivity=plan.sensitivity,
        autonomy_mode=autonomy,
        owner_authenticated=True,
        missing_context=plan.missing_context,
        intent_labels=["session_action"],
    )
    await create_status_event(
        session,
        run_id=run.id,
        event_type="policy.decision",
        title=f"Policy: {policy.decision}",
        visibility="discord_compact",
        detail_json=policy.as_dict(),
    )
    if policy.decision != "auto_apply":
        plan.reason = policy.reason
        return await _create_review(session, run, plan)

    command_result = await CommandBus(session, settings).apply(
        CommandRequest(
            command_type=str(plan.proposed_action["command_type"]),
            payload=dict(plan.proposed_action.get("payload", {})),
            source_review_item_id=None,
            actor_type="agent",
            actor_id=plan.agent_id,
        )
    )
    action = {
        "command_type": command_result.command_type,
        "state_change_id": command_result.state_change_id,
        "entity_type": command_result.entity_type,
        "entity_id": command_result.entity_id,
        "status": str(command_result.status),
    }
    await create_status_event(
        session,
        run_id=run.id,
        event_type="autonomous.action.completed",
        title=f"Completed {command_result.command_type}",
        visibility="discord_compact",
        detail_json=action,
    )
    return _result(
        status="final",
        final_message_md="Done.\n\nWhat I did:\n- Added this to LifeOS working state.\n- Kept the original session message as evidence.\n- No review card was needed.",
        what_i_did_md="- Added this to LifeOS working state.\n- Preserved the session message.\n- Audited the state change.",
        autonomous_actions=[action],
        audit_refs=[command_result.audit_event_id] if command_result.audit_event_id else [],
        status_summary=f"Auto-applied {command_result.command_type}",
    )


async def _create_review(session: AsyncSession, run: AgentRun, plan: RuntimePlan) -> dict[str, Any]:
    now = utc_now()
    review = ReviewItem(
        id=new_id("rev"),
        kind=plan.domain,
        title=plan.title,
        body_md=_review_body(plan),
        source_capture_id=None,
        source_uri=None,
        proposed_by_agent_id=plan.agent_id,
        assigned_agent_id="approval-manager",
        priority="normal",
        confidence=plan.confidence,
        risk_level=plan.risk_level,
        sensitivity=plan.sensitivity,
        proposed_action_json=plan.proposed_action or {"command_type": "none", "risk_level": plan.risk_level, "payload": {}},
        validation_json={"reason": plan.reason, "missing_context": plan.missing_context},
        status="pending",
        expires_at=None,
        snoozed_until=None,
        created_at=now,
        updated_at=now,
    )
    session.add(review)
    await session.flush()
    await create_status_event(
        session,
        run_id=run.id,
        event_type="review.created",
        title=f"Review created: {review.title}",
        visibility="discord_compact",
        detail_json={"review_item_id": review.id, "risk_level": review.risk_level},
    )
    return _result(
        status="needs_approval",
        final_message_md=(
            "This needs review before I change durable or sensitive state.\n\n"
            f"Review: `{review.id}`\n"
            f"Reason: {plan.reason}"
        ),
        what_i_did_md="- Created a review item.\n- Paused before risky or sensitive mutation.",
        review_item_id=review.id,
        status_summary="Review required",
    )


async def _create_preference_candidate(
    session: AsyncSession,
    run: AgentRun,
    plan: RuntimePlan,
    message_md: str,
    evidence_message_id: str,
) -> dict[str, Any]:
    candidate = await _write_preference_candidate(
        session,
        run,
        statement=f"User preference: {message_md.strip()}",
        evidence_message_id=evidence_message_id,
        kind="preference",
        status="auto_learned",
    )
    return _result(
        status="final",
        final_message_md=(
            "Got it.\n\n"
            "What I did:\n"
            "- Added a low-risk preference candidate.\n"
            "- Kept it out of sensitive durable memory."
        ),
        what_i_did_md="- Created a low-risk preference candidate.",
        preference_candidates=[{"candidate_id": candidate.id, "status": candidate.status}],
        status_summary=plan.title,
    )


async def _apply_correction(
    *,
    session: AsyncSession,
    settings: Settings,
    agent_session: AgentSession,
    run: AgentRun,
    message_md: str,
    prior_run_id: str | None,
    user_message_id: str,
) -> dict[str, Any]:
    prior_run = await session.get(AgentRun, prior_run_id) if prior_run_id else None
    lower = message_md.lower()
    changed: list[str] = []
    actions: list[dict[str, Any]] = []

    target = _target_life_item(prior_run.result_json if prior_run else {})
    updates: dict[str, Any] = {}
    if target and "note" in lower and ("reminder" in lower or "task" in lower):
        updates.update({"item_type": "note", "due_at": None, "scheduled_at": None})
        changed.append("Converted prior item to a note and cleared reminder timing.")
    domain = _domain_correction(lower)
    if target and domain:
        updates["domain"] = domain
        changed.append(f"Changed domain to {domain}.")

    if target and updates:
        command_result = await CommandBus(session, settings).apply(
            CommandRequest(
                command_type="life_item.update",
                payload={"item_id": target, "updates": updates},
                actor_type="agent",
                actor_id="approval-manager",
            )
        )
        actions.append(
            {
                "command_type": "life_item.update",
                "state_change_id": command_result.state_change_id,
                "entity_type": command_result.entity_type,
                "entity_id": command_result.entity_id,
                "status": str(command_result.status),
            }
        )

    candidate = await _write_preference_candidate(
        session,
        run,
        statement=_correction_preference(message_md),
        evidence_message_id=user_message_id,
        kind="routing_preference" if domain else "preference",
        status="auto_learned",
    )
    changed.append("Added a low-risk preference candidate for future behavior.")
    agent_session.last_user_correction_id = user_message_id
    agent_session.paused_run_id = None

    await create_status_event(
        session,
        run_id=run.id,
        event_type="correction.applied",
        title="Correction applied",
        visibility="discord_compact",
        detail_json={"changed": changed, "preference_candidate_id": candidate.id},
    )
    return _result(
        status="final",
        final_message_md="Got it. I fixed what was safe to fix.\n\nChanged:\n"
        + "\n".join(f"- {item}" for item in changed),
        what_i_did_md="\n".join(f"- {item}" for item in changed),
        autonomous_actions=actions,
        preference_candidates=[{"candidate_id": candidate.id, "status": candidate.status}],
        status_summary="Correction applied",
    )


async def _write_preference_candidate(
    session: AsyncSession,
    run: AgentRun,
    *,
    statement: str,
    evidence_message_id: str,
    kind: str,
    status: str,
) -> MemoryCandidate:
    now = utc_now()
    candidate = MemoryCandidate(
        id=new_id("memcand"),
        source_capture_id=None,
        proposed_by_agent_id="memory-curator",
        candidate_kind=kind,
        statement_md=statement[:1000],
        evidence_refs=[{"kind": "message", "id": evidence_message_id, "run_id": run.id}],
        confidence=0.82,
        sensitivity="normal",
        status=status,
        review_item_id=None,
        created_at=now,
        updated_at=now,
    )
    session.add(candidate)
    await create_status_event(
        session,
        run_id=run.id,
        event_type="preference_candidate.created",
        title="Preference candidate created",
        visibility="discord_compact",
        detail_json={"candidate_id": candidate.id, "status": status},
    )
    return candidate


async def _finish_max_iterations(
    session: AsyncSession,
    agent_session: AgentSession,
    run: AgentRun,
    user_message: Message,
) -> dict[str, Any]:
    result = _result(
        status="max_iterations",
        final_message_md=(
            f"I reached the {run.iteration_cap}-iteration cap.\n\n"
            "What I completed:\n"
            "- Received and recorded your message.\n\n"
            "What is incomplete:\n"
            "- I did not finish the action. Reply `continue` or raise `/lifeos iterations`."
        ),
        what_i_did_md="- Recorded the message.\n- Stopped at iteration cap.",
        status_summary="Max iterations reached",
    )
    await create_status_event(
        session,
        run_id=run.id,
        event_type="run.max_iterations_reached",
        title="Max iterations reached",
        visibility="discord_compact",
        detail_json={"iteration_cap": run.iteration_cap},
    )
    return await _finish_run(session, agent_session, run, user_message, result, terminal_status="max_iterations")


async def _finish_run(
    session: AsyncSession,
    agent_session: AgentSession,
    run: AgentRun,
    user_message: Message,
    result: dict[str, Any],
    *,
    terminal_status: str | None = None,
) -> dict[str, Any]:
    now = utc_now()
    status = terminal_status or _run_status_from_result(str(result["status"]))
    run.status = status
    run.status_summary = str(result.get("status_summary") or result["status"])
    run.result_json = result
    run.finished_at = now if status not in {"needs_clarification", "waiting_approval"} else None
    run.updated_at = now
    agent_session.last_run_id = run.id
    agent_session.updated_at = now
    if status != "needs_clarification":
        agent_session.paused_run_id = None

    assistant_message = Message(
        id=new_id("msg"),
        session_id=agent_session.id,
        run_id=run.id,
        role="assistant",
        content_md=str(result.get("final_message_md") or ""),
        content_json=result,
        source_platform="lifeos",
        source_external_channel_id=None,
        source_external_thread_id=None,
        source_external_message_id=None,
        metadata_json={},
        created_at=now,
    )
    session.add(assistant_message)

    await create_status_event(
        session,
        run_id=run.id,
        event_type="run.completed" if status not in {"failed", "max_iterations"} else f"run.{status}",
        title=run.status_summary or "Run completed",
        visibility="discord_compact",
        detail_json={"status": status, "assistant_message_id": assistant_message.id},
    )
    await create_audit_event(
        session,
        actor_type="agent",
        actor_id=run.active_agent_id or "orchestrator",
        event_type="agent_session.message_processed",
        entity_type="agent_run",
        entity_id=run.id,
        summary=run.status_summary or "Agent run completed",
        after_json={
            "session_id": agent_session.id,
            "user_message_id": user_message.id,
            "result": result,
        },
        trace_id=run.trace_id,
    )
    await session.commit()
    return {
        "ok": True,
        "session_id": agent_session.id,
        "run_id": run.id,
        "message_id": assistant_message.id,
        "agent_id": run.active_agent_id,
        "status": status,
        "answer": result.get("final_message_md"),
        "result": result,
    }


def _result(
    *,
    status: str,
    final_message_md: str | None,
    what_i_did_md: str | None,
    review_item_id: str | None = None,
    clarifying_questions: list[str] | None = None,
    tool_calls: list[dict[str, Any]] | None = None,
    handoffs: list[dict[str, Any]] | None = None,
    autonomous_actions: list[dict[str, Any]] | None = None,
    memory_candidates: list[dict[str, Any]] | None = None,
    preference_candidates: list[dict[str, Any]] | None = None,
    audit_refs: list[str] | None = None,
    status_summary: str = "",
) -> dict[str, Any]:
    return {
        "status": status,
        "final_message_md": final_message_md,
        "what_i_did_md": what_i_did_md,
        "review_item_id": review_item_id,
        "clarifying_questions": clarifying_questions or [],
        "tool_calls": tool_calls or [],
        "handoffs": handoffs or [],
        "autonomous_actions": autonomous_actions or [],
        "memory_candidates": memory_candidates or [],
        "preference_candidates": preference_candidates or [],
        "audit_refs": audit_refs or [],
        "status_summary": status_summary,
    }


def _run_status_from_result(result_status: str) -> str:
    return {
        "final": "completed",
        "needs_clarification": "needs_clarification",
        "needs_approval": "waiting_approval",
        "failed": "failed",
        "max_iterations": "max_iterations",
    }.get(result_status, "completed")


def _provider_log(
    log_id: str,
    run_id: str,
    agent_id: str,
    completion: ProviderCompletion,
    status: str,
) -> ProviderCallLog:
    return ProviderCallLog(
        id=log_id,
        run_id=run_id,
        agent_id=agent_id,
        provider_id=completion.provider,
        model=completion.model,
        key_label=completion.key_label,
        status=status,
        latency_ms=completion.latency_ms,
        input_tokens=completion.input_tokens,
        output_tokens=completion.output_tokens,
        cost_usd=0,
        error_json=None,
        created_at=utc_now(),
    )


def _life_item_action(text: str, *, domain: str, item_type: str, risk_level: str) -> dict[str, Any]:
    return {
        "command_type": "life_item.create",
        "risk_level": risk_level,
        "payload": {
            "domain": domain,
            "item_type": item_type,
            "title": _title(text, "LifeOS item"),
            "description_md": text,
            "priority": "normal",
            "status": "open",
            "metadata": {"source": "agent_session"},
        },
    }


def _review_body(plan: RuntimePlan) -> str:
    return "\n".join(
        [
            "I need review before acting.",
            "",
            f"Understood: {plan.title}",
            f"Agent: `{plan.agent_id}`",
            f"Risk: `{plan.risk_level}`",
            f"Reason: {plan.reason}",
        ]
    )


def _clarification_message(plan: RuntimePlan) -> str:
    questions = "\n".join(f"{idx}. {question}" for idx, question in enumerate(plan.clarifying_questions, start=1))
    return (
        "I need one clarification before acting.\n\n"
        "What I understood:\n"
        f"- Domain: {plan.domain}\n"
        f"- Suggested agent: {plan.agent_id}\n\n"
        "What is unclear:\n"
        "- The exact action or destination could change the result.\n\n"
        f"Please answer:\n{questions}"
    )


def _infer_domain(lower: str, active_agent_id: str) -> str:
    active_domain = _domain_for_agent(active_agent_id)
    if active_agent_id != "orchestrator" and active_domain != "system":
        return active_domain
    scores = {
        "finance": _score(lower, ["money", "finance", "spent", "paid", "transfer", "$", "mad", "usd", "bank"]),
        "health": _score(lower, ["health", "gym", "workout", "sleep", "meal", "water", "medicine"]),
        "family": _score(lower, ["family", "wife", "parents", "mother", "father", "call my", "visit"]),
        "deen": _score(lower, ["prayer", "fajr", "dhuhr", "asr", "maghrib", "isha", "quran"]),
        "research": _score(lower, ["research", "find", "compare", "source", "investigate"]),
        "work": _score(lower, ["work", "deadline", "submit", "client", "project", "blocker"]),
        "system": _score(lower, ["repo", "server", "deploy", "terminal", "docker", "bug", "test"]),
    }
    domain, score = max(scores.items(), key=lambda item: item[1])
    return domain if score > 0 else "planning"


def _domain_for_agent(agent_id: str) -> str:
    for domain, mapped_agent in DOMAIN_AGENT.items():
        if mapped_agent == agent_id:
            return domain
    return "system" if agent_id in {"orchestrator", "approval-manager"} else "planning"


def _score(lower: str, tokens: list[str]) -> int:
    return sum(1 for token in tokens if token in lower)


def _looks_like_preference(lower: str) -> bool:
    return any(
        token in lower
        for token in [
            "i prefer",
            "prefer ",
            "always ",
            "never ",
            "do not ",
            "don't ",
            "for future",
            "from now on",
        ]
    )


def _looks_high_impact(lower: str) -> bool:
    return any(token in lower for token in ["send ", "post ", "delete", "transfer", "pay ", "deploy", "credential"])


def _title(text: str, fallback: str) -> str:
    compact = " ".join(text.split())
    return (compact[:80].rstrip() if compact else fallback) or fallback


def _target_life_item(result_json: dict[str, Any]) -> str | None:
    for action in result_json.get("autonomous_actions", []):
        if action.get("entity_type") == "life_item" and action.get("entity_id"):
            return str(action["entity_id"])
    return None


def _domain_correction(lower: str) -> str | None:
    for domain in ["family", "health", "work", "finance", "research", "planning", "deen"]:
        if f"under {domain}" in lower or f"{domain}, not" in lower or f"should be {domain}" in lower:
            return domain
    return None


def _correction_preference(message_md: str) -> str:
    text = message_md.strip()
    if "reminder" in text.lower() and ("do not" in text.lower() or "don't" in text.lower()):
        return "User preference: do not create reminders for similar notes unless explicitly requested."
    return f"User correction preference: {text}"
