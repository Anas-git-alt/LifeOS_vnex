"""OpenAI-compatible provider routing with safe fallbacks."""

from __future__ import annotations

import json
import os
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

import yaml


@dataclass(frozen=True)
class ProviderChoice:
    provider: str
    model: str
    fallback_allowed: bool
    raw: dict[str, Any]
    key_label: str | None = None
    api_key: str | None = None
    base_url: str | None = None
    provider_type: str | None = None


@dataclass(frozen=True)
class ProviderCompletion:
    content: str
    provider: str
    model: str
    key_label: str | None
    latency_ms: int
    input_tokens: int | None = None
    output_tokens: int | None = None


class ProviderRouter:
    def __init__(
        self,
        config_path: Path | str = "configs/providers.yaml",
        *,
        config: dict[str, Any] | None = None,
    ) -> None:
        self.config_path = Path(config_path)
        self.config = config or yaml.safe_load(self.config_path.read_text(encoding="utf-8")) or {}

    def choose_for_agent(self, agent_id: str) -> ProviderChoice:
        choices = self._choices_for_agent(agent_id)
        if not choices:
            raise KeyError(f"No provider config for agent {agent_id!r}")
        return choices[0]

    def complete_json(self, agent_id: str, messages: list[dict[str, str]]) -> ProviderCompletion:
        errors: list[str] = []
        for choice in self._choices_for_agent(agent_id):
            if choice.provider_type != "openai_compatible":
                errors.append(f"{choice.provider}: not OpenAI-compatible")
                continue
            if not choice.api_key:
                errors.append(f"{choice.provider}: no configured API key")
                continue
            if not choice.base_url:
                errors.append(f"{choice.provider}: no base_url")
                continue

            started = time.monotonic()
            payload = {
                "model": choice.model,
                "messages": messages,
                "temperature": 0,
                "response_format": {"type": "json_object"},
            }
            request = Request(
                f"{choice.base_url.rstrip('/')}/chat/completions",
                data=json.dumps(payload).encode("utf-8"),
                headers={
                    "Authorization": f"Bearer {choice.api_key}",
                    "Content-Type": "application/json",
                    "HTTP-Referer": "https://lifeos.local",
                    "X-Title": "LifeOS vNext",
                },
                method="POST",
            )
            try:
                with urlopen(request, timeout=90) as response:  # noqa: S310
                    body = json.loads(response.read().decode("utf-8"))
            except HTTPError as exc:
                detail = exc.read().decode("utf-8", errors="replace")
                errors.append(f"{choice.provider}/{choice.model}/{choice.key_label}: HTTP {exc.code}: {detail[:300]}")
                continue
            except (OSError, URLError, TimeoutError, json.JSONDecodeError) as exc:
                errors.append(f"{choice.provider}/{choice.model}/{choice.key_label}: {exc}")
                continue

            content = str(body["choices"][0]["message"]["content"])
            usage = body.get("usage", {}) if isinstance(body, dict) else {}
            return ProviderCompletion(
                content=content,
                provider=choice.provider,
                model=choice.model,
                key_label=choice.key_label,
                latency_ms=int((time.monotonic() - started) * 1000),
                input_tokens=usage.get("prompt_tokens"),
                output_tokens=usage.get("completion_tokens"),
            )
        raise RuntimeError(f"No provider route succeeded for {agent_id}: {'; '.join(errors)[:1200]}")

    def _first_configured_key(self, provider: dict[str, Any]) -> tuple[str | None, str] | None:
        keys = self._configured_keys(provider)
        return keys[0] if keys else None

    def _choices_for_agent(self, agent_id: str) -> list[ProviderChoice]:
        agent_models = self.config.get("agent_models", {})
        if agent_id not in agent_models:
            raise KeyError(f"No provider config for agent {agent_id!r}")

        raw = agent_models[agent_id]
        fallback_allowed = bool(raw.get("fallback_allowed", True))
        model_refs = [raw["primary"]]
        if fallback_allowed and raw.get("secondary"):
            model_refs.append(raw["secondary"])

        choices: list[ProviderChoice] = []
        for model_ref in model_refs:
            provider_id = model_ref.get("provider")
            model = model_ref.get("model")
            if not provider_id or not model:
                continue
            provider = self.config.get("providers", {}).get(provider_id, {})
            if provider.get("enabled", True) is False:
                continue
            keys = self._configured_keys(provider) or [(None, None)]
            models = self._models_for_ref(model_ref, str(model))
            for candidate_model in models:
                for key_label, api_key in keys:
                    choices.append(
                        ProviderChoice(
                            provider=str(provider_id),
                            model=candidate_model,
                            fallback_allowed=fallback_allowed,
                            raw=raw,
                            key_label=key_label,
                            api_key=api_key,
                            base_url=provider.get("base_url"),
                            provider_type=provider.get("type"),
                        )
                    )
        return choices

    def _configured_keys(self, provider: dict[str, Any]) -> list[tuple[str | None, str]]:
        keys = sorted(
            provider.get("auth", {}).get("keys", []),
            key=lambda item: int(item.get("priority", 100)),
        )
        configured = []
        for key in keys:
            env = key.get("env")
            if not env:
                continue
            value = os.getenv(str(env))
            if value:
                configured.append((key.get("label"), value))
        return configured

    def _models_for_ref(self, model_ref: dict[str, Any], default_model: str) -> list[str]:
        models = model_ref.get("models")
        if isinstance(models, list) and models:
            return [str(model) for model in models]
        return [default_model]
