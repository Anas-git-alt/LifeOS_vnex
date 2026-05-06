"""Capture ingestion and routing endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.config import Settings
from lifeos_api.db.models import (
    AgentRun,
    CaptureInterpretation,
    Handoff,
    Notification,
    RawCapture,
    ReviewItem,
)
from lifeos_api.deps import db_session_dep, settings_dep
from lifeos_api.schemas.capture import CaptureCreate
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.agentic_router import route_capture_agentically
from lifeos_api.services.command_bus import CommandBus, CommandRequest
from lifeos_api.services.orchestrator import draft_from_capture
from lifeos_api.services.policy_engine import decide_capture_action
from lifeos_api.services.runtime_config import get_agent_autonomy, get_router_mode
from lifeos_api.services.serialization import row_to_dict
from lifeos_api.services.status_events import create_status_event
from lifeos_api.services.vault import VaultWriter
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now

router = APIRouter()


CAPTURE_FIELDS = [
    "id",
    "source_platform",
    "source_external_message_id",
    "capture_kind",
    "raw_text",
    "raw_uri",
    "content_hash",
    "status",
    "sensitivity",
    "received_at",
    "created_at",
    "updated_at",
]


@router.post("/captures")
async def create_capture(
    payload: CaptureCreate,
    session: AsyncSession = Depends(db_session_dep),
    settings: Settings = Depends(settings_dep),
) -> dict[str, object]:
    now = utc_now()
    capture_id = new_id("cap")
    vault = VaultWriter(settings)
    metadata = dict(payload.metadata)
    metadata["sensitivity"] = payload.sensitivity
    raw_uri, digest = vault.write_raw_capture(
        capture_id=capture_id,
        platform=payload.source_platform,
        kind=payload.capture_kind.value,
        text=payload.raw_text,
        metadata=metadata,
    )

    capture = RawCapture(
        id=capture_id,
        source_platform=payload.source_platform,
        source_channel_id=payload.source_channel_id,
        source_external_message_id=payload.external_message_id,
        source_thread_id=payload.external_thread_id,
        source_user_id=None,
        capture_kind=payload.capture_kind.value,
        raw_text=payload.raw_text,
        raw_uri=raw_uri,
        content_hash=digest,
        status="received",
        sensitivity=payload.sensitivity,
        received_at=payload.received_at,
        created_at=now,
        updated_at=now,
    )
    session.add(capture)
    await session.flush()

    run = AgentRun(
        id=new_id("run"),
        session_id=None,
        root_capture_id=capture.id,
        initiating_user_id=None,
        orchestrator_agent_id="orchestrator",
        active_agent_id="capture-router",
        status="routing",
        status_summary="Routing capture",
        provider_used=None,
        model_used=None,
        cost_usd=0,
        token_usage_json={"input_tokens": 0, "output_tokens": 0},
        trace_id=new_id("trace"),
        created_at=now,
        updated_at=now,
        finished_at=None,
    )
    session.add(run)
    await session.flush()

    await create_status_event(
        session,
        run_id=run.id,
        event_type="capture.received",
        title="Received capture",
        visibility="discord_compact",
        detail_json={"capture_id": capture.id, "source_platform": payload.source_platform},
    )
    await create_status_event(
        session,
        run_id=run.id,
        event_type="capture.routing",
        title="Routing/classifying capture",
        visibility="discord_compact",
        detail_json={"capture_id": capture.id},
    )

    router_mode = await get_router_mode(session, settings.router_mode)
    try:
        draft, provider_meta = await route_capture_agentically(
            session=session,
            settings=settings,
            capture_id=capture_id,
            raw_text=payload.raw_text,
            platform=payload.source_platform,
            run_id=run.id,
            router_mode=router_mode,
        )
    except Exception as exc:  # noqa: BLE001 - ingestion must never lose raw evidence
        draft = draft_from_capture(
            capture_id=capture_id,
            raw_text=payload.raw_text,
            platform=payload.source_platform,
        )
        provider_meta = {
            "provider": "deterministic",
            "model": "capture-router-v1",
            "fallback_used": True,
            "fallback_reason": str(exc)[:500],
        }

    capture.sensitivity = draft.sensitivity
    run.active_agent_id = draft.agent_id
    run.provider_used = str(provider_meta.get("provider"))
    run.model_used = str(provider_meta.get("model"))

    interpretation = CaptureInterpretation(
        id=new_id("interp"),
        capture_id=capture.id,
        agent_id=draft.agent_id,
        intent_labels=draft.intent_labels,
        draft_json={
            "domain": draft.domain,
            "title": draft.title,
            "proposed_action": draft.proposed_action,
        },
        confidence=draft.confidence,
        missing_context=draft.missing_context or [],
        risk_level=draft.risk_level,
        status="drafted",
        created_at=now,
    )
    session.add(interpretation)

    autonomy_mode = await get_agent_autonomy(session, draft.agent_id)
    owner_authenticated = bool(payload.metadata.get("owner_authenticated", True))
    policy = decide_capture_action(
        action=draft.proposed_action,
        confidence=draft.confidence,
        sensitivity=draft.sensitivity,
        autonomy_mode=autonomy_mode,
        owner_authenticated=owner_authenticated,
        missing_context=draft.missing_context or [],
        intent_labels=draft.intent_labels,
    )
    await create_status_event(
        session,
        run_id=run.id,
        event_type="policy.decision",
        title=f"Policy: {policy.decision}",
        visibility="discord_compact",
        detail_json=policy.as_dict(),
    )

    handoff = Handoff(
        id=new_id("hnd"),
        parent_run_id=run.id,
        from_agent_id="capture-router",
        to_agent_id=draft.agent_id,
        reason=f"Capture classified as {draft.domain}",
        task_md=f"Classify capture {capture.id} and apply policy.",
        context_refs=[{"kind": "raw_capture", "id": capture.id, "uri": raw_uri}],
        expected_output_schema={"type": "review_item"},
        status="returned",
        visibility="web",
        discord_summary_posted=False,
        created_at=now,
        updated_at=now,
        completed_at=now,
    )
    session.add(handoff)

    await create_status_event(
        session,
        run_id=run.id,
        event_type="agent.handoff_created",
        title=f"Capture Router -> {draft.agent_id}",
        visibility="discord_compact",
        detail_json={"handoff_id": handoff.id},
    )

    review: ReviewItem | None = None
    notification: Notification | None = None
    state_change_id: str | None = None
    route_decision = policy.decision
    message = ""

    if policy.decision == "raw_only":
        capture.status = "raw_only"
        interpretation.status = "archived_raw_only"
        run.status = "completed"
        run.status_summary = "Captured as raw context; no approval needed."
        run.finished_at = now
        message = "Captured as raw context. No approval needed."
    elif policy.decision == "auto_apply":
        command_result = await CommandBus(session, settings).apply(
            CommandRequest(
                command_type=str(draft.proposed_action["command_type"]),
                payload=dict(draft.proposed_action.get("payload", {})),
                source_review_item_id=None,
                actor_type="system",
                actor_id="policy-engine",
            )
        )
        state_change_id = command_result.state_change_id
        capture.status = "auto_applied" if command_result.status == "applied" else "failed"
        interpretation.status = "auto_applied"
        run.status = "completed" if command_result.status == "applied" else "failed"
        run.status_summary = f"Auto-applied {draft.proposed_action['command_type']}"
        run.finished_at = now
        message = f"Done: {run.status_summary}."
    elif policy.decision in {"review_required", "ask_clarification"}:
        review = ReviewItem(
            id=new_id("rev"),
            kind=draft.domain,
            title=draft.title,
            body_md=draft.body_md,
            source_capture_id=capture.id,
            source_uri=raw_uri,
            proposed_by_agent_id=draft.agent_id,
            assigned_agent_id="approval-manager",
            priority="normal",
            confidence=draft.confidence,
            risk_level=draft.risk_level,
            sensitivity=draft.sensitivity,
            proposed_action_json=draft.proposed_action,
            validation_json={"missing_context": draft.missing_context or [], "policy": policy.as_dict()},
            status="pending" if policy.decision == "review_required" else "needs_clarification",
            expires_at=None,
            snoozed_until=None,
            created_at=now,
            updated_at=now,
        )
        session.add(review)
        await session.flush()

        notification = Notification(
            id=new_id("notif"),
            target_platform="discord",
            target_channel_id=None,
            notification_type="review.created",
            title=draft.title,
            body_md=draft.body_md,
            status="queued",
            related_run_id=run.id,
            related_review_item_id=review.id,
            external_message_id=None,
            error_json=None,
            created_at=now,
            sent_at=None,
        )
        session.add(notification)

        capture.status = "waiting_approval" if policy.decision == "review_required" else "needs_clarification"
        interpretation.status = "promoted_to_review"
        run.status = "waiting_approval" if policy.decision == "review_required" else "needs_clarification"
        run.status_summary = (
            f"Waiting for approval: {draft.title}"
            if policy.decision == "review_required"
            else f"Needs clarification: {draft.title}"
        )
        message = (
            f"Captured. Review needed: {draft.title}"
            if policy.decision == "review_required"
            else f"Captured. Clarification needed: {draft.title}"
        )
        await create_status_event(
            session,
            run_id=run.id,
            event_type="review.created",
            title=f"Review created: {draft.title}",
            visibility="discord_compact",
            detail_json={"review_item_id": review.id},
        )
    else:
        capture.status = "rejected"
        interpretation.status = "rejected_by_policy"
        run.status = "rejected"
        run.status_summary = policy.reason
        run.finished_at = now
        route_decision = "reject"
        message = f"Capture rejected by policy: {policy.reason}"

    run.updated_at = now
    capture.updated_at = now

    await create_audit_event(
        session,
        actor_type="agent",
        actor_id=draft.agent_id,
        event_type="capture.policy_routed",
        entity_type="raw_capture",
        entity_id=capture.id,
        summary=f"Capture routed to {draft.agent_id}; policy={policy.decision}.",
        after_json={
            "review_item_id": review.id if review else None,
            "run_id": run.id,
            "state_change_id": state_change_id,
            "policy": policy.as_dict(),
            "provider": provider_meta,
        },
        trace_id=run.trace_id,
    )
    await session.commit()

    return {
        "capture": row_to_dict(capture, CAPTURE_FIELDS),
        "run_id": run.id,
        "handoff_id": handoff.id,
        "route": {
            "agent_id": draft.agent_id,
            "domain": draft.domain,
            "decision": route_decision,
            "reason": policy.reason,
            "confidence": draft.confidence,
            "provider": provider_meta.get("provider"),
            "model": provider_meta.get("model"),
            "fallback_used": provider_meta.get("fallback_used", False),
        },
        "review_item_id": review.id if review else None,
        "state_change_id": state_change_id,
        "notification_id": notification.id if notification else None,
        "message": message,
    }


@router.get("/captures")
async def list_captures(
    status: str | None = None,
    limit: int = 50,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    stmt = select(RawCapture).order_by(desc(RawCapture.created_at)).limit(limit)
    if status:
        stmt = select(RawCapture).where(RawCapture.status == status).order_by(desc(RawCapture.created_at)).limit(limit)
    rows = (await session.scalars(stmt)).all()
    return {"items": [row_to_dict(row, CAPTURE_FIELDS) for row in rows], "count": len(rows)}


@router.get("/captures/{capture_id}")
async def get_capture(capture_id: str, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    capture = await session.get(RawCapture, capture_id)
    if capture is None:
        return {"error": "not_found"}
    reviews = (
        await session.scalars(select(ReviewItem).where(ReviewItem.source_capture_id == capture_id))
    ).all()
    return {
        "capture": row_to_dict(capture, CAPTURE_FIELDS),
        "review_items": [
            row_to_dict(
                review,
                [
                    "id",
                    "kind",
                    "title",
                    "status",
                    "risk_level",
                    "sensitivity",
                    "created_at",
                ],
            )
            for review in reviews
        ],
    }
