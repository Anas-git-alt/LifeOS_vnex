"""Job request schemas."""

from typing import Any

from pydantic import BaseModel, Field


class JobCreate(BaseModel):
    name: str
    description_md: str | None = None
    schedule_type: str
    schedule_json: dict[str, Any] = Field(default_factory=dict)
    timezone: str = "Africa/Casablanca"
    target_agent_id: str | None = None
    command_json: dict[str, Any] = Field(default_factory=dict)
    approval_policy: str = "ask_for_mutations"
    enabled: bool = True
