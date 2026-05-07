"""Structured planner for Discord-first conversational actions.

The planner is intentionally side-effect free. It returns validated action
plans; persistence, command execution, reviews, and audit all stay in the API
services that already own durable state.
"""

from __future__ import annotations

import re
from datetime import datetime, time, timedelta
from typing import Any, Literal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, ConfigDict, Field, ValidationError


ActionType = Literal[
    "task.create",
    "task.update",
    "task.complete",
    "reminder.create",
    "job.create_once",
    "job.create_recurring",
    "daily_log.create",
    "memory_candidate.create",
    "research.start",
    "file.read",
    "file.write_proposal",
    "terminal.run_proposal",
    "agent.handoff",
]
RiskLevel = Literal["low", "medium", "high", "sensitive", "destructive"]
PlanMode = Literal["answer_only", "execute_now", "propose_inline", "formal_review", "clarify"]
FollowUpKind = Literal["none", "approve", "reject", "revise", "ask"]


class ConversationActionProposal(BaseModel):
    model_config = ConfigDict(extra="ignore")

    type: ActionType
    summary: str
    confidence: float = Field(ge=0.0, le=1.0)
    risk: RiskLevel
    requires_confirmation: bool
    formal_review_required: bool
    draft: dict[str, Any]
    reason: str | None = None


class ConversationTurnPlan(BaseModel):
    model_config = ConfigDict(extra="ignore")

    mode: PlanMode
    assistant_reply: str
    proposals: list[ConversationActionProposal] = Field(default_factory=list)
    memory_candidates: list[dict[str, Any]] = Field(default_factory=list)
    clarifying_question: str | None = None
    status_events: list[str] = Field(default_factory=list)


class ProposalFollowUpPlan(BaseModel):
    kind: FollowUpKind
    assistant_reply: str | None = None
    proposal_indexes: list[int] = Field(default_factory=list)
    revision_text: str | None = None


STRICT_JSON_INSTRUCTIONS = (
    "Return strict JSON matching ConversationTurnPlan. Do not include markdown outside JSON. "
    "Use execute_now only for explicit low-risk task/reminder/task-complete commands. "
    "Use propose_inline for inferred useful actions. Use formal_review for recurring, memory, "
    "sensitive, destructive, file, terminal, provider, external side-effect, or hard-to-reverse actions. "
    "Use answer_only for questions/advice/conversation."
)


WEEKDAYS = {
    "monday": 0,
    "tuesday": 1,
    "wednesday": 2,
    "thursday": 3,
    "friday": 4,
    "saturday": 5,
    "sunday": 6,
}
QUESTION_STARTS = (
    "what ",
    "why ",
    "how ",
    "when ",
    "where ",
    "who ",
    "which ",
    "can you explain",
    "give me ",
    "suggest ",
    "recommend ",
)
EXPLICIT_TASK_RE = re.compile(r"^(create|add|make)\s+(a\s+)?(task|todo)\b", re.I)
EXPLICIT_REMINDER_RE = re.compile(r"^(remind me|set (a )?reminder|create (a )?reminder)\b", re.I)
EXPLICIT_COMPLETE_RE = re.compile(r"^(mark|complete|finish)\b", re.I)
IMPLICIT_ACTION_RE = re.compile(r"\b(i need to|need to|i should|should|have to|got to)\b", re.I)
MEMORY_RE = re.compile(r"\b(remember that|remember this|i prefer|my preference|from now on|always|never)\b", re.I)
RECURRING_RE = re.compile(r"\b(every|daily|weekly|monthly|weekdays|weekend|each)\b", re.I)
DESTRUCTIVE_RE = re.compile(r"\b(delete|remove permanently|wipe|destroy|drop table|reset|factory reset)\b", re.I)
FILE_TERMINAL_RE = re.compile(
    r"\b(terminal|shell|command line|bash|run `|run npm|run docker|write file|edit file|read file|"
    r"open file|provider|model setting|api key|credential|send email|post to|transfer|pay)\b",
    re.I,
)
APPROVE_RE = re.compile(r"^(yes|yep|yeah|do it|go ahead|create it|create them|add it|add them|sure|ok|okay)$", re.I)
REJECT_RE = re.compile(r"^(no|nope|ignore|ignore it|cancel|cancel it|don't|do not|never mind|nevermind)$", re.I)
ASK_RE = re.compile(r"\b(what exactly|what will|show me|details|what are you|what would)\b", re.I)
REVISE_RE = re.compile(r"\b(make it|change|instead|only|first|second|third|saturday|sunday|monday|tomorrow|morning|evening)\b", re.I)
ORPHAN_REVISION_RE = re.compile(r"^(make|change|only|instead)\b", re.I)


async def plan_conversation_turn(
    *,
    agent_name: str,
    user_message: str,
    session_id: str | None,
    source: str,
    recent_context: list[dict[str, Any]],
    state_packet: dict[str, Any] | None,
    timezone: str,
    llm_plan_json: str | None = None,
) -> ConversationTurnPlan:
    """Plan one conversational turn without mutating durable state.

    When a caller supplies provider JSON, it is strictly validated first. Invalid
    JSON falls back to the local safe planner for clear policy-covered messages;
    the local planner never writes state itself.
    """

    if llm_plan_json is not None:
        try:
            parsed = ConversationTurnPlan.model_validate_json(llm_plan_json)
        except (ValidationError, ValueError):
            return enforce_conversation_policy(
                _deterministic_plan(user_message, timezone=timezone),
                user_message=user_message,
                timezone=timezone,
            )
        return enforce_conversation_policy(parsed, user_message=user_message, timezone=timezone)

    _ = (agent_name, session_id, source, recent_context, state_packet)
    return enforce_conversation_policy(
        _deterministic_plan(user_message, timezone=timezone),
        user_message=user_message,
        timezone=timezone,
    )


def enforce_conversation_policy(
    plan: ConversationTurnPlan,
    *,
    user_message: str,
    timezone: str = "UTC",
) -> ConversationTurnPlan:
    """Apply deterministic safety policy after model planning."""

    lower = _norm(user_message)
    policy_override = _policy_override_plan(user_message, timezone=timezone)
    if policy_override is not None:
        if policy_override.mode == "formal_review":
            return policy_override
        if policy_override.mode == "clarify":
            return policy_override
        if plan.mode == "clarify" or not plan.proposals:
            return policy_override

    if _is_advice_or_question(lower) and not _is_explicit_action(lower):
        return ConversationTurnPlan(
            mode="answer_only",
            assistant_reply=plan.assistant_reply if plan.mode == "answer_only" else _advice_answer(user_message),
            status_events=["received_input", "understanding_request"],
        )

    proposals = [
        _sanitize_provider_proposal(_enforce_proposal_policy(item, user_message=lower), user_message, timezone=timezone)
        for item in plan.proposals
    ]
    if not proposals:
        if plan.mode in {"execute_now", "propose_inline", "formal_review"}:
            return ConversationTurnPlan(
                mode="clarify",
                assistant_reply="I need one detail before I can safely act. What should I create or change?",
                clarifying_question="What should I create or change?",
                status_events=[*plan.status_events, "waiting_for_confirmation"],
            )
        return plan

    if any(item.formal_review_required for item in proposals):
        return plan.model_copy(
            update={
                "mode": "formal_review",
                "proposals": proposals,
                "assistant_reply": plan.assistant_reply
                or "This needs formal review before I can change anything.",
                "status_events": _dedupe([*plan.status_events, "planned_action", "formal_review_created"]),
            }
        )

    if plan.mode == "execute_now":
        explicit = all(bool(item.draft.get("explicit")) for item in proposals)
        safe = all(item.risk == "low" and not item.requires_confirmation for item in proposals)
        if explicit and safe:
            return plan.model_copy(
                update={
                    "proposals": proposals,
                    "status_events": _dedupe([*plan.status_events, "planned_action", "executing_action"]),
                }
            )

    return plan.model_copy(
        update={
            "mode": "propose_inline",
            "proposals": [
                item.model_copy(update={"requires_confirmation": True, "formal_review_required": False})
                for item in proposals
            ],
            "assistant_reply": plan.assistant_reply
            or "I can create this. Please confirm first.",
            "status_events": _dedupe([*plan.status_events, "planned_action", "waiting_for_confirmation"]),
        }
    )


def _policy_override_plan(user_message: str, *, timezone: str) -> ConversationTurnPlan | None:
    lower = _norm(user_message)
    if ORPHAN_REVISION_RE.search(lower) and not EXPLICIT_TASK_RE.search(lower):
        return ConversationTurnPlan(
            mode="clarify",
            assistant_reply="I do not have a pending proposal to edit. What should I create or change?",
            clarifying_question="What should I create or change?",
            status_events=["received_input", "understanding_request"],
        )
    if DESTRUCTIVE_RE.search(lower) or FILE_TERMINAL_RE.search(lower):
        return _deterministic_plan(user_message, timezone=timezone)
    if MEMORY_RE.search(lower):
        return _deterministic_plan(user_message, timezone=timezone)
    if RECURRING_RE.search(lower) and ("remind me" in lower or "reminder" in lower):
        return _deterministic_plan(user_message, timezone=timezone)
    return None


def _sanitize_provider_proposal(
    proposal: ConversationActionProposal,
    user_message: str,
    *,
    timezone: str,
) -> ConversationActionProposal:
    lower = _norm(user_message)
    replacement: ConversationActionProposal | None = None
    if proposal.type == "task.create":
        if EXPLICIT_TASK_RE.search(lower):
            replacement = _explicit_task_plan(user_message, timezone=timezone, status_events=[]).proposals[0]
        elif IMPLICIT_ACTION_RE.search(lower):
            replacement = _implicit_task_plan(user_message, timezone=timezone, status_events=[]).proposals[0]
    elif proposal.type in {"reminder.create", "job.create_once"} and EXPLICIT_REMINDER_RE.search(lower):
        replacement = _explicit_reminder_plan(user_message, timezone=timezone, status_events=[]).proposals[0]
    elif proposal.type == "task.complete":
        replacement = _complete_task_plan(user_message, status_events=[]).proposals[0]

    if replacement is None:
        return proposal
    return replacement.model_copy(
        update={
            "summary": proposal.summary or replacement.summary,
            "confidence": max(proposal.confidence, replacement.confidence),
            "reason": proposal.reason or replacement.reason,
        }
    )


def interpret_proposal_follow_up(
    user_message: str,
    pending_proposals: list[dict[str, Any]],
    *,
    timezone: str,
) -> ProposalFollowUpPlan:
    """Interpret a message against existing pending proposals."""

    if not pending_proposals:
        return ProposalFollowUpPlan(kind="none")

    text = _norm(user_message)
    if APPROVE_RE.fullmatch(text):
        return ProposalFollowUpPlan(kind="approve", proposal_indexes=[len(pending_proposals) - 1])
    if REJECT_RE.fullmatch(text):
        return ProposalFollowUpPlan(kind="reject", proposal_indexes=[len(pending_proposals) - 1])
    if ASK_RE.search(text):
        return ProposalFollowUpPlan(kind="ask", proposal_indexes=[len(pending_proposals) - 1])
    if "only" in text and "first" in text:
        return ProposalFollowUpPlan(kind="approve", proposal_indexes=[0])
    if "only" in text and "second" in text and len(pending_proposals) >= 2:
        return ProposalFollowUpPlan(kind="approve", proposal_indexes=[1])
    if REVISE_RE.search(text):
        index = _ordinal_index(text)
        if index is None or index >= len(pending_proposals):
            index = len(pending_proposals) - 1
        if _resolve_natural_datetime(user_message, timezone=timezone) is not None or any(
            token in text for token in ["change", "make it", "instead", "only"]
        ):
            return ProposalFollowUpPlan(kind="revise", proposal_indexes=[index], revision_text=user_message.strip())
    return ProposalFollowUpPlan(kind="none")


def revise_proposal_draft(
    draft: dict[str, Any],
    *,
    revision_text: str,
    timezone: str,
) -> dict[str, Any]:
    """Return a revised draft payload without mutating the original dict."""

    revised = dict(draft)
    command = dict(revised.get("command") or {})
    payload = dict(command.get("payload") or {})
    when = _resolve_natural_datetime(revision_text, timezone=timezone)
    if when is not None:
        if revised.get("proposal_type") in {"reminder.create", "job.create_once", "job.create_recurring"}:
            schedule = dict(payload.get("schedule") or payload.get("schedule_json") or {})
            schedule["run_at"] = when.isoformat()
            schedule["source_text"] = revision_text.strip()
            payload["schedule"] = schedule
        else:
            payload["due_at"] = when.isoformat()
    if "only" not in _norm(revision_text) and revision_text.strip():
        revised["revision_note"] = revision_text.strip()
    if payload:
        command["payload"] = payload
        revised["command"] = command
    return revised


def natural_datetime_for_text(text: str, *, timezone: str) -> datetime | None:
    return _resolve_natural_datetime(text, timezone=timezone)


def _deterministic_plan(user_message: str, *, timezone: str) -> ConversationTurnPlan:
    text = " ".join(user_message.strip().split())
    lower = _norm(text)
    base_events = ["received_input", "understanding_request"]

    if not text:
        return ConversationTurnPlan(
            mode="clarify",
            assistant_reply="I got an empty message. What would you like me to do?",
            clarifying_question="What would you like me to do?",
            status_events=base_events,
        )
    if lower in {"hi", "hey", "hello", "yo", "salam", "thanks", "thank you"}:
        return ConversationTurnPlan(
            mode="answer_only",
            assistant_reply="Hey. I am here. Send me a question, task, reminder, or correction.",
            status_events=base_events,
        )
    if _is_advice_or_question(lower) and not _is_explicit_action(lower):
        return ConversationTurnPlan(mode="answer_only", assistant_reply=_advice_answer(text), status_events=base_events)
    if DESTRUCTIVE_RE.search(lower) or FILE_TERMINAL_RE.search(lower):
        return _formal_review_plan(
            proposal_type="terminal.run_proposal",
            summary=_title(text, "Risky request"),
            reason="File, terminal, provider, external, or destructive action requires formal review.",
            draft={"command": {"command_type": "none", "payload": {"request": text}}, "source_text": text},
            risk="destructive" if DESTRUCTIVE_RE.search(lower) else "high",
            status_events=base_events,
        )
    if MEMORY_RE.search(lower):
        return _formal_review_plan(
            proposal_type="memory_candidate.create",
            summary=_title(text, "Memory candidate"),
            reason="Memory and preference writes need confirmation and evidence review.",
            draft={
                "command": {
                    "command_type": "memory_fact.create",
                    "payload": {
                        "fact_kind": "preference" if "prefer" in lower else "note",
                        "domain": "planning",
                        "statement_md": text,
                        "confidence": 0.7,
                        "sensitivity": "normal",
                        "evidence_refs": [],
                    },
                },
                "source_text": text,
            },
            risk="sensitive",
            status_events=base_events,
        )
    if RECURRING_RE.search(lower) and ("remind me" in lower or "reminder" in lower):
        return _recurring_reminder_plan(text, timezone=timezone, status_events=base_events)
    if EXPLICIT_REMINDER_RE.search(lower):
        if RECURRING_RE.search(lower):
            return _recurring_reminder_plan(text, timezone=timezone, status_events=base_events)
        return _explicit_reminder_plan(text, timezone=timezone, status_events=base_events)
    if EXPLICIT_TASK_RE.search(lower):
        return _explicit_task_plan(text, timezone=timezone, status_events=base_events)
    if EXPLICIT_COMPLETE_RE.search(lower) and "done" in lower or lower.startswith("mark ") and "done" in lower:
        return _complete_task_plan(text, status_events=base_events)
    if IMPLICIT_ACTION_RE.search(lower):
        return _implicit_task_plan(text, timezone=timezone, status_events=base_events)

    return ConversationTurnPlan(
        mode="answer_only",
        assistant_reply="I heard you. I did not change anything.",
        status_events=base_events,
    )


def _explicit_task_plan(text: str, *, timezone: str, status_events: list[str]) -> ConversationTurnPlan:
    title = _clean_title(_after_task_prefix(text), fallback="New task")
    due_at = _resolve_natural_datetime(text, timezone=timezone)
    payload: dict[str, Any] = {
        "domain": "planning",
        "item_type": "task",
        "title": title,
        "description_md": text,
        "priority": "normal",
        "status": "open",
        "metadata": {"source": "conversation_action_loop"},
    }
    if due_at is not None:
        payload["due_at"] = due_at.isoformat()
    return ConversationTurnPlan(
        mode="execute_now",
        assistant_reply=f"Done - task created: {title}.",
        proposals=[
            ConversationActionProposal(
                type="task.create",
                summary=f"Create task: {title}",
                confidence=0.9,
                risk="low",
                requires_confirmation=False,
                formal_review_required=False,
                draft={
                    "explicit": True,
                    "proposal_type": "task.create",
                    "source_text": text,
                    "command": {"command_type": "life_item.create", "payload": payload},
                },
            )
        ],
        status_events=status_events,
    )


def _explicit_reminder_plan(text: str, *, timezone: str, status_events: list[str]) -> ConversationTurnPlan:
    remind_at = _resolve_natural_datetime(text, timezone=timezone)
    if remind_at is None:
        return ConversationTurnPlan(
            mode="clarify",
            assistant_reply="When should I remind you?",
            clarifying_question="When should I remind you?",
            status_events=status_events,
        )
    title = _clean_title(_after_to(text), fallback="Reminder")
    payload = _job_payload(
        name=f"Reminder: {title}",
        description=text,
        schedule_type="one_time",
        schedule={"run_at": remind_at.isoformat(), "source_text": text},
        command={"type": "notify", "text": title},
        timezone=timezone,
    )
    return ConversationTurnPlan(
        mode="execute_now",
        assistant_reply=f"Done - reminder created for {_friendly_when(remind_at)}.",
        proposals=[
            ConversationActionProposal(
                type="reminder.create",
                summary=f"Create reminder: {title}",
                confidence=0.9,
                risk="low",
                requires_confirmation=False,
                formal_review_required=False,
                draft={
                    "explicit": True,
                    "proposal_type": "reminder.create",
                    "source_text": text,
                    "command": {"command_type": "job.create", "payload": payload},
                },
            )
        ],
        status_events=status_events,
    )


def _recurring_reminder_plan(text: str, *, timezone: str, status_events: list[str]) -> ConversationTurnPlan:
    title = _clean_title(_after_to(text), fallback="Recurring reminder")
    payload = _job_payload(
        name=f"Recurring reminder: {title}",
        description=text,
        schedule_type="recurring",
        schedule={"source_text": text},
        command={"type": "notify", "text": title},
        timezone=timezone,
    )
    return _formal_review_plan(
        proposal_type="job.create_recurring",
        summary=f"Create recurring reminder: {title}",
        reason="Recurring jobs need review before activation.",
        draft={
            "explicit": True,
            "proposal_type": "job.create_recurring",
            "source_text": text,
            "command": {"command_type": "job.create", "payload": payload},
        },
        risk="medium",
        status_events=status_events,
    )


def _complete_task_plan(text: str, *, status_events: list[str]) -> ConversationTurnPlan:
    query = _completion_query(text)
    return ConversationTurnPlan(
        mode="execute_now",
        assistant_reply=f"Done - marked matching task complete: {query}.",
        proposals=[
            ConversationActionProposal(
                type="task.complete",
                summary=f"Mark task done: {query}",
                confidence=0.82,
                risk="low",
                requires_confirmation=False,
                formal_review_required=False,
                draft={
                    "explicit": True,
                    "proposal_type": "task.complete",
                    "source_text": text,
                    "lookup": {"title_contains": query},
                    "command": {"command_type": "life_item.update", "payload": {"updates": {"status": "done"}}},
                },
            )
        ],
        status_events=status_events,
    )


def _implicit_task_plan(text: str, *, timezone: str, status_events: list[str]) -> ConversationTurnPlan:
    title = _clean_title(_after_implicit_prefix(text), fallback="New task")
    due_at = _resolve_natural_datetime(text, timezone=timezone)
    payload: dict[str, Any] = {
        "domain": "planning",
        "item_type": "task",
        "title": title,
        "description_md": text,
        "priority": "normal",
        "status": "open",
        "metadata": {"source": "conversation_action_loop", "inferred": True},
    }
    if due_at is not None:
        payload["due_at"] = due_at.isoformat()
    return ConversationTurnPlan(
        mode="propose_inline",
        assistant_reply=f"I can create a task for this: {title}",
        proposals=[
            ConversationActionProposal(
                type="task.create",
                summary=f"Create task: {title}",
                confidence=0.76,
                risk="low",
                requires_confirmation=True,
                formal_review_required=False,
                draft={
                    "explicit": False,
                    "proposal_type": "task.create",
                    "source_text": text,
                    "command": {"command_type": "life_item.create", "payload": payload},
                },
                reason="Inferred useful action from natural language.",
            )
        ],
        status_events=status_events,
    )


def _formal_review_plan(
    *,
    proposal_type: ActionType,
    summary: str,
    reason: str,
    draft: dict[str, Any],
    risk: RiskLevel,
    status_events: list[str],
) -> ConversationTurnPlan:
    return ConversationTurnPlan(
        mode="formal_review",
        assistant_reply="This needs formal review before I act.",
        proposals=[
            ConversationActionProposal(
                type=proposal_type,
                summary=summary,
                confidence=0.78,
                risk=risk,
                requires_confirmation=True,
                formal_review_required=True,
                draft=draft,
                reason=reason,
            )
        ],
        status_events=[*status_events, "planned_action", "formal_review_created"],
    )


def _enforce_proposal_policy(item: ConversationActionProposal, *, user_message: str) -> ConversationActionProposal:
    update: dict[str, Any] = {}
    if item.type in {"job.create_recurring", "memory_candidate.create", "file.write_proposal", "terminal.run_proposal"}:
        update["requires_confirmation"] = True
        update["formal_review_required"] = True
    if item.type == "file.read" and "sensitive" in user_message:
        update["formal_review_required"] = True
    if item.risk in {"high", "sensitive", "destructive"}:
        update["requires_confirmation"] = True
        update["formal_review_required"] = True
    if item.type in {"task.create", "task.update", "task.complete", "reminder.create", "job.create_once"} and item.risk == "low":
        if item.draft.get("explicit"):
            update.setdefault("requires_confirmation", False)
            update.setdefault("formal_review_required", False)
    return item.model_copy(update=update) if update else item


def _job_payload(
    *,
    name: str,
    description: str,
    schedule_type: str,
    schedule: dict[str, Any],
    command: dict[str, Any],
    timezone: str,
) -> dict[str, Any]:
    return {
        "name": name,
        "description_md": description,
        "schedule_type": schedule_type,
        "schedule": schedule,
        "timezone": timezone,
        "target_agent_id": "daily-planner",
        "command": command,
        "approval_policy": "ask_for_mutations",
        "enabled": True,
    }


def _resolve_natural_datetime(text: str, *, timezone: str) -> datetime | None:
    tz = _zone(timezone)
    now = datetime.now(tz)
    lower = _norm(text)
    target_date = None
    if "tomorrow" in lower:
        target_date = (now + timedelta(days=1)).date()
    elif "today" in lower:
        target_date = now.date()
    else:
        for name, weekday in WEEKDAYS.items():
            if name in lower:
                days = (weekday - now.weekday()) % 7
                if days == 0:
                    days = 7
                target_date = (now + timedelta(days=days)).date()
                break
    if target_date is None:
        return None

    target_time = _time_from_text(lower) or time(9, 0)
    return datetime.combine(target_date, target_time, tzinfo=tz)


def _time_from_text(lower: str) -> time | None:
    match = re.search(r"\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b", lower)
    if match:
        hour = int(match.group(1))
        minute = int(match.group(2) or 0)
        suffix = match.group(3)
        if suffix == "pm" and hour < 12:
            hour += 12
        if suffix == "am" and hour == 12:
            hour = 0
        if 0 <= hour <= 23 and 0 <= minute <= 59:
            return time(hour, minute)
    if "morning" in lower:
        return time(9, 0)
    if "afternoon" in lower:
        return time(14, 0)
    if "evening" in lower:
        return time(18, 0)
    if "night" in lower:
        return time(20, 0)
    return None


def _zone(timezone: str) -> ZoneInfo:
    try:
        return ZoneInfo(timezone)
    except ZoneInfoNotFoundError:
        return ZoneInfo("UTC")


def _after_task_prefix(text: str) -> str:
    return re.sub(r"^(create|add|make)\s+(a\s+)?(task|todo)\s*(to|for)?\s*", "", text, flags=re.I).strip()


def _after_implicit_prefix(text: str) -> str:
    return re.sub(r"^.*?\b(i need to|need to|i should|should|have to|got to)\b\s*", "", text, flags=re.I).strip()


def _after_to(text: str) -> str:
    match = re.search(r"\bto\s+(.+)$", text, flags=re.I)
    if match:
        return match.group(1).strip()
    return re.sub(r"^(remind me|set (a )?reminder|create (a )?reminder)\s*", "", text, flags=re.I).strip()


def _completion_query(text: str) -> str:
    cleaned = re.sub(r"^(mark|complete|finish)\s*", "", text, flags=re.I)
    cleaned = re.sub(r"\b(the|a)?\s*task\b", "", cleaned, flags=re.I)
    cleaned = re.sub(r"\bdone\b", "", cleaned, flags=re.I)
    return _clean_title(cleaned, fallback="task")


def _clean_title(text: str, *, fallback: str) -> str:
    cleaned = re.sub(r"\b(today|tomorrow)\b", "", text, flags=re.I)
    cleaned = re.sub(r"\b(on\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b", "", cleaned, flags=re.I)
    cleaned = re.sub(r"\bat\s+\d{1,2}(:\d{2})?\s*(am|pm)?\b", "", cleaned, flags=re.I)
    cleaned = re.sub(r"\b(morning|afternoon|evening|night)\b", "", cleaned, flags=re.I)
    cleaned = " ".join(cleaned.split()).strip(" .")
    return _title(cleaned, fallback)


def _title(text: str, fallback: str) -> str:
    compact = " ".join(text.split())
    return compact[:120].rstrip(" .,") if compact else fallback


def _friendly_when(value: datetime) -> str:
    return value.strftime("%A at %-I:%M %p")


def _is_explicit_action(lower: str) -> bool:
    return bool(EXPLICIT_TASK_RE.search(lower) or EXPLICIT_REMINDER_RE.search(lower) or EXPLICIT_COMPLETE_RE.search(lower))


def _is_advice_or_question(lower: str) -> bool:
    return lower.endswith("?") or lower.startswith(QUESTION_STARTS)


def _advice_answer(text: str) -> str:
    lower = _norm(text)
    if "cheap" in lower and "protein" in lower and "dinner" in lower:
        return "Try eggs with lentils or tuna over rice with yogurt on the side. Cheap, high protein, and low effort."
    return "I can answer this without changing LifeOS state. No task, log, or memory was created."


def _ordinal_index(text: str) -> int | None:
    if "first" in text:
        return 0
    if "second" in text:
        return 1
    if "third" in text:
        return 2
    return None


def _norm(text: str) -> str:
    return " ".join(text.strip().lower().split())


def _dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        if item not in seen:
            out.append(item)
            seen.add(item)
    return out
