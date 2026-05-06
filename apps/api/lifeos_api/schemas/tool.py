"""Tool request schemas."""

from typing import Any

from pydantic import BaseModel, Field


class ToolCallCreate(BaseModel):
    run_id: str | None = None
    agent_id: str
    tool_id: str
    input_json: dict[str, Any] = Field(default_factory=dict)


class ToolPermissionUpdate(BaseModel):
    agent_id: str
    tool_id: str
    effect: str
    mode: str = "read_only"
    scopes: dict[str, Any] = Field(default_factory=dict)
    requires_approval_when: dict[str, Any] = Field(default_factory=dict)
