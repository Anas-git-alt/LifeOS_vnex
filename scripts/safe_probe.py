#!/usr/bin/env python3
"""Read-only LifeOS probe.

This script uses GET requests and log reads only. It does not create captures,
reviews, audit events, vault files, Discord messages, or Telegram messages.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

import yaml


ROOT = Path(__file__).resolve().parents[1]


@dataclass
class Check:
    name: str
    ok: bool
    detail: str
    warn: bool = False


def read_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def env_value(name: str, file_values: dict[str, str]) -> str:
    return os.getenv(name) or file_values.get(name, "")


def get_json(url: str, headers: dict[str, str] | None = None, timeout: int = 10) -> tuple[int, Any]:
    request = Request(url, headers=headers or {}, method="GET")
    with urlopen(request, timeout=timeout) as response:  # noqa: S310
        body = response.read().decode("utf-8")
        return response.status, json.loads(body) if body else None


def get_text(url: str, timeout: int = 10) -> tuple[int, str]:
    with urlopen(url, timeout=timeout) as response:  # noqa: S310
        return response.status, response.read().decode("utf-8", errors="replace")


def http_json_check(name: str, url: str, expect: int = 200) -> Check:
    try:
        status, payload = get_json(url)
    except HTTPError as exc:
        return Check(name, False, f"HTTP {exc.code}")
    except (OSError, URLError, TimeoutError, json.JSONDecodeError) as exc:
        return Check(name, False, str(exc))
    return Check(name, status == expect, f"HTTP {status} {short_payload(payload)}")


def http_text_check(name: str, url: str, contains: str | None = None) -> Check:
    try:
        status, text = get_text(url)
    except HTTPError as exc:
        return Check(name, False, f"HTTP {exc.code}")
    except (OSError, URLError, TimeoutError) as exc:
        return Check(name, False, str(exc))
    ok = status == 200 and (contains is None or contains in text)
    detail = f"HTTP {status}"
    if contains is not None:
        detail += f" contains={contains in text}"
    return Check(name, ok, detail)


def short_payload(payload: Any) -> str:
    if isinstance(payload, dict):
        parts = []
        for key in ["status", "service", "count"]:
            if key in payload:
                parts.append(f"{key}={payload[key]}")
        if "items" in payload and isinstance(payload["items"], list):
            parts.append(f"items={len(payload['items'])}")
        return " ".join(parts) or "json"
    return type(payload).__name__


def run_compose(args: list[str]) -> tuple[int, str]:
    result = subprocess.run(  # noqa: S603 - fixed command with caller-provided args
        ["docker", "compose", *args],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
        timeout=20,
    )
    return result.returncode, (result.stdout + result.stderr).strip()


def docker_checks() -> list[Check]:
    checks: list[Check] = []
    code, output = run_compose(["ps"])
    checks.append(Check("docker.compose.ps", code == 0, first_line(output) or "ok"))
    gateway_api_ok = False

    code, output = run_compose(
        [
            "exec",
            "-T",
            "discord-gateway",
            "python",
            "-c",
            (
                "from urllib.request import urlopen;"
                "urlopen('http://api:8000/api/health', timeout=5).read();"
                "print('ok')"
            ),
        ]
    )
    gateway_api_ok = code == 0 and "ok" in output
    checks.append(
        Check(
            "docker.discord_gateway.api_reachable",
            gateway_api_ok,
            "http://api:8000 reachable" if gateway_api_ok else first_line(output),
        )
    )

    for service in ["api", "web", "discord-gateway"]:
        code, output = run_compose(["logs", "--tail=80", service])
        if code != 0:
            checks.append(Check(f"docker.logs.{service}", False, first_line(output)))
            continue
        lower = output.lower()
        bad = "connection refused" in lower or "traceback" in lower
        if service == "discord-gateway" and bad and gateway_api_ok:
            checks.append(
                Check(
                    f"docker.logs.{service}",
                    True,
                    "startup race log seen; API reachable now",
                )
            )
            continue
        checks.append(
            Check(
                f"docker.logs.{service}",
                not bad,
                "connection refused/traceback seen" if bad else "no obvious fatal log",
                warn=bad,
            )
        )
        if service == "discord-gateway":
            ready = "websocket ready" in lower
            checks.append(
                Check(
                    "docker.discord_gateway.websocket_ready",
                    ready,
                    "ready log seen" if ready else "missing websocket ready log",
                    warn=not ready,
                )
            )
    return checks


def first_line(text: str) -> str:
    for line in text.splitlines():
        if line.strip():
            return line.strip()[:160]
    return ""


def discord_read_only_checks(file_values: dict[str, str]) -> list[Check]:
    token = env_value("DISCORD_BOT_TOKEN", file_values)
    owner_id = env_value("DISCORD_OWNER_USER_ID", file_values)
    channel_id = env_value("DISCORD_APPROVAL_CHANNEL_ID", file_values)
    checks = [
        Check("discord.config.token", bool(token), "set" if token else "missing", warn=not token),
        Check("discord.config.owner", bool(owner_id), "set" if owner_id else "missing", warn=not owner_id),
        Check("discord.config.channel", bool(channel_id), "set" if channel_id else "missing", warn=not channel_id),
    ]
    if not token:
        return checks

    headers = {
        "Authorization": f"Bot {token}",
        "User-Agent": "LifeOS-vNext read-only probe",
    }
    checks.append(discord_api_check("discord.auth.me", "https://discord.com/api/v10/users/@me", headers))
    if channel_id:
        checks.append(
            discord_api_check(
                "discord.channel.read",
                f"https://discord.com/api/v10/channels/{channel_id}",
                headers,
            )
        )
    return checks


def discord_structure_checks(file_values: dict[str, str]) -> list[Check]:
    token = env_value("DISCORD_BOT_TOKEN", file_values)
    guild_id = env_value("DISCORD_GUILD_ID", file_values)
    if not token or not guild_id:
        return [
            Check(
                "discord.structure.config",
                False,
                "missing DISCORD_BOT_TOKEN or DISCORD_GUILD_ID",
                warn=True,
            )
        ]

    headers = {
        "Authorization": f"Bot {token}",
        "User-Agent": "LifeOS-vNext read-only probe",
    }
    try:
        status, payload = get_json(f"https://discord.com/api/v10/guilds/{guild_id}/channels", headers, timeout=15)
    except HTTPError as exc:
        return [Check("discord.structure.read", False, f"HTTP {exc.code}")]
    except (OSError, URLError, TimeoutError, json.JSONDecodeError) as exc:
        return [Check("discord.structure.read", False, str(exc))]
    if status != 200 or not isinstance(payload, list):
        return [Check("discord.structure.read", False, f"HTTP {status}")]

    existing = {str(item.get("name")) for item in payload if isinstance(item, dict)}
    config = yaml.safe_load((ROOT / "configs" / "discord.yaml").read_text(encoding="utf-8"))
    categories = [str(item["name"]) for item in config.get("categories", {}).values()]
    channels = [str(item["name"]) for item in config.get("channels", {}).values()]
    checks = [Check("discord.structure.read", True, f"channels={len(existing)}")]
    missing_categories = [name for name in categories if name not in existing]
    missing_channels = [name for name in channels if name not in existing]
    checks.append(
        Check(
            "discord.structure.categories",
            not missing_categories,
            "all present" if not missing_categories else f"missing={', '.join(missing_categories)}",
            warn=bool(missing_categories),
        )
    )
    checks.append(
        Check(
            "discord.structure.channels",
            not missing_channels,
            "all present" if not missing_channels else f"missing={', '.join(missing_channels)}",
            warn=bool(missing_channels),
        )
    )
    return checks


def discord_api_check(name: str, url: str, headers: dict[str, str]) -> Check:
    try:
        status, payload = get_json(url, headers=headers, timeout=15)
    except HTTPError as exc:
        return Check(name, False, f"HTTP {exc.code}")
    except (OSError, URLError, TimeoutError, json.JSONDecodeError) as exc:
        return Check(name, False, str(exc))
    detail = f"HTTP {status}"
    if isinstance(payload, dict) and payload.get("id"):
        detail += " id=present"
    return Check(name, status == 200, detail)


def print_checks(checks: list[Check]) -> int:
    failures = 0
    for check in checks:
        if check.ok:
            status = "OK"
        elif check.warn:
            status = "WARN"
        else:
            status = "FAIL"
            failures += 1
        print(f"{status:4} {check.name}: {check.detail}")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--api-url", default=os.getenv("LIFEOS_PROBE_API_URL", "http://localhost:8000"))
    parser.add_argument("--web-url", default=os.getenv("LIFEOS_PROBE_WEB_URL", "http://localhost:5173"))
    parser.add_argument("--skip-docker", action="store_true", help="Do not read Docker Compose status/logs.")
    parser.add_argument(
        "--discord-read-only",
        action="store_true",
        help="Check Discord token and channel using GET requests only. Sends no messages.",
    )
    parser.add_argument(
        "--discord-structure",
        action="store_true",
        help="Read-only check for configured LifeOS Discord categories/channels.",
    )
    args = parser.parse_args()

    api_url = args.api_url.rstrip("/")
    web_url = args.web_url.rstrip("/")
    file_values = read_env_file(ROOT / ".env")

    print("Mode: read-only. No captures, reviews, audit events, vault files, or Discord messages created.")

    checks = [
        http_json_check("api.health", f"{api_url}/api/health"),
        http_json_check("api.readiness", f"{api_url}/api/readiness"),
        http_json_check("api.today", f"{api_url}/api/today"),
        http_json_check("api.reviews.read", f"{api_url}/api/reviews?limit=1"),
        http_json_check("api.captures.read", f"{api_url}/api/captures?limit=1"),
        http_json_check("api.providers.read", f"{api_url}/api/providers"),
        http_text_check("web.index", f"{web_url}/", contains='id="root"'),
        http_json_check("web.proxy.api_health", f"{web_url}/api/health"),
    ]
    if not args.skip_docker:
        checks.extend(docker_checks())
    if args.discord_read_only:
        checks.extend(discord_read_only_checks(file_values))
    if args.discord_structure:
        checks.extend(discord_structure_checks(file_values))

    failures = print_checks(checks)
    if failures:
        print(f"Result: {failures} hard failure(s).")
        return 1
    print("Result: no hard failures.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
