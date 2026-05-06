# AGENTS.md

This repo builds LifeOS vNext, a Discord-first, review-gated personal agent swarm.

## Core Rules

- Do not treat raw captures as truth.
- Do not write durable memory from model output without policy review.
- Do not mutate operational state outside the command bus.
- Do not put business logic in Discord or Telegram gateways.
- Do not index sensitive raw finance, family, health, secrets, backups, or auth caches by default.
- Keep the Work Agent generic until approved context proves a real work domain.
- Every state mutation needs source evidence and an audit event.
- Every tool call needs a run id, agent id, input/output log, and risk classification.

## Local Development

Use Docker for the intended runtime:

```bash
cp .env.example .env
python3 scripts/doctor.py
docker compose up --build
```

Useful local checks:

```bash
python3 scripts/doctor.py
python3 -m compileall apps packages scripts
npm --prefix apps/web install
npm --prefix apps/web run build
```

## Architecture Boundaries

- `apps/api` owns command handling, validation, state mutation, audit, and API reads.
- `apps/discord-gateway` converts Discord events to API commands and renders API responses.
- `apps/telegram-gateway` captures raw evidence and forwards it to the API.
- `apps/worker` runs async jobs and agent/tool execution.
- `apps/web` gives visibility and configuration.
- `packages/core` contains dependency-light shared contracts.
- `vault/raw` is append-only.

When in doubt, prefer a pending review item over a silent state write.
