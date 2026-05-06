#!/usr/bin/env python3
"""Minimal smoke checks for a running LifeOS API."""

from __future__ import annotations

import json
import os
import sys
from urllib.request import Request, urlopen


def get_json(url: str) -> dict[str, object]:
    with urlopen(url, timeout=10) as response:  # noqa: S310
        return json.loads(response.read().decode("utf-8"))


def post_json(url: str, payload: dict[str, object]) -> dict[str, object]:
    request = Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urlopen(request, timeout=20) as response:  # noqa: S310
        return json.loads(response.read().decode("utf-8"))


def patch_json(url: str, payload: dict[str, object]) -> dict[str, object]:
    request = Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="PATCH",
    )
    with urlopen(request, timeout=20) as response:  # noqa: S310
        return json.loads(response.read().decode("utf-8"))


def main() -> int:
    base_url = os.getenv("LIFEOS_API_BASE_URL", "http://localhost:8000")
    payload = get_json(f"{base_url}/api/health")
    if payload != {"service": "lifeos-api", "status": "ok"}:
        print(f"unexpected health payload: {payload}")
        return 1

    settings = get_json(f"{base_url}/api/settings")
    router_mode = "hybrid"
    for item in settings.get("items", []):
        if isinstance(item, dict) and item.get("key") == "router.mode":
            value_json = item.get("value_json")
            if isinstance(value_json, dict):
                router_mode = str(value_json.get("value") or router_mode)
    patch_json(f"{base_url}/api/settings", {"values": {"router.mode": "deterministic"}})

    capture = post_json(
        f"{base_url}/api/captures",
        {
            "source_platform": "web",
            "capture_kind": "text",
            "raw_text": "random thought: smoke test raw note",
            "metadata": {"owner_authenticated": True},
        },
    )
    route = capture.get("route", {})
    if not isinstance(route, dict) or route.get("decision") not in {
        "raw_only",
        "auto_apply",
        "review_required",
        "ask_clarification",
    }:
        print(f"unexpected capture route: {capture}")
        return 1

    review_capture = post_json(
        f"{base_url}/api/captures",
        {
            "source_platform": "web",
            "capture_kind": "text",
            "raw_text": "I spent 40 MAD on lunch",
            "metadata": {"owner_authenticated": True},
        },
    )
    review_id = review_capture.get("review_item_id")
    if not review_id:
        print(f"expected finance review: {review_capture}")
        return 1

    decision = post_json(
        f"{base_url}/api/reviews/{review_id}/decision",
        {
            "decision": "reject",
            "source_platform": "api",
            "decision_payload": {},
        },
    )
    if not decision.get("ok"):
        print(f"review decision failed: {decision}")
        return 1

    providers = get_json(f"{base_url}/api/providers")
    if "items" not in providers:
        print(f"providers endpoint failed: {providers}")
        return 1

    chat = post_json(
        f"{base_url}/api/chat",
        {
            "source_platform": "web",
            "external_channel_id": "smoke-test",
            "message": "smoke test note: keep this as a low-risk LifeOS note",
            "iteration_cap": 3,
            "metadata": {"owner_authenticated": True, "smoke_test": True},
        },
    )
    if not chat.get("ok") or chat.get("status") not in {"completed", "waiting_approval"}:
        print(f"chat endpoint failed: {chat}")
        return 1

    sessions = get_json(f"{base_url}/api/sessions?limit=5")
    if "items" not in sessions:
        print(f"sessions endpoint failed: {sessions}")
        return 1

    patch_json(f"{base_url}/api/settings", {"values": {"router.mode": router_mode}})

    print("smoke test ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
