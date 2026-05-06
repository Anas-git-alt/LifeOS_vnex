"""Health and readiness endpoints."""

from pathlib import Path

from fastapi import APIRouter, Depends

from lifeos_api.config import Settings
from lifeos_api.deps import settings_dep
from lifeos_api.schemas.health import HealthResponse, ReadinessResponse, ReadinessStatus

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(service="lifeos-api", status="ok")


@router.get("/readiness", response_model=ReadinessResponse)
async def readiness(settings: Settings = Depends(settings_dep)) -> ReadinessResponse:
    vault_path = Path(settings.vault_path)
    checks = [
        ReadinessStatus(
            name="vault_path",
            ok=vault_path.exists(),
            detail=str(vault_path),
        ),
        ReadinessStatus(
            name="database_url_configured",
            ok=bool(settings.database_url),
            detail="configured" if settings.database_url else "missing DATABASE_URL",
        ),
        ReadinessStatus(
            name="redis_url_configured",
            ok=bool(settings.redis_url),
            detail="configured" if settings.redis_url else "missing REDIS_URL",
        ),
        ReadinessStatus(
            name="discord_configured",
            ok=bool(
                settings.discord_bot_token
                and settings.discord_owner_user_id
                and settings.discord_approval_channel_id
            ),
            detail="bot token, owner id, and approval channel configured"
            if (
                settings.discord_bot_token
                and settings.discord_owner_user_id
                and settings.discord_approval_channel_id
            )
            else "missing Discord token, owner id, or approval channel",
        ),
        ReadinessStatus(
            name="telegram_configured",
            ok=bool(settings.telegram_bot_token and settings.telegram_owner_user_id),
            detail="bot token and owner id configured"
            if settings.telegram_bot_token and settings.telegram_owner_user_id
                else "missing Telegram token or owner id",
        ),
        ReadinessStatus(
            name="router_mode",
            ok=settings.router_mode in {"agentic", "deterministic", "hybrid"},
            detail=settings.router_mode,
        ),
        ReadinessStatus(
            name="providers_configured",
            ok=any(count > 0 for count in settings.provider_key_counts.values()),
            detail=", ".join(f"{key}={value}" for key, value in settings.provider_key_counts.items()),
        ),
    ]

    return ReadinessResponse(
        service="lifeos-api",
        status="ready" if all(check.ok for check in checks[:3]) else "degraded",
        environment=settings.environment,
        timezone=settings.timezone,
        checks=checks,
        provider_key_counts=settings.provider_key_counts,
    )
