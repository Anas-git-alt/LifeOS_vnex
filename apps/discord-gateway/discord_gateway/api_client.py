"""Small HTTP client for Discord gateway -> LifeOS API."""

from __future__ import annotations

import json
from dataclasses import dataclass
from urllib.request import Request, urlopen

API_TIMEOUT_SECONDS = 75


@dataclass(frozen=True)
class LifeOSApiClient:
    base_url: str

    def get(self, path: str) -> dict[str, object]:
        with urlopen(f"{self.base_url.rstrip('/')}{path}", timeout=45) as response:  # noqa: S310
            return json.loads(response.read().decode("utf-8"))

    def post(self, path: str, payload: dict[str, object] | None = None) -> dict[str, object]:
        request = Request(
            f"{self.base_url.rstrip('/')}{path}",
            data=json.dumps(payload or {}).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urlopen(request, timeout=API_TIMEOUT_SECONDS) as response:  # noqa: S310
            return json.loads(response.read().decode("utf-8"))

    def patch(self, path: str, payload: dict[str, object]) -> dict[str, object]:
        request = Request(
            f"{self.base_url.rstrip('/')}{path}",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="PATCH",
        )
        with urlopen(request, timeout=API_TIMEOUT_SECONDS) as response:  # noqa: S310
            return json.loads(response.read().decode("utf-8"))
