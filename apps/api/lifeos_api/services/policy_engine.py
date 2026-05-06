"""Policy helpers for review and tool decisions."""

from typing import Any


ALWAYS_REVIEW_RISKS = {
    "durable_state_mutation",
    "finance_mutation",
    "durable_memory_write",
    "file_write_or_move",
    "external_side_effect",
    "destructive_or_sensitive_action",
}

SENSITIVE_DOMAINS = {"finance", "health", "family", "secret"}


def review_required(action: dict[str, Any], *, confidence: float, sensitivity: str) -> bool:
    risk = str(action.get("risk_level") or action.get("risk") or "")
    command_type = str(action.get("command_type") or "")
    if risk in ALWAYS_REVIEW_RISKS:
        return True
    if sensitivity in SENSITIVE_DOMAINS:
        return True
    if command_type and command_type != "none":
        return True
    return confidence < 0.9


def tool_effect(agent_id: str, tool_id: str, config: dict[str, Any]) -> str:
    permissions = config.get("agent_permissions", {})
    agent_permissions = permissions.get(agent_id, {})
    payload = agent_permissions.get(tool_id)
    if isinstance(payload, dict):
        return str(payload.get("effect", "deny"))
    default = config.get("global_tool_policy", {}).get("default_effect", "deny")
    return str(default)
