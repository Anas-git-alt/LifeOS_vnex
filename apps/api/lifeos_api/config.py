"""Runtime settings for the API.

The settings object intentionally contains only infrastructure configuration.
Agent behavior, tool policy, provider routing, and gateway channel maps live in
YAML under ``configs/`` so they can be reviewed and audited separately.
"""

from functools import lru_cache
from pathlib import Path

from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Environment-backed settings for LifeOS API services."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="",
        extra="ignore",
        case_sensitive=False,
    )

    environment: str = Field(default="development", alias="LIFEOS_ENV")
    timezone: str = Field(default="Africa/Casablanca", alias="LIFEOS_TIMEZONE")
    vault_path: Path = Field(default=Path("vault"), alias="LIFEOS_VAULT_PATH")
    api_base_url: str = Field(default="http://localhost:8000", alias="LIFEOS_API_BASE_URL")

    database_url: str | None = Field(default=None, alias="DATABASE_URL")
    redis_url: str | None = Field(default=None, alias="REDIS_URL")
    router_mode: str = Field(default="hybrid", alias="LIFEOS_ROUTER_MODE")

    discord_bot_token: str | None = Field(default=None, alias="DISCORD_BOT_TOKEN")
    discord_owner_user_id: str | None = Field(default=None, alias="DISCORD_OWNER_USER_ID")
    discord_guild_id: str | None = Field(default=None, alias="DISCORD_GUILD_ID")
    discord_approval_channel_id: str | None = Field(default=None, alias="DISCORD_APPROVAL_CHANNEL_ID")

    telegram_bot_token: str | None = Field(default=None, alias="TELEGRAM_BOT_TOKEN")
    telegram_owner_user_id: str | None = Field(default=None, alias="TELEGRAM_OWNER_USER_ID")

    openrouter_api_key_1: str | None = Field(default=None, alias="OPENROUTER_API_KEY_1")
    openrouter_api_key_2: str | None = Field(default=None, alias="OPENROUTER_API_KEY_2")
    nvidia_nim_api_key_1: str | None = Field(default=None, alias="NVIDIA_NIM_API_KEY_1")
    nvidia_nim_api_key_2: str | None = Field(default=None, alias="NVIDIA_NIM_API_KEY_2")

    cors_origins_raw: str = Field(
        default="http://localhost:5173,http://127.0.0.1:5173",
        alias="LIFEOS_CORS_ORIGINS",
    )

    @computed_field
    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins_raw.split(",") if origin.strip()]

    @computed_field
    @property
    def vault_exists(self) -> bool:
        return self.vault_path.exists()

    @computed_field
    @property
    def provider_key_counts(self) -> dict[str, int]:
        return {
            "openrouter": sum(bool(key) for key in [self.openrouter_api_key_1, self.openrouter_api_key_2]),
            "nvidia_nim": sum(bool(key) for key in [self.nvidia_nim_api_key_1, self.nvidia_nim_api_key_2]),
        }


@lru_cache
def get_settings() -> Settings:
    return Settings()
