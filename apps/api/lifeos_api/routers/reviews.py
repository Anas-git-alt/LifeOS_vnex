"""Review queue and decision endpoints."""

from datetime import timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.config import Settings
from lifeos_api.db.models import ReviewDecision, ReviewItem
from lifeos_api.deps import db_session_dep, settings_dep
from lifeos_api.schemas.review import ReviewDecisionCreate
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.command_bus import CommandBus, CommandRequest
from lifeos_api.services.serialization import row_to_dict
from lifeos_api.services.status_events import create_status_event
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now

router = APIRouter()


REVIEW_FIELDS = [
    "id",
    "kind",
    "title",
    "body_md",
    "source_capture_id",
    "source_uri",
    "proposed_by_agent_id",
    "assigned_agent_id",
    "priority",
    "confidence",
    "risk_level",
    "sensitivity",
    "proposed_action_json",
    "validation_json",
    "status",
    "expires_at",
    "snoozed_until",
    "created_at",
    "updated_at",
]


@router.get("/reviews")
async def list_reviews(
    status: str | None = None,
    domain: str | None = None,
    limit: int = 100,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    stmt = select(ReviewItem).order_by(desc(ReviewItem.created_at)).limit(limit)
    if status:
        stmt = stmt.where(ReviewItem.status == status)
    if domain:
        stmt = stmt.where(ReviewItem.kind == domain)
    rows = (await session.scalars(stmt)).all()
    return {"items": [row_to_dict(row, REVIEW_FIELDS) for row in rows], "count": len(rows)}


@router.get("/reviews/{review_id}")
async def get_review(review_id: str, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    review = await session.get(ReviewItem, review_id)
    if review is None:
        return {"error": "not_found"}
    decisions = (
        await session.scalars(
            select(ReviewDecision)
            .where(ReviewDecision.review_item_id == review_id)
            .order_by(desc(ReviewDecision.created_at))
        )
    ).all()
    return {
        "review": row_to_dict(review, REVIEW_FIELDS),
        "decisions": [
            row_to_dict(
                decision,
                [
                    "id",
                    "review_item_id",
                    "decision",
                    "decision_text",
                    "decision_payload",
                    "source_platform",
                    "created_at",
                ],
            )
            for decision in decisions
        ],
    }


@router.post("/reviews/{review_id}/decision")
async def decide_review(
    review_id: str,
    payload: ReviewDecisionCreate,
    session: AsyncSession = Depends(db_session_dep),
    settings: Settings = Depends(settings_dep),
) -> dict[str, object]:
    review = await session.get(ReviewItem, review_id)
    if review is None:
        return {"ok": False, "status": "not_found", "result": {}}

    now = utc_now()
    decision = ReviewDecision(
        id=new_id("dec"),
        review_item_id=review.id,
        user_id=None,
        decision=payload.decision.value,
        decision_text=payload.decision_text,
        decision_payload=payload.decision_payload,
        source_platform=payload.source_platform,
        source_external_message_id=payload.source_external_message_id,
        created_at=now,
    )
    session.add(decision)

    result: dict[str, object] = {"decision_id": decision.id}
    before = row_to_dict(review, REVIEW_FIELDS)

    if payload.decision.value == "approve":
        action = review.proposed_action_json
        command = CommandRequest(
            command_type=str(action["command_type"]),
            payload=dict(action.get("payload", {})),
            source_review_item_id=review.id,
            actor_type="user",
            actor_id="owner",
        )
        command_result = await CommandBus(session, settings).apply(command)
        review.status = "applied" if command_result.status == "applied" else "failed"
        review.updated_at = now
        result.update(command_result.model_dump(mode="json"))
    elif payload.decision.value == "reject":
        review.status = "rejected"
        review.updated_at = now
    elif payload.decision.value == "correct":
        if "proposed_action_json" in payload.decision_payload:
            review.proposed_action_json = dict(payload.decision_payload["proposed_action_json"])
        if "body_md" in payload.decision_payload:
            review.body_md = str(payload.decision_payload["body_md"])
        elif payload.decision_text:
            review.body_md = f"{review.body_md}\n\nCorrection note:\n{payload.decision_text}"
        review.status = "pending"
        review.updated_at = now
    elif payload.decision.value == "clarify":
        review.status = "needs_clarification"
        review.updated_at = now
    elif payload.decision.value == "snooze":
        hours = int(payload.decision_payload.get("hours", 8))
        review.status = "snoozed"
        review.snoozed_until = now + timedelta(hours=hours)
        review.updated_at = now
    elif payload.decision.value == "done":
        review.status = "applied"
        review.updated_at = now

    await create_audit_event(
        session,
        actor_type="user",
        actor_id="owner",
        event_type="review.decision_received",
        entity_type="review_item",
        entity_id=review.id,
        summary=f"Review decision: {payload.decision.value}",
        before_json=before,
        after_json=row_to_dict(review, REVIEW_FIELDS),
        metadata_json={"decision_id": decision.id},
    )
    await create_status_event(
        session,
        event_type="review.decision_received",
        title=f"Review {payload.decision.value}: {review.title}",
        visibility="discord_compact",
        detail_json={"review_item_id": review.id, "decision_id": decision.id},
    )
    await session.commit()
    return {"ok": True, "status": review.status, "result": result}
