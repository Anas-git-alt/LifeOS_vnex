"""Ask LifeOS flow."""

from __future__ import annotations

from pydantic import BaseModel
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from fastapi import APIRouter, Depends

from lifeos_api.db.models import AgentRun, LifeItem, ReviewItem
from lifeos_api.deps import db_session_dep
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.serialization import row_to_dict
from lifeos_api.services.status_events import create_status_event
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now

router = APIRouter()


class AskCreate(BaseModel):
    message: str
    source_platform: str = "web"
    source_external_message_id: str | None = None


@router.post("/ask")
async def ask_lifeos(payload: AskCreate, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    now = utc_now()
    lower = payload.message.lower()
    run = AgentRun(
        id=new_id("run"),
        session_id=None,
        root_capture_id=None,
        initiating_user_id=None,
        orchestrator_agent_id="orchestrator",
        active_agent_id=_select_agent(lower),
        status="running",
        status_summary="Ask LifeOS",
        provider_used="deterministic",
        model_used="ask-router-v1",
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
        event_type="ask.received",
        title="Ask LifeOS received",
        visibility="discord_compact",
        detail_json={"source_platform": payload.source_platform},
    )

    review_id = None
    if _asks_for_automation(lower):
        review = ReviewItem(
            id=new_id("rev"),
            kind="planning",
            title="Automation request",
            body_md=f"Proposed automation from Ask LifeOS:\n\n> {payload.message}",
            source_capture_id=None,
            source_uri=None,
            proposed_by_agent_id="daily-planner",
            assigned_agent_id="approval-manager",
            priority="normal",
            confidence=0.72,
            risk_level="durable_state_mutation",
            sensitivity="normal",
            proposed_action_json={
                "command_type": "job.create",
                "risk_level": "durable_state_mutation",
                "payload": {
                    "name": payload.message[:80],
                    "description_md": payload.message,
                    "schedule_type": "natural_language",
                    "schedule": {"source_text": payload.message},
                    "target_agent_id": "daily-planner",
                    "command": {"type": "notify", "text": payload.message},
                },
            },
            validation_json={"reason": "new automations require review"},
            status="pending",
            expires_at=None,
            snoozed_until=None,
            created_at=now,
            updated_at=now,
        )
        session.add(review)
        review_id = review.id
        run.status = "waiting_approval"
        run.status_summary = "Automation review created"
        answer = "Review needed: automation request."
        await create_status_event(
            session,
            run_id=run.id,
            event_type="review.created",
            title="Review created: automation request",
            visibility="discord_compact",
            detail_json={"review_item_id": review_id},
        )
    elif "today" in lower or "plan" in lower:
        tasks = await _open_tasks(session, limit=8)
        answer = _today_answer(tasks)
        run.status = "answered"
        run.status_summary = "Answered from approved state"
        run.finished_at = now
    elif "pending work" in lower or "work" in lower:
        tasks = await _open_tasks(session, domain="work", limit=12)
        answer = _work_answer(tasks)
        run.status = "answered"
        run.status_summary = "Answered from approved work state"
        run.finished_at = now
    else:
        answer = "I can answer from approved state or create escalation-gated proposals. No state mutation needed."
        run.status = "answered"
        run.status_summary = "Answered directly"
        run.finished_at = now

    run.updated_at = now
    await create_audit_event(
        session,
        actor_type="user",
        actor_id="owner",
        event_type="ask_lifeos.created",
        entity_type="agent_run",
        entity_id=run.id,
        summary=f"Ask LifeOS: {payload.message[:120]}",
        after_json={"answer": answer, "review_item_id": review_id},
        trace_id=run.trace_id,
    )
    await session.commit()
    return {
        "ok": True,
        "run_id": run.id,
        "agent_id": run.active_agent_id,
        "status": run.status,
        "answer": answer,
        "review_item_id": review_id,
    }


async def _open_tasks(session: AsyncSession, domain: str | None = None, limit: int = 8) -> list[LifeItem]:
    stmt = select(LifeItem).where(LifeItem.status == "open")
    if domain:
        stmt = stmt.where(LifeItem.domain == domain)
    return (await session.scalars(stmt.order_by(desc(LifeItem.created_at)).limit(limit))).all()


def _today_answer(tasks: list[LifeItem]) -> str:
    if not tasks:
        return "Today plan: no approved open tasks found. Check review queue for pending items."
    lines = ["Today plan from approved state:"]
    lines.extend(f"- {task.title} ({task.domain})" for task in tasks)
    return "\n".join(lines)


def _work_answer(tasks: list[LifeItem]) -> str:
    if not tasks:
        return "No approved open work tasks found."
    lines = ["Pending work:"]
    lines.extend(f"- {task.title}" for task in tasks)
    return "\n".join(lines)


def _asks_for_automation(lower: str) -> bool:
    return any(token in lower for token in ["every weekday", "every day", "daily", "weekly", "reminder every"])


def _select_agent(lower: str) -> str:
    if "finance" in lower or "spent" in lower or "paid" in lower:
        return "finance"
    if "today" in lower or "plan" in lower or "reminder" in lower:
        return "daily-planner"
    if "work" in lower:
        return "work.generic"
    return "orchestrator"
