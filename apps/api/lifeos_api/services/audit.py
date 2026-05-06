"""Audit event helpers."""

from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import AuditEvent
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now


async def create_audit_event(
    session: AsyncSession,
    *,
    actor_type: str,
    actor_id: str,
    event_type: str,
    entity_type: str,
    entity_id: str,
    summary: str,
    before_json: dict[str, Any] | None = None,
    after_json: dict[str, Any] | None = None,
    metadata_json: dict[str, Any] | None = None,
    trace_id: str | None = None,
) -> AuditEvent:
    event = AuditEvent(
        id=new_id("audit"),
        actor_type=actor_type,
        actor_id=actor_id,
        event_type=event_type,
        entity_type=entity_type,
        entity_id=entity_id,
        summary=summary,
        before_json=before_json,
        after_json=after_json,
        metadata_json=metadata_json or {},
        trace_id=trace_id,
        created_at=utc_now(),
    )
    session.add(event)
    return event
