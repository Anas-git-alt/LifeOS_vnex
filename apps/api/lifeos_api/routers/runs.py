"""Agent run trace endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import AgentRun, Handoff, StatusEventRow, ToolCall
from lifeos_api.deps import db_session_dep
from lifeos_api.services.serialization import row_to_dict

router = APIRouter()

RUN_FIELDS = [
    "id",
    "session_id",
    "root_capture_id",
    "orchestrator_agent_id",
    "active_agent_id",
    "status",
    "status_summary",
    "provider_used",
    "model_used",
    "cost_usd",
    "token_usage_json",
    "trace_id",
    "created_at",
    "updated_at",
    "finished_at",
]


@router.get("/runs")
async def list_runs(limit: int = 100, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    rows = (
        await session.scalars(select(AgentRun).order_by(desc(AgentRun.created_at)).limit(limit))
    ).all()
    return {"items": [row_to_dict(row, RUN_FIELDS) for row in rows], "count": len(rows)}


@router.get("/runs/{run_id}")
async def get_run(run_id: str, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    run = await session.get(AgentRun, run_id)
    if run is None:
        return {"error": "not_found"}
    events = (
        await session.scalars(
            select(StatusEventRow)
            .where(StatusEventRow.run_id == run_id)
            .order_by(StatusEventRow.created_at)
        )
    ).all()
    handoffs = (
        await session.scalars(select(Handoff).where(Handoff.parent_run_id == run_id).order_by(Handoff.created_at))
    ).all()
    tools = (
        await session.scalars(select(ToolCall).where(ToolCall.run_id == run_id).order_by(ToolCall.created_at))
    ).all()
    return {
        "run": row_to_dict(run, RUN_FIELDS),
        "events": [
            row_to_dict(event, ["id", "run_id", "event_type", "visibility", "title", "detail_json", "created_at"])
            for event in events
        ],
        "handoffs": [
            row_to_dict(
                handoff,
                [
                    "id",
                    "parent_run_id",
                    "from_agent_id",
                    "to_agent_id",
                    "reason",
                    "task_md",
                    "status",
                    "visibility",
                    "created_at",
                    "completed_at",
                ],
            )
            for handoff in handoffs
        ],
        "tool_calls": [
            row_to_dict(
                tool,
                ["id", "run_id", "agent_id", "tool_id", "status", "input_json", "output_json", "created_at"],
            )
            for tool in tools
        ],
    }


@router.get("/runs/{run_id}/events")
async def get_run_events(run_id: str, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    events = (
        await session.scalars(
            select(StatusEventRow)
            .where(StatusEventRow.run_id == run_id)
            .order_by(StatusEventRow.created_at)
        )
    ).all()
    return {
        "items": [
            row_to_dict(event, ["id", "run_id", "event_type", "visibility", "title", "detail_json", "created_at"])
            for event in events
        ],
        "count": len(events),
    }
