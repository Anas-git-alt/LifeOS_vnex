"""Agent session chat endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.config import Settings
from lifeos_api.db.models import AgentRun, AgentSession, Message, SystemSetting, User
from lifeos_api.deps import db_session_dep, settings_dep
from lifeos_api.schemas.session import (
    ChatCreate,
    SessionAgentPatch,
    SessionCreate,
    SessionIterationPatch,
    SessionMessageCreate,
    SessionResolve,
)
from lifeos_api.services.agent_runtime import AGENTS, run_agent_message
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.serialization import row_to_dict
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now

router = APIRouter()

SESSION_FIELDS = [
    "id",
    "agent_id",
    "user_id",
    "channel_id",
    "title",
    "status",
    "memory_scope",
    "iteration_cap",
    "visibility",
    "source_platform",
    "external_channel_id",
    "external_thread_id",
    "external_message_id",
    "last_run_id",
    "last_user_correction_id",
    "paused_run_id",
    "metadata_json",
    "created_at",
    "updated_at",
]

MESSAGE_FIELDS = [
    "id",
    "session_id",
    "run_id",
    "role",
    "content_md",
    "content_json",
    "source_platform",
    "source_external_channel_id",
    "source_external_thread_id",
    "source_external_message_id",
    "metadata_json",
    "created_at",
]


@router.get("/sessions")
async def list_sessions(limit: int = 100, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    rows = (await session.scalars(select(AgentSession).order_by(desc(AgentSession.updated_at)).limit(limit))).all()
    return {"items": [row_to_dict(row, SESSION_FIELDS) for row in rows], "count": len(rows)}


@router.post("/sessions")
async def create_session(
    payload: SessionCreate,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    row = await _create_session_row(session, payload)
    await create_audit_event(
        session,
        actor_type="user",
        actor_id=payload.user_id or "owner",
        event_type="agent_session.created",
        entity_type="agent_session",
        entity_id=row.id,
        summary=f"Created session for {row.agent_id}",
        after_json=row_to_dict(row, SESSION_FIELDS),
    )
    await session.commit()
    return {"ok": True, "session": row_to_dict(row, SESSION_FIELDS)}


@router.post("/sessions/resolve")
async def resolve_session(
    payload: SessionResolve,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    row = await _resolve_session(session, payload)
    if row is None:
        return {"ok": False, "status": "not_found"}
    await session.commit()
    return {"ok": True, "session": row_to_dict(row, SESSION_FIELDS)}


@router.get("/sessions/{session_id}")
async def get_session(session_id: str, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    row = await session.get(AgentSession, session_id)
    if row is None:
        return {"error": "not_found"}
    messages = (
        await session.scalars(
            select(Message).where(Message.session_id == session_id).order_by(Message.created_at).limit(100)
        )
    ).all()
    runs = (
        await session.scalars(
            select(AgentRun).where(AgentRun.session_id == session_id).order_by(desc(AgentRun.created_at)).limit(20)
        )
    ).all()
    return {
        "session": row_to_dict(row, SESSION_FIELDS),
        "messages": [row_to_dict(message, MESSAGE_FIELDS) for message in messages],
        "runs": [
            row_to_dict(
                run,
                [
                    "id",
                    "active_agent_id",
                    "status",
                    "status_summary",
                    "iteration_cap",
                    "current_iteration",
                    "result_json",
                    "created_at",
                    "updated_at",
                    "finished_at",
                ],
            )
            for run in runs
        ],
    }


@router.get("/sessions/{session_id}/messages")
async def get_messages(session_id: str, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    rows = (
        await session.scalars(
            select(Message).where(Message.session_id == session_id).order_by(Message.created_at).limit(200)
        )
    ).all()
    return {"items": [row_to_dict(row, MESSAGE_FIELDS) for row in rows], "count": len(rows)}


@router.post("/sessions/{session_id}/messages")
async def post_message(
    session_id: str,
    payload: SessionMessageCreate,
    db: AsyncSession = Depends(db_session_dep),
    settings: Settings = Depends(settings_dep),
) -> dict[str, object]:
    row = await db.get(AgentSession, session_id)
    if row is None:
        return {"ok": False, "status": "not_found"}
    return await run_agent_message(
        session=db,
        settings=settings,
        agent_session=row,
        message_md=payload.message,
        source_platform=payload.source_platform,
        external_channel_id=payload.external_channel_id,
        external_thread_id=payload.external_thread_id,
        external_message_id=payload.external_message_id,
        user_id=payload.user_id,
        metadata=payload.metadata,
    )


@router.post("/chat")
async def chat(
    payload: ChatCreate,
    db: AsyncSession = Depends(db_session_dep),
    settings: Settings = Depends(settings_dep),
) -> dict[str, object]:
    resolve = SessionResolve(
        source_platform=payload.source_platform,
        external_channel_id=payload.external_channel_id,
        external_thread_id=payload.external_thread_id,
        create_if_missing=True,
        agent_id=payload.agent_id or "orchestrator",
        title=payload.title,
        iteration_cap=payload.iteration_cap,
        visibility=payload.visibility,
        user_id=payload.user_id,
        metadata=payload.metadata,
    )
    row = await _resolve_session(db, resolve)
    if row is None:
        return {"ok": False, "status": "not_found"}
    return await run_agent_message(
        session=db,
        settings=settings,
        agent_session=row,
        message_md=payload.message,
        source_platform=payload.source_platform,
        external_channel_id=payload.external_channel_id,
        external_thread_id=payload.external_thread_id,
        external_message_id=payload.external_message_id,
        user_id=payload.user_id,
        metadata=payload.metadata,
    )


@router.patch("/sessions/{session_id}/agent")
async def set_session_agent(
    session_id: str,
    payload: SessionAgentPatch,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    row = await session.get(AgentSession, session_id)
    if row is None:
        return {"ok": False, "status": "not_found"}
    if payload.agent_id not in AGENTS:
        return {"ok": False, "status": "unknown_agent"}
    before = row.agent_id
    row.agent_id = payload.agent_id
    row.updated_at = utc_now()
    await create_audit_event(
        session,
        actor_type="user",
        actor_id="owner",
        event_type="agent_session.agent_changed",
        entity_type="agent_session",
        entity_id=row.id,
        summary=f"Session agent {before} -> {row.agent_id}",
        before_json={"agent_id": before},
        after_json={"agent_id": row.agent_id},
    )
    await session.commit()
    return {"ok": True, "session": row_to_dict(row, SESSION_FIELDS)}


@router.patch("/sessions/{session_id}/iterations")
async def set_session_iterations(
    session_id: str,
    payload: SessionIterationPatch,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    row = await session.get(AgentSession, session_id)
    if row is None:
        return {"ok": False, "status": "not_found"}
    before = row.iteration_cap
    row.iteration_cap = payload.iteration_cap
    row.updated_at = utc_now()
    await create_audit_event(
        session,
        actor_type="user",
        actor_id="owner",
        event_type="agent_session.iteration_cap_changed",
        entity_type="agent_session",
        entity_id=row.id,
        summary=f"Iteration cap {before} -> {row.iteration_cap}",
        before_json={"iteration_cap": before},
        after_json={"iteration_cap": row.iteration_cap},
    )
    await session.commit()
    return {"ok": True, "session": row_to_dict(row, SESSION_FIELDS)}


@router.post("/sessions/{session_id}/cancel")
async def cancel_session_run(session_id: str, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    row = await session.get(AgentSession, session_id)
    if row is None:
        return {"ok": False, "status": "not_found"}
    if not row.last_run_id:
        return {"ok": True, "status": "no_active_run"}
    run = await session.get(AgentRun, row.last_run_id)
    if run is None:
        return {"ok": True, "status": "no_active_run"}
    now = utc_now()
    run.cancel_requested = True
    run.cancelled_at = now
    run.status = "cancelled"
    run.status_summary = "Cancelled by owner"
    run.finished_at = now
    run.updated_at = now
    row.paused_run_id = None
    row.updated_at = now
    await create_audit_event(
        session,
        actor_type="user",
        actor_id="owner",
        event_type="agent_run.cancelled",
        entity_type="agent_run",
        entity_id=run.id,
        summary="Run cancelled by owner.",
    )
    await session.commit()
    return {"ok": True, "status": "cancelled", "run_id": run.id}


async def _resolve_session(session: AsyncSession, payload: SessionResolve) -> AgentSession | None:
    row = await _find_bound_session(
        session,
        source_platform=payload.source_platform,
        external_channel_id=payload.external_channel_id,
        external_thread_id=payload.external_thread_id,
    )
    if row is not None:
        if payload.iteration_cap:
            row.iteration_cap = payload.iteration_cap
        if payload.agent_id and row.agent_id == "orchestrator" and payload.agent_id != "orchestrator":
            row.agent_id = payload.agent_id
        row.updated_at = utc_now()
        return row
    if not payload.create_if_missing:
        return None
    return await _create_session_row(
        session,
        SessionCreate(
            agent_id=payload.agent_id,
            title=payload.title,
            iteration_cap=payload.iteration_cap,
            visibility=payload.visibility,
            source_platform=payload.source_platform,
            external_channel_id=payload.external_channel_id,
            external_thread_id=payload.external_thread_id,
            user_id=payload.user_id,
            memory_scope={},
            metadata=payload.metadata,
        ),
    )


async def _find_bound_session(
    session: AsyncSession,
    *,
    source_platform: str,
    external_channel_id: str | None,
    external_thread_id: str | None,
) -> AgentSession | None:
    if external_thread_id:
        row = (
            await session.scalars(
                select(AgentSession)
                .where(AgentSession.source_platform == source_platform)
                .where(AgentSession.external_thread_id == external_thread_id)
                .where(AgentSession.status == "active")
                .order_by(desc(AgentSession.updated_at))
                .limit(1)
            )
        ).first()
        if row is not None:
            return row
    if external_channel_id:
        return (
            await session.scalars(
                select(AgentSession)
                .where(AgentSession.source_platform == source_platform)
                .where(AgentSession.external_channel_id == external_channel_id)
                .where(AgentSession.status == "active")
                .order_by(desc(AgentSession.updated_at))
                .limit(1)
            )
        ).first()
    return None


async def _create_session_row(session: AsyncSession, payload: SessionCreate) -> AgentSession:
    now = utc_now()
    cap = payload.iteration_cap or await _default_iteration_cap(session)
    await _ensure_user(session, payload.user_id)
    row = AgentSession(
        id=new_id("sess"),
        agent_id=payload.agent_id if payload.agent_id in AGENTS else "orchestrator",
        user_id=payload.user_id,
        channel_id=None,
        title=payload.title or "LifeOS session",
        status="active",
        memory_scope=payload.memory_scope,
        iteration_cap=cap,
        visibility=payload.visibility,
        source_platform=payload.source_platform,
        external_channel_id=payload.external_channel_id,
        external_thread_id=payload.external_thread_id,
        external_message_id=payload.external_message_id,
        last_run_id=None,
        last_user_correction_id=None,
        paused_run_id=None,
        metadata_json=payload.metadata,
        created_at=now,
        updated_at=now,
    )
    session.add(row)
    await session.flush()
    return row


async def _default_iteration_cap(session: AsyncSession) -> int:
    row = await session.get(SystemSetting, "agent.default_iteration_cap")
    value = row.value_json.get("value") if row else 5
    try:
        return max(1, min(int(value), 50))
    except (TypeError, ValueError):
        return 5


async def _ensure_user(session: AsyncSession, user_id: str | None) -> None:
    if not user_id:
        return
    if await session.get(User, user_id) is not None:
        return
    now = utc_now()
    row = User(
        id=user_id,
        display_name="Discord owner",
        timezone="Africa/Casablanca",
        locale=None,
        role="owner",
        created_at=now,
        updated_at=now,
    )
    session.add(row)
    await session.flush()
    await create_audit_event(
        session,
        actor_type="system",
        actor_id="discord_gateway",
        event_type="user.placeholder_created",
        entity_type="user",
        entity_id=user_id,
        summary="Created placeholder owner user for Discord session.",
        after_json={
            "id": row.id,
            "display_name": row.display_name,
            "timezone": row.timezone,
            "role": row.role,
        },
    )
