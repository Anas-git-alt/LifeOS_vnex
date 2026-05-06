"""Central autonomy and escalation policy decisions."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


AUTONOMY_MODES = {"manual", "review_gated", "balanced", "safe"}

ALWAYS_REVIEW_RISKS = {
    "finance_mutation",
    "durable_memory_write",
    "family_sensitive_mutation",
    "health_sensitive_mutation",
    "file_write_or_move",
    "external_side_effect",
    "destructive_or_sensitive_action",
    "provider_config_change",
    "tool_permission_change",
}

SENSITIVE_DOMAINS = {"finance", "health", "family", "secret"}

AUTO_ALLOW_BY_MODE = {
    "manual": set(),
    "review_gated": {"review.done", "raw_capture.archive"},
    "balanced": {
        "review.done",
        "raw_capture.archive",
        "life_item.create",
        "prayer_log.create",
        "daily_log.create",
        "memory_candidate.create",
    },
    "safe": {
        "review.done",
        "raw_capture.archive",
        "life_item.create",
        "prayer_log.create",
        "daily_log.create",
        "life_item.low_risk_log",
        "memory_candidate.create",
    },
}


@dataclass(frozen=True)
class PolicyDecision:
    decision: str
    reason: str
    risk_level: str
    confidence: float
    requires_user_visible_status: bool = True

    def as_dict(self) -> dict[str, Any]:
        return {
            "decision": self.decision,
            "reason": self.reason,
            "risk_level": self.risk_level,
            "confidence": self.confidence,
            "requires_user_visible_status": self.requires_user_visible_status,
        }


def decide_capture_action(
    *,
    action: dict[str, Any],
    confidence: float,
    sensitivity: str,
    autonomy_mode: str,
    owner_authenticated: bool,
    missing_context: list[dict[str, Any]] | None = None,
    intent_labels: list[str] | None = None,
) -> PolicyDecision:
    """Decide if draft action is raw-only, auto-applied, escalated, or blocked."""

    mode = autonomy_mode if autonomy_mode in AUTONOMY_MODES else "review_gated"
    risk = str(action.get("risk_level") or action.get("risk") or "unknown")
    command_type = str(action.get("command_type") or "none")
    labels = set(intent_labels or [])
    missing = missing_context or []

    if command_type == "none" or "raw_note" in labels:
        return PolicyDecision(
            decision="raw_only",
            reason="No clear action intent; raw evidence archived without memory promotion.",
            risk_level="safe_internal_read",
            confidence=confidence,
            requires_user_visible_status=False,
        )

    if not owner_authenticated:
        return PolicyDecision(
            decision="review_required",
            reason="Source not owner-authenticated.",
            risk_level=risk,
            confidence=confidence,
        )

    if missing:
        return PolicyDecision(
            decision="ask_clarification",
            reason="Draft has missing context.",
            risk_level=risk,
            confidence=confidence,
        )

    if confidence < 0.7:
        return PolicyDecision(
            decision="review_required",
            reason="Low-confidence interpretation.",
            risk_level=risk,
            confidence=confidence,
        )

    if mode == "manual":
        return PolicyDecision(
            decision="review_required",
            reason="Manual autonomy mode requires review.",
            risk_level=risk,
            confidence=confidence,
        )

    if risk in ALWAYS_REVIEW_RISKS:
        return PolicyDecision(
            decision="review_required",
            reason=f"{risk} always requires review.",
            risk_level=risk,
            confidence=confidence,
        )

    if sensitivity in SENSITIVE_DOMAINS:
        return PolicyDecision(
            decision="review_required",
            reason=f"{sensitivity} sensitivity requires review.",
            risk_level=risk,
            confidence=confidence,
        )

    if (
        command_type in AUTO_ALLOW_BY_MODE[mode]
        and confidence >= 0.78
        and risk in {"safe_internal_read", "reversible_internal_write", "durable_state_mutation"}
    ):
        return PolicyDecision(
            decision="auto_apply",
            reason=f"{command_type} is allowlisted for {mode} mode.",
            risk_level=risk,
            confidence=confidence,
        )

    return PolicyDecision(
        decision="review_required",
        reason=f"{command_type} is not allowlisted for {mode} mode.",
        risk_level=risk,
        confidence=confidence,
    )


def review_required(action: dict[str, Any], *, confidence: float, sensitivity: str) -> bool:
    return (
        decide_capture_action(
            action=action,
            confidence=confidence,
            sensitivity=sensitivity,
            autonomy_mode="manual",
            owner_authenticated=True,
        ).decision
        == "review_required"
    )


def tool_effect(agent_id: str, tool_id: str, config: dict[str, Any]) -> str:
    permissions = config.get("agent_permissions", {})
    agent_permissions = permissions.get(agent_id, {})
    payload = agent_permissions.get(tool_id)
    if isinstance(payload, dict):
        return str(payload.get("effect", "deny"))
    default = config.get("global_tool_policy", {}).get("default_effect", "deny")
    return str(default)
