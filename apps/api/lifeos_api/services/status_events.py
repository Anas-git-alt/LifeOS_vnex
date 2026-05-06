"""Persistent status event helpers."""

from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import StatusEventRow
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now


async def create_status_event(
    session: AsyncSession,
    *,
    event_type: str,
    title: str,
    run_id: str | None = None,
    visibility: str = "web_only",
    detail_json: dict[str, Any] | None = None,
) -> StatusEventRow:
    event = StatusEventRow(
        id=new_id("evt"),
        run_id=run_id,
        event_type=event_type,
        visibility=visibility,
        title=title,
        detail_json=detail_json or {},
        created_at=utc_now(),
    )
    session.add(event)
    return event
