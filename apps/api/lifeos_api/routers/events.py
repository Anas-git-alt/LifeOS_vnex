"""Status event endpoints, including a simple SSE stream."""

import asyncio
import json

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import StatusEventRow
from lifeos_api.deps import db_session_dep
from lifeos_api.services.serialization import row_to_dict

router = APIRouter()


EVENT_FIELDS = ["id", "run_id", "event_type", "visibility", "title", "detail_json", "created_at"]


@router.get("/events")
async def list_events(limit: int = 100, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    rows = (
        await session.scalars(select(StatusEventRow).order_by(desc(StatusEventRow.created_at)).limit(limit))
    ).all()
    return {"items": [row_to_dict(row, EVENT_FIELDS) for row in rows], "count": len(rows)}


@router.get("/events/stream")
async def stream_events() -> StreamingResponse:
    async def generator():
        while True:
            payload = json.dumps({"type": "heartbeat"})
            yield f"event: heartbeat\ndata: {payload}\n\n"
            await asyncio.sleep(15)

    return StreamingResponse(generator(), media_type="text/event-stream")
