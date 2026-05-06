# Provider Router

LifeOS uses `LIFEOS_ROUTER_MODE`:

- `deterministic`: use local keyword router only.
- `agentic`: require configured provider router.
- `hybrid`: try provider router, validate JSON, fall back deterministic. Default.

OpenRouter and NVIDIA NIM use OpenAI-compatible `/chat/completions`. Codex OAuth remains the Systems/DevOps coding adapter.

Capture routing emits:

- `provider.call_started`
- `provider.fallback_used` / `agentic_router.fallback_deterministic`
- `agentic_router.completed`
- `policy.decision`

Provider calls write `provider_call_logs` with provider id, model, key label, latency, token usage when supplied, status, and redacted errors.

Fallback order:

1. Primary provider/model.
2. Additional models declared under `primary.models`.
3. Additional configured keys by priority.
4. Secondary provider/model when `fallback_allowed` is true.

The router never returns raw keys in API responses, logs, Discord, or WebUI. When no provider route succeeds in `hybrid` mode, the agent runtime falls back to contextual local planning and emits a compact status event.

Runtime config:

- YAML in `configs/providers.yaml` seeds defaults.
- DB `provider_runtime_configs` and `agent_model_configs` override YAML.
- WebUI edits DB via `/api/agents/{agent_id}/model` and provider endpoints.
- API responses never include raw key values; only env var labels and configured status.

Structured router output:

```json
{
  "agent_id": "work.generic",
  "domain": "work",
  "intent_labels": ["task"],
  "confidence": 0.83,
  "sensitivity": "normal",
  "risk_level": "durable_state_mutation",
  "needs_review": true,
  "title": "Submit HR paper",
  "body_md": "...",
  "proposed_action": {"command_type": "life_item.create", "risk_level": "durable_state_mutation", "payload": {}},
  "missing_context": [],
  "user_facing_summary": "..."
}
```

Invalid JSON, missing keys, missing API keys, HTTP errors, or provider timeouts in hybrid mode degrade safely to deterministic routing.
