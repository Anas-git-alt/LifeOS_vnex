"""Job and automation endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.config import Settings
from lifeos_api.db.models import Job, JobRun, ReviewItem
from lifeos_api.deps import db_session_dep, settings_dep
from lifeos_api.schemas.job import JobCreate
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.command_bus import CommandBus, CommandRequest
from lifeos_api.services.serialization import row_to_dict
from lifeos_api.services.status_events import create_status_event
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now

router = APIRouter()


JOB_FIELDS = [
    "id",
    "name",
    "description_md",
    "schedule_type",
    "schedule_json",
    "timezone",
    "target_agent_id",
    "command_json",
    "approval_policy",
    "enabled",
    "created_at",
    "updated_at",
]


@router.get("/jobs")
async def list_jobs(session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    rows = (await session.scalars(select(Job).order_by(desc(Job.created_at)).limit(100))).all()
    return {"items": [row_to_dict(row, JOB_FIELDS) for row in rows], "count": len(rows)}


@router.post("/jobs")
async def create_job_proposal(
    payload: JobCreate,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    now = utc_now()
    review = ReviewItem(
        id=new_id("rev"),
        kind="job",
        title=f"Create job: {payload.name}",
        body_md=payload.description_md or payload.name,
        source_capture_id=None,
        source_uri=None,
        proposed_by_agent_id="daily-planner",
        assigned_agent_id="approval-manager",
        priority="normal",
        confidence=1,
        risk_level="durable_state_mutation",
        sensitivity="normal",
        proposed_action_json={
            "command_type": "job.create",
            "risk_level": "durable_state_mutation",
            "payload": payload.model_dump(mode="json"),
        },
        validation_json={},
        status="pending",
        expires_at=None,
        snoozed_until=None,
        created_at=now,
        updated_at=now,
    )
    session.add(review)
    await create_status_event(
        session,
        event_type="review.created",
        title=f"Job review created: {payload.name}",
        visibility="discord_compact",
        detail_json={"review_item_id": review.id},
    )
    await create_audit_event(
        session,
        actor_type="system",
        actor_id="scheduler",
        event_type="job.proposed",
        entity_type="review_item",
        entity_id=review.id,
        summary=f"Proposed job: {payload.name}",
    )
    await session.commit()
    return {"review_item_id": review.id, "status": "pending_review"}


@router.post("/jobs/{job_id}/pause")
async def pause_job(job_id: str, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    return await _set_job_enabled(session, job_id, False)


@router.post("/jobs/{job_id}/resume")
async def resume_job(job_id: str, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    return await _set_job_enabled(session, job_id, True)


@router.post("/jobs/{job_id}/test")
async def test_job(
    job_id: str,
    session: AsyncSession = Depends(db_session_dep),
    settings: Settings = Depends(settings_dep),
) -> dict[str, object]:
    job = await session.get(Job, job_id)
    if job is None:
        return {"error": "not_found"}
    run = JobRun(
        id=new_id("jobrun"),
        job_id=job.id,
        run_id=None,
        status="succeeded",
        started_at=utc_now(),
        finished_at=utc_now(),
        output_summary_md=f"Dry-run for {job.name}",
        error_json=None,
        created_at=utc_now(),
    )
    session.add(run)
    await create_status_event(
        session,
        event_type="job.started",
        title=f"Job dry-run: {job.name}",
        visibility="discord_compact",
        detail_json={"job_id": job.id, "job_run_id": run.id},
    )
    await create_audit_event(
        session,
        actor_type="system",
        actor_id="scheduler",
        event_type="job.tested",
        entity_type="job",
        entity_id=job.id,
        summary=f"Dry-ran job {job.name}",
        after_json={"job_run_id": run.id, "settings_timezone": settings.timezone},
    )
    await session.commit()
    return {"job_run_id": run.id, "status": run.status}


async def _set_job_enabled(session: AsyncSession, job_id: str, enabled: bool) -> dict[str, object]:
    job = await session.get(Job, job_id)
    if job is None:
        return {"error": "not_found"}
    job.enabled = enabled
    job.updated_at = utc_now()
    await create_audit_event(
        session,
        actor_type="user",
        actor_id="owner",
        event_type="job.updated",
        entity_type="job",
        entity_id=job.id,
        summary=f"Job {'resumed' if enabled else 'paused'}: {job.name}",
    )
    await session.commit()
    return row_to_dict(job, JOB_FIELDS)
