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
from lifeos_api.services.orchestrator import draft_from_capture
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

    draft = draft_from_capture(
        capture_id=capture_id,
        raw_text=payload.raw_text,
        platform=payload.source_platform,
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
        status="routed",
        sensitivity=draft.sensitivity,
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
        active_agent_id=draft.agent_id,
        status="waiting_approval",
        status_summary=f"Routed to {draft.agent_id}",
        provider_used="deterministic",
        model_used="capture-router-v1",
        cost_usd=0,
        token_usage_json={"input_tokens": 0, "output_tokens": 0},
        trace_id=new_id("trace"),
        created_at=now,
        updated_at=now,
        finished_at=None,
    )
    session.add(run)
    await session.flush()

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
        status="promoted_to_review",
        created_at=now,
    )
    session.add(interpretation)

    handoff = Handoff(
        id=new_id("hnd"),
        parent_run_id=run.id,
        from_agent_id="capture-router",
        to_agent_id=draft.agent_id,
        reason=f"Capture classified as {draft.domain}",
        task_md=f"Draft review-gated action for capture {capture.id}.",
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
        validation_json={"missing_context": draft.missing_context or []},
        status="pending",
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

    await create_status_event(
        session,
        run_id=run.id,
        event_type="capture.received",
        title="Received capture",
        visibility="discord_compact",
        detail_json={"capture_id": capture.id},
    )
    await create_status_event(
        session,
        run_id=run.id,
        event_type="agent.handoff_created",
        title=f"Capture Router -> {draft.agent_id}",
        visibility="discord_compact",
        detail_json={"handoff_id": handoff.id},
    )
    await create_status_event(
        session,
        run_id=run.id,
        event_type="review.created",
        title=f"Review created: {draft.title}",
        visibility="discord_compact",
        detail_json={"review_item_id": review.id},
    )
    await create_audit_event(
        session,
        actor_type="system",
        actor_id="capture-router",
        event_type="capture.routed",
        entity_type="raw_capture",
        entity_id=capture.id,
        summary=f"Capture routed to {draft.agent_id} and promoted to review.",
        after_json={"review_item_id": review.id, "run_id": run.id},
        trace_id=run.trace_id,
    )
    await session.commit()

    return {
        "capture": row_to_dict(capture, CAPTURE_FIELDS),
        "run_id": run.id,
        "handoff_id": handoff.id,
        "review_item_id": review.id,
        "notification_id": notification.id,
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
