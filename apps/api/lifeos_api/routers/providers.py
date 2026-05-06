"""Provider status and routing endpoints."""

from __future__ import annotations

import os
from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import AgentModelConfig, ProviderCallLog, ProviderRuntimeConfig
from lifeos_api.deps import db_session_dep
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.runtime_config import agent_model_to_payload, provider_to_payload
from lifeos_api.services.serialization import row_to_dict
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now

router = APIRouter()


class ProviderPatch(BaseModel):
    display_name: str | None = None
    base_url: str | None = None
    enabled: bool | None = None
    key_refs_json: list[dict[str, Any]] | None = None
    settings_json: dict[str, Any] = Field(default_factory=dict)


PROVIDER_FIELDS = [
    "id",
    "provider_id",
    "display_name",
    "provider_type",
    "base_url",
    "enabled",
    "key_refs_json",
    "settings_json",
    "created_at",
    "updated_at",
]


@router.get("/providers")
async def list_providers(session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    provider_rows = (
        await session.scalars(select(ProviderRuntimeConfig).order_by(ProviderRuntimeConfig.provider_id))
    ).all()
    model_rows = (await session.scalars(select(AgentModelConfig))).all()
    providers = [provider_to_payload(row) for row in provider_rows]
    return {
        "items": providers,
        "agent_models": {row.agent_id: agent_model_to_payload(row) for row in model_rows},
        "count": len(providers),
    }


@router.patch("/providers/{provider_id}")
async def patch_provider(
    provider_id: str,
    payload: ProviderPatch,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    row = (
        await session.scalars(
            select(ProviderRuntimeConfig).where(ProviderRuntimeConfig.provider_id == provider_id)
        )
    ).first()
    if row is None:
        return {"ok": False, "status": "not_found"}
    before = row_to_dict(row, PROVIDER_FIELDS)
    if payload.display_name is not None:
        row.display_name = payload.display_name
    if payload.base_url is not None:
        row.base_url = payload.base_url
    if payload.enabled is not None:
        row.enabled = payload.enabled
    if payload.key_refs_json is not None:
        row.key_refs_json = _safe_key_refs(payload.key_refs_json)
    if payload.settings_json:
        row.settings_json = {**(row.settings_json or {}), **payload.settings_json}
    row.updated_at = utc_now()
    after = row_to_dict(row, PROVIDER_FIELDS)
    await create_audit_event(
        session,
        actor_type="user",
        actor_id="owner",
        event_type="provider_config.updated",
        entity_type="provider",
        entity_id=provider_id,
        summary=f"Updated provider {provider_id}",
        before_json=before,
        after_json=after,
    )
    await session.commit()
    return {"ok": True, "provider": provider_to_payload(row)}


@router.post("/providers/{provider_id}/test")
async def test_provider_path(
    provider_id: str,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    return await _test_provider(provider_id, session)


@router.post("/providers/test")
async def test_provider(
    provider_id: str,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    return await _test_provider(provider_id, session)


async def _test_provider(provider_id: str, session: AsyncSession) -> dict[str, object]:
    provider = (
        await session.scalars(
            select(ProviderRuntimeConfig).where(ProviderRuntimeConfig.provider_id == provider_id)
        )
    ).first()
    if provider is None:
        return {"ok": False, "status": "not_found"}

    keys = provider.key_refs_json or []
    configured = [key for key in keys if key.get("env") and os.getenv(str(key["env"]))]
    status = (
        "configured"
        if configured or provider.provider_type in {"codex_cli", "chatgpt_oauth_cache"}
        else "missing_key"
    )
    log = ProviderCallLog(
        id=new_id("pcall"),
        run_id=None,
        agent_id=None,
        provider_id=provider_id,
        model="health-check",
        key_label=configured[0].get("label") if configured else None,
        status=status,
        latency_ms=0,
        input_tokens=0,
        output_tokens=0,
        cost_usd=0,
        error_json=None if status == "configured" else {"message": "No provider key configured"},
        created_at=utc_now(),
    )
    session.add(log)
    await create_audit_event(
        session,
        actor_type="system",
        actor_id="provider-router",
        event_type="provider.tested",
        entity_type="provider",
        entity_id=provider_id,
        summary=f"Provider {provider_id} test status: {status}",
        after_json={"status": status},
    )
    await session.commit()
    return {"ok": status == "configured", "status": status, "log_id": log.id}


@router.get("/providers/calls")
async def list_provider_calls(
    limit: int = 100,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    rows = (
        await session.scalars(select(ProviderCallLog).order_by(desc(ProviderCallLog.created_at)).limit(limit))
    ).all()
    fields = [
        "id",
        "run_id",
        "agent_id",
        "provider_id",
        "model",
        "key_label",
        "status",
        "latency_ms",
        "input_tokens",
        "output_tokens",
        "cost_usd",
        "error_json",
        "created_at",
    ]
    return {"items": [row_to_dict(row, fields) for row in rows], "count": len(rows)}


def _safe_key_refs(keys: list[dict[str, Any]]) -> list[dict[str, Any]]:
    safe = []
    for key in keys:
        safe.append(
            {
                "env": key.get("env"),
                "label": key.get("label"),
                "priority": key.get("priority", 100),
            }
        )
    return safe
