"""Runtime config seed/load helpers.

YAML remains bootstrap defaults. DB rows override YAML for daily operations.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import Agent, AgentModelConfig, ProviderRuntimeConfig, SystemSetting, ToolPermission
from lifeos_api.services.config_loader import ROOT, load_config
from lifeos_agents.registry import load_agent_configs
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now
from lifeos_tools.registry import load_tool_config


async def seed_runtime_config(session: AsyncSession) -> None:
    now = utc_now()
    await _seed_agents(session, now)
    await _seed_agent_models(session, now)
    await _seed_providers(session, now)
    await _seed_tools(session, now)
    await _seed_settings(session, now)
    await session.commit()


async def _seed_agents(session: AsyncSession, now) -> None:
    for config in load_agent_configs(ROOT / "configs" / "agents"):
        row = await session.get(Agent, config.id)
        registry_uri = str(Path("configs/agents") / f"{config.id.replace('.', '-')}.yaml")
        if row is None:
            session.add(
                Agent(
                    id=config.id,
                    display_name=config.display_name,
                    domain=config.domain,
                    registry_uri=registry_uri,
                    enabled=config.enabled,
                    autonomy_level=_normalize_autonomy(config.autonomy_level),
                    version=1,
                    created_at=now,
                    updated_at=now,
                )
            )


async def _seed_agent_models(session: AsyncSession, now) -> None:
    config = load_config("providers.yaml")
    for agent_id, raw in config.get("agent_models", {}).items():
        existing = (
            await session.scalars(select(AgentModelConfig).where(AgentModelConfig.agent_id == agent_id))
        ).first()
        if existing is not None:
            continue
        primary = raw.get("primary", {})
        secondary = raw.get("secondary", {})
        settings = {key: value for key, value in raw.items() if key not in {"primary", "secondary", "fallback_allowed"}}
        session.add(
            AgentModelConfig(
                id=new_id("amodel"),
                agent_id=agent_id,
                primary_provider_id=primary.get("provider"),
                primary_model=primary.get("model"),
                secondary_provider_id=secondary.get("provider"),
                secondary_model=secondary.get("model"),
                fallback_allowed=bool(raw.get("fallback_allowed", True)),
                settings_json=settings,
                created_at=now,
                updated_at=now,
            )
        )


async def _seed_providers(session: AsyncSession, now) -> None:
    config = load_config("providers.yaml")
    for provider_id, raw in config.get("providers", {}).items():
        existing = (
            await session.scalars(
                select(ProviderRuntimeConfig).where(ProviderRuntimeConfig.provider_id == provider_id)
            )
        ).first()
        if existing is not None:
            continue
        keys = [
            {
                "env": key.get("env"),
                "label": key.get("label"),
                "priority": key.get("priority", 100),
            }
            for key in raw.get("auth", {}).get("keys", [])
        ]
        session.add(
            ProviderRuntimeConfig(
                id=new_id("prov"),
                provider_id=provider_id,
                display_name=raw.get("display_name", provider_id),
                provider_type=raw.get("type", "unknown"),
                base_url=raw.get("base_url"),
                enabled=bool(raw.get("enabled", True)),
                key_refs_json=keys,
                settings_json={
                    key: value
                    for key, value in raw.items()
                    if key not in {"display_name", "type", "base_url", "enabled", "auth"}
                },
                created_at=now,
                updated_at=now,
            )
        )


async def _seed_tools(session: AsyncSession, now) -> None:
    config = load_config("tools.yaml")
    for agent_id, tools in config.get("agent_permissions", {}).items():
        for tool_id, raw in tools.items():
            existing = (
                await session.scalars(
                    select(ToolPermission)
                    .where(ToolPermission.agent_id == agent_id)
                    .where(ToolPermission.tool_id == tool_id)
                )
            ).first()
            if existing is not None:
                continue
            payload = raw if isinstance(raw, dict) else {"effect": str(raw)}
            session.add(
                ToolPermission(
                    id=new_id("perm"),
                    agent_id=agent_id,
                    tool_id=tool_id,
                    effect=str(payload.get("effect", "deny")),
                    mode=str(payload.get("mode", "read_only")),
                    scopes=dict(payload.get("scopes", {})),
                    requires_approval_when=dict(payload.get("requires_approval_when", {})),
                    created_at=now,
                    updated_at=now,
                )
            )

    # Ensure tools themselves are also present when sync endpoint has not run.
    from lifeos_api.db.models import Tool

    for tool in load_tool_config(ROOT / "configs" / "tools.yaml"):
        if await session.get(Tool, tool.id) is not None:
            continue
        session.add(
            Tool(
                id=tool.id,
                display_name=tool.display_name,
                category=tool.category,
                description=tool.raw.get("description"),
                risk_level=tool.risk_level,
                enabled=True,
                schema_json=tool.raw.get("schemas", {}),
                created_at=now,
                updated_at=now,
            )
        )


async def _seed_settings(session: AsyncSession, now) -> None:
    if await session.get(SystemSetting, "router.mode") is None:
        session.add(
            SystemSetting(
                key="router.mode",
                value_json={"value": os.getenv("LIFEOS_ROUTER_MODE", "hybrid")},
                description="agentic, hybrid, or deterministic capture routing",
                created_at=now,
                updated_at=now,
            )
        )
    if await session.get(SystemSetting, "agent.default_iteration_cap") is None:
        session.add(
            SystemSetting(
                key="agent.default_iteration_cap",
                value_json={"value": 5},
                description="Default max iterations for Discord/WebUI agent sessions.",
                created_at=now,
                updated_at=now,
            )
        )


async def get_agent_autonomy(session: AsyncSession, agent_id: str) -> str:
    row = await session.get(Agent, agent_id)
    return _normalize_autonomy(row.autonomy_level if row else "review_gated")


async def get_router_mode(session: AsyncSession, env_default: str = "hybrid") -> str:
    row = await session.get(SystemSetting, "router.mode")
    value = row.value_json.get("value") if row else env_default
    return str(value or "hybrid")


async def get_agent_model_map(session: AsyncSession) -> dict[str, dict[str, Any]]:
    rows = (await session.scalars(select(AgentModelConfig))).all()
    return {row.agent_id: agent_model_to_payload(row) for row in rows}


def agent_model_to_payload(row: AgentModelConfig) -> dict[str, Any]:
    payload = {
        "primary": {
            "provider": row.primary_provider_id,
            "model": row.primary_model,
        },
        "secondary": {
            "provider": row.secondary_provider_id,
            "model": row.secondary_model,
        },
        "fallback_allowed": row.fallback_allowed,
    }
    payload.update(row.settings_json or {})
    return payload


def provider_to_payload(row: ProviderRuntimeConfig) -> dict[str, Any]:
    keys = row.key_refs_json or []
    return {
        "id": row.provider_id,
        "display_name": row.display_name,
        "type": row.provider_type,
        "base_url": row.base_url,
        "enabled": row.enabled,
        "keys": [
            {
                "label": key.get("label"),
                "env": key.get("env"),
                "configured": bool(os.getenv(str(key.get("env")))) if key.get("env") else False,
            }
            for key in keys
        ],
        "settings": row.settings_json or {},
    }


def _normalize_autonomy(value: str | None) -> str:
    mapped = {
        "owner_gated": "manual",
        "explicit_owner_approval": "manual",
    }.get(str(value or ""), str(value or "review_gated"))
    return mapped if mapped in {"manual", "review_gated", "balanced", "safe"} else "review_gated"
