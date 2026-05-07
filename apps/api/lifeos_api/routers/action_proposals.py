"""Inline conversational action proposal endpoints."""

from __future__ import annotations

from typing import Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.config import Settings
from lifeos_api.deps import db_session_dep, settings_dep
from lifeos_api.services.conversation_action_service import (
    execute_action_proposal,
    get_action_proposal as get_action_proposal_row,
    list_action_proposals,
    proposal_to_public_dict,
    reject_action_proposal,
    revise_action_proposal,
)

router = APIRouter()


class ActionProposalDecisionCreate(BaseModel):
    decision: Literal["approve", "reject", "revise", "ask"]
    decision_text: str | None = None
    decision_payload: dict[str, object] = Field(default_factory=dict)
    source_platform: str = "discord"
    source_external_message_id: str | None = None


@router.get("/action-proposals")
async def get_action_proposals(
    status: str | None = None,
    limit: int = 50,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    rows = await list_action_proposals(session, status=status, limit=limit)
    return {"items": [proposal_to_public_dict(row) for row in rows], "count": len(rows)}


@router.get("/action-proposals/{proposal_id}")
async def get_action_proposal(
    proposal_id: str,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    row = await get_action_proposal_row(session, proposal_id)
    if row is None:
        return {"ok": False, "status": "not_found"}
    return {"ok": True, "proposal": proposal_to_public_dict(row)}


@router.post("/action-proposals/{proposal_id}/decision")
async def decide_action_proposal(
    proposal_id: str,
    payload: ActionProposalDecisionCreate,
    session: AsyncSession = Depends(db_session_dep),
    settings: Settings = Depends(settings_dep),
) -> dict[str, object]:
    row = await get_action_proposal_row(session, proposal_id)
    if row is None:
        return {"ok": False, "status": "not_found", "result": {}}

    if payload.decision == "approve":
        result = await execute_action_proposal(
            session,
            settings,
            row,
            actor_type="user",
            actor_id="owner",
        )
        await session.commit()
        return {
            "ok": True,
            "status": row.status,
            "proposal": proposal_to_public_dict(row),
            "result": result.model_dump(mode="json"),
        }

    if payload.decision == "reject":
        await reject_action_proposal(session, row)
        await session.commit()
        return {"ok": True, "status": row.status, "proposal": proposal_to_public_dict(row), "result": {}}

    if payload.decision == "revise":
        row = await revise_action_proposal(
            session,
            row,
            revision_text=payload.decision_text or str(payload.decision_payload.get("text") or ""),
            timezone=settings.timezone,
        )
        await session.commit()
        return {"ok": True, "status": row.status, "proposal": proposal_to_public_dict(row), "result": {}}

    return {
        "ok": True,
        "status": row.status,
        "proposal": proposal_to_public_dict(row),
        "result": {"message": "Proposal details returned without mutation."},
    }
