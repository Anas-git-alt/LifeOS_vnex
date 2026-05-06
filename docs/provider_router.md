# Provider Router

Provider routing is per-agent. OpenRouter and NVIDIA NIM are normal OpenAI-compatible model providers. Codex OAuth is treated first as a coding/tool adapter for Systems/DevOps workflows.

Routing sequence:

1. Load agent model config.
2. Try primary provider and first active key.
3. On auth failure, mark key failed and try next key.
4. On rate limit, cooldown key and try next key.
5. On timeout/5xx, retry once when safe.
6. Try model fallback, then secondary provider when allowed.
7. Record provider call log and status events.
