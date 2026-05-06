"""Audit log endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import AuditEvent
from lifeos_api.deps import db_session_dep
from lifeos_api.services.serialization import row_to_dict

router = APIRouter()


@router.get("/audit")
async def list_audit(
    entity_type: str | None = None,
    limit: int = 100,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    stmt = select(AuditEvent).order_by(desc(AuditEvent.created_at)).limit(limit)
    if entity_type:
        stmt = stmt.where(AuditEvent.entity_type == entity_type)
    rows = (await session.scalars(stmt)).all()
    fields = [
        "id",
        "actor_type",
        "actor_id",
        "event_type",
        "entity_type",
        "entity_id",
        "summary",
        "before_json",
        "after_json",
        "metadata_json",
        "trace_id",
        "created_at",
    ]
    return {"items": [row_to_dict(row, fields) for row in rows], "count": len(rows)}
