"""Agent handoff endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import Handoff
from lifeos_api.deps import db_session_dep
from lifeos_api.schemas.handoff import HandoffCreate
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.serialization import row_to_dict
from lifeos_api.services.status_events import create_status_event
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now

router = APIRouter()

HANDOFF_FIELDS = [
    "id",
    "parent_run_id",
    "from_agent_id",
    "to_agent_id",
    "reason",
    "task_md",
    "known_context",
    "context_refs",
    "constraints",
    "expected_output_schema",
    "result_json",
    "summary_md",
    "risk_level",
    "status",
    "visibility",
    "requires_user_visibility",
    "discord_summary_posted",
    "created_at",
    "updated_at",
    "completed_at",
]


@router.get("/handoffs")
async def list_handoffs(limit: int = 100, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    rows = (await session.scalars(select(Handoff).order_by(desc(Handoff.created_at)).limit(limit))).all()
    return {"items": [row_to_dict(row, HANDOFF_FIELDS) for row in rows], "count": len(rows)}


@router.post("/handoffs")
async def create_handoff(payload: HandoffCreate, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    now = utc_now()
    row = Handoff(
        id=new_id("hnd"),
        parent_run_id=payload.parent_run_id,
        from_agent_id=payload.from_agent_id,
        to_agent_id=payload.to_agent_id,
        reason=payload.reason,
        task_md=payload.task_md,
        known_context=payload.known_context,
        context_refs=payload.context_refs,
        constraints=payload.constraints,
        expected_output_schema=payload.expected_output_schema,
        result_json={},
        summary_md=None,
        risk_level=payload.risk_level,
        status="created",
        visibility=payload.visibility,
        requires_user_visibility=payload.requires_user_visibility,
        discord_summary_posted=False,
        created_at=now,
        updated_at=now,
        completed_at=None,
    )
    session.add(row)
    await create_status_event(
        session,
        run_id=payload.parent_run_id,
        event_type="agent.handoff_created",
        title=f"{payload.from_agent_id} -> {payload.to_agent_id}",
        visibility="discord_compact",
        detail_json={"handoff_id": row.id, "reason": payload.reason},
    )
    await create_audit_event(
        session,
        actor_type="agent",
        actor_id=payload.from_agent_id,
        event_type="agent.handoff_created",
        entity_type="handoff",
        entity_id=row.id,
        summary=payload.reason,
        after_json=row_to_dict(row, HANDOFF_FIELDS),
    )
    await session.commit()
    return row_to_dict(row, HANDOFF_FIELDS)


@router.post("/handoffs/{handoff_id}/status/{status}")
async def update_handoff_status(
    handoff_id: str,
    status: str,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    row = await session.get(Handoff, handoff_id)
    if row is None:
        return {"error": "not_found"}
    row.status = status
    row.updated_at = utc_now()
    if status in {"returned", "merged", "failed", "cancelled"}:
        row.completed_at = row.updated_at
    await create_audit_event(
        session,
        actor_type="system",
        actor_id="handoff-router",
        event_type="handoff.status_updated",
        entity_type="handoff",
        entity_id=row.id,
        summary=f"Handoff status updated to {status}",
    )
    await session.commit()
    return row_to_dict(row, HANDOFF_FIELDS)
