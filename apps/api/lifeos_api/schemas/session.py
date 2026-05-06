"""Agent session and chat API contracts."""

from typing import Any

from pydantic import BaseModel, Field


class SessionCreate(BaseModel):
    agent_id: str = "orchestrator"
    title: str | None = None
    iteration_cap: int | None = Field(default=None, ge=1, le=50)
    visibility: str = "private"
    source_platform: str | None = None
    external_channel_id: str | None = None
    external_thread_id: str | None = None
    external_message_id: str | None = None
    user_id: str | None = None
    memory_scope: dict[str, Any] = Field(default_factory=dict)
    metadata: dict[str, Any] = Field(default_factory=dict)


class SessionResolve(BaseModel):
    source_platform: str
    external_channel_id: str | None = None
    external_thread_id: str | None = None
    create_if_missing: bool = True
    agent_id: str = "orchestrator"
    title: str | None = None
    iteration_cap: int | None = Field(default=None, ge=1, le=50)
    visibility: str = "private"
    user_id: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)


class SessionMessageCreate(BaseModel):
    message: str
    source_platform: str = "web"
    external_channel_id: str | None = None
    external_thread_id: str | None = None
    external_message_id: str | None = None
    user_id: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)


class SessionAgentPatch(BaseModel):
    agent_id: str


class SessionIterationPatch(BaseModel):
    iteration_cap: int = Field(ge=1, le=50)


class ChatCreate(SessionMessageCreate):
    agent_id: str | None = None
    title: str | None = None
    iteration_cap: int | None = Field(default=None, ge=1, le=50)
    visibility: str = "private"
