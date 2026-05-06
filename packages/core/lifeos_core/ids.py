"""Identifier helpers."""

from uuid import uuid4


def new_id(prefix: str) -> str:
    """Create a compact, sortable-enough application id.

    UUIDv4 is sufficient for Phase 0. The prefix keeps logs and review cards
    readable until we switch to ULIDs/UUIDv7.
    """

    normalized = prefix.strip().lower().replace("_", "-")
    return f"{normalized}_{uuid4().hex}"
