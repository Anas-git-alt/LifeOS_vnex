#!/usr/bin/env python3
"""Minimal smoke checks for a running LifeOS API."""

from __future__ import annotations

import json
import os
import sys
from urllib.request import urlopen


def main() -> int:
    base_url = os.getenv("LIFEOS_API_BASE_URL", "http://localhost:8000")
    with urlopen(f"{base_url}/api/health", timeout=10) as response:  # noqa: S310
        payload = json.loads(response.read().decode("utf-8"))
    if payload != {"service": "lifeos-api", "status": "ok"}:
        print(f"unexpected health payload: {payload}")
        return 1
    print("smoke test ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
