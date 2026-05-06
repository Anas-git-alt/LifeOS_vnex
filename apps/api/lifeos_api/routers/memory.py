"""Memory candidate, fact, and vault index endpoints."""

from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import MemoryCandidate, MemoryFact, ReviewItem, VaultIndexEntry
from lifeos_api.deps import db_session_dep
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.serialization import row_to_dict
from lifeos_api.services.status_events import create_status_event
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now

router = APIRouter()


class MemoryCandidateCreate(BaseModel):
    source_capture_id: str | None = None
    proposed_by_agent_id: str = "memory-curator"
    candidate_kind: str = "fact"
    statement_md: str
    domain: str = "planning"
    evidence_refs: list[dict[str, Any]] = Field(default_factory=list)
    confidence: float = 0.75
    sensitivity: str = "normal"


@router.get("/memory/candidates")
async def list_candidates(
    status: str | None = None,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    stmt = select(MemoryCandidate).order_by(desc(MemoryCandidate.created_at)).limit(100)
    if status:
        stmt = stmt.where(MemoryCandidate.status == status)
    rows = (await session.scalars(stmt)).all()
    fields = [
        "id",
        "source_capture_id",
        "proposed_by_agent_id",
        "candidate_kind",
        "statement_md",
        "evidence_refs",
        "confidence",
        "sensitivity",
        "status",
        "review_item_id",
        "created_at",
        "updated_at",
    ]
    return {"items": [row_to_dict(row, fields) for row in rows], "count": len(rows)}


@router.post("/memory/candidates")
async def create_candidate(
    payload: MemoryCandidateCreate,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    now = utc_now()
    candidate = MemoryCandidate(
        id=new_id("memcand"),
        source_capture_id=payload.source_capture_id,
        proposed_by_agent_id=payload.proposed_by_agent_id,
        candidate_kind=payload.candidate_kind,
        statement_md=payload.statement_md,
        evidence_refs=payload.evidence_refs,
        confidence=payload.confidence,
        sensitivity=payload.sensitivity,
        status="pending_review",
        review_item_id=None,
        created_at=now,
        updated_at=now,
    )
    session.add(candidate)
    await session.flush()
    review = ReviewItem(
        id=new_id("rev"),
        kind="memory",
        title="Memory candidate",
        body_md=payload.statement_md,
        source_capture_id=payload.source_capture_id,
        source_uri=None,
        proposed_by_agent_id=payload.proposed_by_agent_id,
        assigned_agent_id="approval-manager",
        priority="normal",
        confidence=payload.confidence,
        risk_level="durable_memory_write",
        sensitivity=payload.sensitivity,
        proposed_action_json={
            "command_type": "memory_fact.create",
            "risk_level": "durable_memory_write",
            "payload": {
                "fact_kind": payload.candidate_kind,
                "domain": payload.domain,
                "statement_md": payload.statement_md,
                "confidence": payload.confidence,
                "sensitivity": payload.sensitivity,
                "source_candidate_id": candidate.id,
                "evidence_refs": payload.evidence_refs,
            },
        },
        validation_json={},
        status="pending",
        expires_at=None,
        snoozed_until=None,
        created_at=now,
        updated_at=now,
    )
    session.add(review)
    await session.flush()
    candidate.review_item_id = review.id
    await create_status_event(
        session,
        event_type="memory.candidate_created",
        title="Memory candidate created",
        visibility="discord_compact",
        detail_json={"candidate_id": candidate.id, "review_item_id": review.id},
    )
    await create_audit_event(
        session,
        actor_type="agent",
        actor_id=payload.proposed_by_agent_id,
        event_type="memory.candidate_created",
        entity_type="memory_candidate",
        entity_id=candidate.id,
        summary="Created memory candidate and review item.",
        after_json={"review_item_id": review.id, "statement_md": payload.statement_md},
    )
    await session.commit()
    return {"candidate_id": candidate.id, "review_item_id": review.id}


@router.get("/memory/facts")
async def list_facts(session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    rows = (await session.scalars(select(MemoryFact).order_by(desc(MemoryFact.created_at)).limit(100))).all()
    fields = [
        "id",
        "fact_kind",
        "statement_md",
        "domain",
        "confidence",
        "sensitivity",
        "status",
        "source_candidate_id",
        "evidence_refs",
        "vault_uri",
        "created_at",
        "updated_at",
    ]
    return {"items": [row_to_dict(row, fields) for row in rows], "count": len(rows)}


@router.get("/memory/vault-index")
async def list_vault_index(session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    rows = (
        await session.scalars(select(VaultIndexEntry).order_by(desc(VaultIndexEntry.created_at)).limit(100))
    ).all()
    fields = [
        "id",
        "vault_uri",
        "content_hash",
        "index_kind",
        "domain",
        "sensitivity",
        "indexed_text",
        "metadata_json",
        "created_at",
        "updated_at",
    ]
    return {"items": [row_to_dict(row, fields) for row in rows], "count": len(rows)}
