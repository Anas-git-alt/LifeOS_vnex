"""Agent registry endpoints."""

from pathlib import Path
from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import Agent, AgentModelConfig
from lifeos_api.deps import db_session_dep
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.config_loader import ROOT
from lifeos_api.services.runtime_config import agent_model_to_payload
from lifeos_api.services.serialization import row_to_dict
from lifeos_agents.registry import load_agent_configs
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now

router = APIRouter()


AGENT_FIELDS = [
    "id",
    "display_name",
    "domain",
    "registry_uri",
    "enabled",
    "autonomy_level",
    "version",
    "created_at",
    "updated_at",
]
MODEL_FIELDS = [
    "id",
    "agent_id",
    "primary_provider_id",
    "primary_model",
    "secondary_provider_id",
    "secondary_model",
    "fallback_allowed",
    "settings_json",
    "created_at",
    "updated_at",
]


class AgentPatch(BaseModel):
    enabled: bool | None = None
    autonomy_level: str | None = None
    display_name: str | None = None


class AgentModelPatch(BaseModel):
    primary_provider_id: str | None = None
    primary_model: str | None = None
    secondary_provider_id: str | None = None
    secondary_model: str | None = None
    fallback_allowed: bool | None = None
    settings_json: dict[str, Any] = Field(default_factory=dict)


@router.get("/agents")
async def list_agents(session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    configs = load_agent_configs(ROOT / "configs" / "agents")
    db_rows = (await session.scalars(select(Agent))).all()
    db_by_id = {row.id: row for row in db_rows}
    model_rows = (await session.scalars(select(AgentModelConfig))).all()
    model_by_agent = {row.agent_id: row for row in model_rows}
    items = []
    for config in configs:
        persisted = db_by_id.get(config.id)
        model = model_by_agent.get(config.id)
        items.append(
            {
                "id": config.id,
                "display_name": persisted.display_name if persisted else config.display_name,
                "domain": persisted.domain if persisted else config.domain,
                "role": config.role,
                "enabled": persisted.enabled if persisted else config.enabled,
                "autonomy_level": persisted.autonomy_level if persisted else config.autonomy_level,
                "persisted": persisted is not None,
                "model": agent_model_to_payload(model) if model else None,
                "config": config.raw,
            }
        )
    for row in db_rows:
        if row.id in {config.id for config in configs}:
            continue
        model = model_by_agent.get(row.id)
        items.append(
            {
                **row_to_dict(row, AGENT_FIELDS),
                "role": "runtime",
                "persisted": True,
                "model": agent_model_to_payload(model) if model else None,
                "config": {},
            }
        )
    return {"items": items, "count": len(items)}


@router.post("/agents/sync")
async def sync_agents(session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    now = utc_now()
    synced = []
    for config in load_agent_configs(ROOT / "configs" / "agents"):
        row = await session.get(Agent, config.id)
        registry_uri = str(Path("configs/agents") / f"{config.id.replace('.', '-')}.yaml")
        if row is None:
            row = Agent(
                id=config.id,
                display_name=config.display_name,
                domain=config.domain,
                registry_uri=registry_uri,
                enabled=config.enabled,
                autonomy_level=config.autonomy_level,
                version=1,
                created_at=now,
                updated_at=now,
            )
            session.add(row)
        else:
            row.display_name = config.display_name
            row.domain = config.domain
            row.registry_uri = registry_uri
            row.updated_at = now
        synced.append(config.id)
    await create_audit_event(
        session,
        actor_type="system",
        actor_id="agent-registry",
        event_type="agents.synced",
        entity_type="agents",
        entity_id="registry",
        summary=f"Synced {len(synced)} agents from YAML registry.",
        after_json={"agents": synced},
    )
    await session.commit()
    return {"synced": synced, "count": len(synced)}


@router.get("/agents/{agent_id}")
async def get_agent(agent_id: str, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    row = await session.get(Agent, agent_id)
    model = (
        await session.scalars(select(AgentModelConfig).where(AgentModelConfig.agent_id == agent_id))
    ).first()
    configs = {config.id: config for config in load_agent_configs(ROOT / "configs" / "agents")}
    config = configs.get(agent_id)
    return {
        "agent": row_to_dict(
            row,
            AGENT_FIELDS,
        )
        if row
        else None,
        "model": row_to_dict(model, MODEL_FIELDS) if model else None,
        "config": config.raw if config else None,
    }


@router.patch("/agents/{agent_id}")
async def patch_agent(
    agent_id: str,
    payload: AgentPatch,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    row = await session.get(Agent, agent_id)
    if row is None:
        return {"ok": False, "status": "not_found"}
    before = row_to_dict(row, AGENT_FIELDS)
    now = utc_now()
    if payload.enabled is not None:
        row.enabled = payload.enabled
    if payload.autonomy_level is not None:
        row.autonomy_level = _normalize_autonomy(payload.autonomy_level)
    if payload.display_name is not None:
        row.display_name = payload.display_name
    row.version += 1
    row.updated_at = now
    after = row_to_dict(row, AGENT_FIELDS)
    await create_audit_event(
        session,
        actor_type="user",
        actor_id="owner",
        event_type="agent.updated",
        entity_type="agent",
        entity_id=agent_id,
        summary=f"Updated agent {agent_id}",
        before_json=before,
        after_json=after,
    )
    await session.commit()
    return {"ok": True, "agent": after}


@router.get("/agents/{agent_id}/model")
async def get_agent_model(agent_id: str, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    row = (
        await session.scalars(select(AgentModelConfig).where(AgentModelConfig.agent_id == agent_id))
    ).first()
    if row is None:
        return {"ok": False, "status": "not_found"}
    return {"ok": True, "model": row_to_dict(row, MODEL_FIELDS), "effective": agent_model_to_payload(row)}


@router.patch("/agents/{agent_id}/model")
async def patch_agent_model(
    agent_id: str,
    payload: AgentModelPatch,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    now = utc_now()
    row = (
        await session.scalars(select(AgentModelConfig).where(AgentModelConfig.agent_id == agent_id))
    ).first()
    if row is None:
        row = AgentModelConfig(
            id=new_id("amodel"),
            agent_id=agent_id,
            primary_provider_id=None,
            primary_model=None,
            secondary_provider_id=None,
            secondary_model=None,
            fallback_allowed=True,
            settings_json={},
            created_at=now,
            updated_at=now,
        )
        session.add(row)
    before = row_to_dict(row, MODEL_FIELDS)
    for field in [
        "primary_provider_id",
        "primary_model",
        "secondary_provider_id",
        "secondary_model",
        "fallback_allowed",
    ]:
        value = getattr(payload, field)
        if value is not None:
            setattr(row, field, value)
    if payload.settings_json:
        row.settings_json = {**(row.settings_json or {}), **payload.settings_json}
    row.updated_at = now
    after = row_to_dict(row, MODEL_FIELDS)
    await create_audit_event(
        session,
        actor_type="user",
        actor_id="owner",
        event_type="agent_model.updated",
        entity_type="agent_model_config",
        entity_id=row.id,
        summary=f"Updated model config for {agent_id}",
        before_json=before,
        after_json=after,
    )
    await session.commit()
    return {"ok": True, "model": after, "effective": agent_model_to_payload(row)}


def _normalize_autonomy(value: str) -> str:
    mapped = {
        "owner_gated": "manual",
        "explicit_owner_approval": "manual",
    }.get(value, value)
    return mapped if mapped in {"manual", "review_gated", "balanced", "safe"} else "review_gated"
