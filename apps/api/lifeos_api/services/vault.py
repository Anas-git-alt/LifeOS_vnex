"""Vault writer and index helpers."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from lifeos_api.config import Settings
from lifeos_core.time import local_now, utc_now


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


class VaultWriter:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.root = settings.vault_path

    def _write(self, rel_path: str, content: str, *, append: bool = False) -> str:
        path = self.root / rel_path
        path.parent.mkdir(parents=True, exist_ok=True)
        if append:
            with path.open("a", encoding="utf-8") as handle:
                handle.write(content)
        else:
            path.write_text(content, encoding="utf-8")
        return rel_path

    def write_raw_capture(
        self,
        *,
        capture_id: str,
        platform: str,
        kind: str,
        text: str | None,
        metadata: dict[str, Any],
    ) -> tuple[str, str]:
        now = local_now(self.settings.timezone)
        rel_path = (
            f"raw/{platform}/{now:%Y}/{now:%m}/{now:%d}/"
            f"{platform[:2]}_{capture_id}.md"
        )
        body = text or ""
        content = "\n".join(
            [
                "---",
                f"id: {capture_id}",
                f"platform: {platform}",
                f"kind: {kind}",
                f"captured_at: {utc_now().isoformat()}",
                f"metadata: {json.dumps(metadata, sort_keys=True)}",
                "---",
                "",
                body,
                "",
            ]
        )
        uri = self._write(rel_path, content)
        digest = sha256_text(content)
        self.append_manifest("manifests/hashes.jsonl", {"uri": uri, "sha256": digest})
        self.append_manifest(
            "manifests/sources.csv",
            {
                "source_uri": uri,
                "content_hash": digest,
                "kind": kind,
                "sensitivity": metadata.get("sensitivity", "normal"),
                "created_at": utc_now().isoformat(),
            },
        )
        return uri, digest

    def write_memory_fact(self, *, fact_id: str, domain: str, statement_md: str) -> str:
        rel_path = f"memory/curated/domains/{domain}.md"
        content = f"\n\n## {fact_id}\n\n{statement_md}\n"
        return self._write(rel_path, content, append=True)

    def write_report(self, *, section: str, name: str, body_md: str) -> str:
        rel_path = f"reports/{section}/{name}.md"
        return self._write(rel_path, body_md)

    def write_state_snapshot(self, *, name: str, body_md: str) -> str:
        return self._write(f"state/{name}.md", body_md)

    def write_dead_letter(self, *, item_id: str, payload: dict[str, Any]) -> str:
        rel_path = f"system/dead-letter/{item_id}.json"
        return self._write(rel_path, json.dumps(payload, indent=2, sort_keys=True))

    def append_manifest(self, rel_path: str, payload: dict[str, Any]) -> None:
        if rel_path.endswith(".csv"):
            line = ",".join(str(payload.get(key, "")) for key in payload.keys()) + "\n"
        else:
            line = json.dumps(payload, sort_keys=True) + "\n"
        self._write(rel_path, line, append=True)
