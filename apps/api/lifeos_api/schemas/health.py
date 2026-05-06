"""Schemas for health/readiness endpoints."""

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    service: str
    status: str


class ReadinessStatus(BaseModel):
    name: str
    ok: bool
    detail: str | None = None


class ReadinessResponse(BaseModel):
    service: str
    status: str
    environment: str
    timezone: str
    checks: list[ReadinessStatus] = Field(default_factory=list)
    provider_key_counts: dict[str, int] = Field(default_factory=dict)
