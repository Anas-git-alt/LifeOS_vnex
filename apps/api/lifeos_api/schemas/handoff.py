"""Handoff request schemas."""

from typing import Any

from pydantic import BaseModel, Field


class HandoffCreate(BaseModel):
    parent_run_id: str | None = None
    from_agent_id: str
    to_agent_id: str
    reason: str
    task_md: str
    context_refs: list[dict[str, Any]] = Field(default_factory=list)
    expected_output_schema: dict[str, Any] | None = None
    visibility: str = "web"
