"""Common request/response contracts."""

from typing import Any

from pydantic import BaseModel, Field


class DecisionResponse(BaseModel):
    ok: bool
    status: str
    result: dict[str, Any] = Field(default_factory=dict)


class ListResponse(BaseModel):
    items: list[dict[str, Any]]
    count: int
