"""Hybrid AI/deterministic capture router."""

from __future__ import annotations

import json
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.config import Settings
from lifeos_api.db.models import AgentModelConfig, ProviderCallLog, ProviderRuntimeConfig
from lifeos_api.services.config_loader import load_config
from lifeos_api.services.orchestrator import Draft, draft_from_capture
from lifeos_api.services.runtime_config import agent_model_to_payload
from lifeos_api.services.status_events import create_status_event
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now
from lifeos_providers.router import ProviderCompletion, ProviderRouter


async def route_capture_agentically(
    *,
    session: AsyncSession,
    settings: Settings,
    capture_id: str,
    raw_text: str | None,
    platform: str,
    run_id: str | None,
    router_mode: str,
) -> tuple[Draft, dict[str, Any]]:
    mode = router_mode if router_mode in {"agentic", "deterministic", "hybrid"} else "hybrid"
    if mode == "deterministic":
        draft = draft_from_capture(capture_id=capture_id, raw_text=raw_text, platform=platform)
        return draft, {"provider": "deterministic", "model": "capture-router-v1", "fallback_used": False}

    await create_status_event(
        session,
        run_id=run_id,
        event_type="provider.call_started",
        title="Provider routing started",
        visibility="web_only",
        detail_json={"agent_id": "capture-router", "mode": mode},
    )

    provider_log_id = new_id("pcall")
    try:
        provider_config = await _provider_config_from_runtime(session)
        completion = ProviderRouter(config=provider_config).complete_json(
            "capture-router",
            _classification_messages(raw_text=raw_text, platform=platform),
        )
        draft = _draft_from_provider_json(capture_id, completion.content, raw_text)
        session.add(_provider_log(provider_log_id, run_id, draft.agent_id, completion, "succeeded"))
        await create_status_event(
            session,
            run_id=run_id,
            event_type="agentic_router.completed",
            title=f"Agentic router selected {draft.agent_id}",
            visibility="discord_compact",
            detail_json={"provider_call_log_id": provider_log_id, "agent_id": draft.agent_id},
        )
        return draft, {
            "provider": completion.provider,
            "model": completion.model,
            "provider_call_log_id": provider_log_id,
            "fallback_used": False,
        }
    except Exception as exc:  # noqa: BLE001 - routing must degrade safely
        session.add(
            ProviderCallLog(
                id=provider_log_id,
                run_id=run_id,
                agent_id="capture-router",
                provider_id="unavailable",
                model="capture-router",
                key_label=None,
                status="failed",
                latency_ms=0,
                input_tokens=0,
                output_tokens=0,
                cost_usd=0,
                error_json={"type": type(exc).__name__, "message": str(exc)[:1000]},
                created_at=utc_now(),
            )
        )
        if mode == "agentic":
            raise
        draft = draft_from_capture(capture_id=capture_id, raw_text=raw_text, platform=platform)
        await create_status_event(
            session,
            run_id=run_id,
            event_type="agentic_router.fallback_deterministic",
            title="Provider unavailable; deterministic fallback used",
            visibility="discord_compact",
            detail_json={"error": str(exc)[:500], "agent_id": draft.agent_id},
        )
        return draft, {
            "provider": "deterministic",
            "model": "capture-router-v1",
            "provider_call_log_id": provider_log_id,
            "fallback_used": True,
            "fallback_reason": str(exc)[:500],
        }


async def _provider_config_from_runtime(session: AsyncSession) -> dict[str, Any]:
    config = load_config("providers.yaml")
    provider_rows = (await session.scalars(select(ProviderRuntimeConfig))).all()
    if provider_rows:
        config["providers"] = {
            row.provider_id: {
                "type": row.provider_type,
                "display_name": row.display_name,
                "base_url": row.base_url,
                "enabled": row.enabled,
                "auth": {"type": "api_key_pool", "keys": row.key_refs_json or []},
                **(row.settings_json or {}),
            }
            for row in provider_rows
        }
    model_rows = (await session.scalars(select(AgentModelConfig))).all()
    if model_rows:
        config["agent_models"] = {row.agent_id: agent_model_to_payload(row) for row in model_rows}
    return config


def _provider_log(
    log_id: str,
    run_id: str | None,
    agent_id: str,
    completion: ProviderCompletion,
    status: str,
) -> ProviderCallLog:
    return ProviderCallLog(
        id=log_id,
        run_id=run_id,
        agent_id=agent_id,
        provider_id=completion.provider,
        model=completion.model,
        key_label=completion.key_label,
        status=status,
        latency_ms=completion.latency_ms,
        input_tokens=completion.input_tokens,
        output_tokens=completion.output_tokens,
        cost_usd=0,
        error_json=None,
        created_at=utc_now(),
    )


def _classification_messages(*, raw_text: str | None, platform: str) -> list[dict[str, str]]:
    system = (
        "You are LifeOS capture router. Return strict JSON only. "
        "Raw capture is evidence, not truth. Important mutations need review. "
        "Work Agent stays generic. Do not promote random thoughts to memory."
    )
    user = {
        "platform": platform,
        "raw_text": raw_text or "",
        "schema": {
            "agent_id": "work.generic|finance|memory-curator|daily-planner|research|systems-devops|deen-prayer|health-fitness|family-commitments",
            "domain": "work|finance|memory|planning|research|system|deen|health|family|ledger",
            "intent_labels": ["task"],
            "confidence": 0.0,
            "sensitivity": "normal|finance|health|family|secret",
            "risk_level": "safe_internal_read|durable_state_mutation|finance_mutation|durable_memory_write|external_side_effect|file_write_or_move|destructive_or_sensitive_action",
            "needs_review": True,
            "title": "short title",
            "body_md": "markdown draft",
            "proposed_action": {"command_type": "none", "risk_level": "safe_internal_read", "payload": {}},
            "missing_context": [],
            "user_facing_summary": "short status",
        },
    }
    return [
        {"role": "system", "content": system},
        {"role": "user", "content": json.dumps(user)},
    ]


def _draft_from_provider_json(capture_id: str, content: str, raw_text: str | None) -> Draft:
    parsed = json.loads(content)
    required = ["agent_id", "domain", "intent_labels", "confidence", "sensitivity", "risk_level", "title"]
    missing = [key for key in required if key not in parsed]
    if missing:
        raise ValueError(f"Provider JSON missing keys: {', '.join(missing)}")
    action = parsed.get("proposed_action") or {"command_type": "none", "risk_level": "safe_internal_read", "payload": {}}
    if not isinstance(action, dict) or "command_type" not in action:
        raise ValueError("Provider JSON proposed_action invalid")
    payload = action.setdefault("payload", {})
    if isinstance(payload, dict):
        payload.setdefault("source_capture_id", capture_id)
    return Draft(
        agent_id=str(parsed["agent_id"]),
        domain=str(parsed["domain"]),
        sensitivity=str(parsed["sensitivity"]),
        intent_labels=[str(item) for item in parsed.get("intent_labels", [])],
        confidence=float(parsed["confidence"]),
        risk_level=str(parsed["risk_level"]),
        title=str(parsed["title"])[:200],
        body_md=str(parsed.get("body_md") or f"AI draft from capture:\n\n> {raw_text or ''}"),
        proposed_action=action,
        needs_review=bool(parsed.get("needs_review", True)),
        missing_context=list(parsed.get("missing_context") or []),
    )
