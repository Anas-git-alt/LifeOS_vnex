"""Agent registry endpoints."""

from pathlib import Path

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import Agent
from lifeos_api.deps import db_session_dep
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.config_loader import ROOT
from lifeos_api.services.serialization import row_to_dict
from lifeos_agents.registry import load_agent_configs
from lifeos_core.time import utc_now

router = APIRouter()


@router.get("/agents")
async def list_agents(session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    configs = load_agent_configs(ROOT / "configs" / "agents")
    db_rows = (await session.scalars(select(Agent))).all()
    db_by_id = {row.id: row for row in db_rows}
    items = []
    for config in configs:
        persisted = db_by_id.get(config.id)
        items.append(
            {
                "id": config.id,
                "display_name": config.display_name,
                "domain": config.domain,
                "role": config.role,
                "enabled": config.enabled,
                "autonomy_level": config.autonomy_level,
                "persisted": persisted is not None,
                "config": config.raw,
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
            row.enabled = config.enabled
            row.autonomy_level = config.autonomy_level
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
    configs = {config.id: config for config in load_agent_configs(ROOT / "configs" / "agents")}
    config = configs.get(agent_id)
    return {
        "agent": row_to_dict(
            row,
            ["id", "display_name", "domain", "registry_uri", "enabled", "autonomy_level", "version", "created_at"],
        )
        if row
        else None,
        "config": config.raw if config else None,
    }
