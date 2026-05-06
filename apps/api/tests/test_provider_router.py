import json
from urllib.error import URLError

from lifeos_providers import router as provider_router
from lifeos_providers.router import ProviderRouter


class FakeResponse:
    def __init__(self, payload: dict[str, object]) -> None:
        self.payload = payload

    def __enter__(self) -> "FakeResponse":
        return self

    def __exit__(self, *args: object) -> None:
        return None

    def read(self) -> bytes:
        return json.dumps(self.payload).encode("utf-8")


def test_provider_router_tries_backup_key(monkeypatch) -> None:
    monkeypatch.setenv("PRIMARY_KEY", "bad")
    monkeypatch.setenv("BACKUP_KEY", "good")
    calls: list[str] = []

    def fake_urlopen(request, timeout):  # type: ignore[no-untyped-def]
        auth = request.get_header("Authorization")
        calls.append(str(auth))
        if auth == "Bearer bad":
            raise URLError("primary failed")
        return FakeResponse({"choices": [{"message": {"content": "{\"ok\": true}"}}], "usage": {}})

    monkeypatch.setattr(provider_router, "urlopen", fake_urlopen)

    completion = ProviderRouter(
        config={
            "providers": {
                "openrouter": {
                    "type": "openai_compatible",
                    "base_url": "https://example.invalid/v1",
                    "auth": {
                        "keys": [
                            {"env": "PRIMARY_KEY", "label": "primary", "priority": 10},
                            {"env": "BACKUP_KEY", "label": "backup", "priority": 20},
                        ]
                    },
                }
            },
            "agent_models": {
                "orchestrator": {
                    "primary": {"provider": "openrouter", "model": "model-a"},
                    "fallback_allowed": True,
                }
            },
        }
    ).complete_json("orchestrator", [{"role": "user", "content": "{}"}])

    assert completion.key_label == "backup"
    assert calls == ["Bearer bad", "Bearer good"]
