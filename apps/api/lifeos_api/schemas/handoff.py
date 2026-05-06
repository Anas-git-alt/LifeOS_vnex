"""Handoff request schemas."""

from typing import Any

from pydantic import BaseModel, Field


class HandoffCreate(BaseModel):
    parent_run_id: str | None = None
    from_agent_id: str
    to_agent_id: str
    reason: str
    task_md: str
    known_context: list[dict[str, Any]] = Field(default_factory=list)
    context_refs: list[dict[str, Any]] = Field(default_factory=list)
    constraints: list[dict[str, Any]] = Field(default_factory=list)
    expected_output_schema: dict[str, Any] | None = None
    risk_level: str = "normal"
    visibility: str = "discord_compact"
    requires_user_visibility: bool = True
