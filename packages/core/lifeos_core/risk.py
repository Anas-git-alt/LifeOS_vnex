"""Tool and state mutation risk levels."""

from enum import IntEnum, StrEnum


class RiskLevel(IntEnum):
    safe_internal_read = 0
    sensitive_internal_read = 1
    external_read = 2
    reversible_internal_write = 3
    durable_state_mutation = 4
    file_write_or_move = 5
    external_side_effect = 6
    destructive_or_sensitive_action = 7


class Sensitivity(StrEnum):
    normal = "normal"
    personal = "personal"
    finance = "finance"
    health = "health"
    family = "family"
    secret = "secret"
