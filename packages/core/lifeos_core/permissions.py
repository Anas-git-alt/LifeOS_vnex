"""Tool permission vocabulary."""

from lifeos_core.compat import StrEnum


class PermissionEffect(StrEnum):
    allow = "allow"
    ask = "ask"
    deny = "deny"
    dry_run = "dry_run"
    read_only = "read_only"
    scoped = "scoped"


class ToolMode(StrEnum):
    read_only = "read_only"
    dry_run = "dry_run"
    write = "write"
    external_side_effect = "external_side_effect"
