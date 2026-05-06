"""Provider status and routing endpoints."""

import os

from fastapi import APIRouter, Depends
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import ProviderCallLog
from lifeos_api.deps import db_session_dep
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.config_loader import load_config
from lifeos_api.services.serialization import row_to_dict
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now

router = APIRouter()


@router.get("/providers")
async def list_providers() -> dict[str, object]:
    config = load_config("providers.yaml")
    providers = []
    for provider_id, payload in config.get("providers", {}).items():
        keys = payload.get("auth", {}).get("keys", [])
        configured_keys = [
            {"label": key.get("label"), "env": key.get("env"), "configured": bool(os.getenv(str(key.get("env"))))}
            for key in keys
        ]
        providers.append(
            {
                "id": provider_id,
                "display_name": payload.get("display_name", provider_id),
                "type": payload.get("type"),
                "base_url": payload.get("base_url"),
                "enabled": payload.get("enabled", False),
                "keys": configured_keys,
                "use_for": payload.get("use_for", []),
            }
        )
    return {
        "items": providers,
        "agent_models": config.get("agent_models", {}),
        "circuit_breakers": config.get("circuit_breakers", {}),
        "count": len(providers),
    }


@router.post("/providers/test")
async def test_provider(
    provider_id: str,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    config = load_config("providers.yaml")
    provider = config.get("providers", {}).get(provider_id)
    if provider is None:
        return {"ok": False, "status": "not_found"}

    keys = provider.get("auth", {}).get("keys", [])
    configured = [key for key in keys if os.getenv(str(key.get("env")))]
    status = "configured" if configured or provider.get("auth", {}).get("type") == "chatgpt_oauth_cache" else "missing_key"
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
        error_json=None if configured else {"message": "No provider key configured"},
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
