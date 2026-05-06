# LifeOS vNext

Codename: **Hermos Swarm**.

LifeOS vNext is a Discord-first, escalation-gated personal operating system. It treats raw capture as evidence, agent output as contextual working state, and audited command-bus/service calls as the only path into durable operational truth.

```text
Capture anywhere
-> preserve raw evidence
-> classify and route
-> specialist agent drafts interpretation/action
-> policy decides autonomous action vs clarification/review
-> Discord surfaces the question/card/status
-> owner approves, rejects, corrects, snoozes, or follows up naturally
-> system mutates state only through audited commands
-> memory/wiki grows from evidence, corrections, repeated behavior, and approved/safe context
-> WebUI shows the whole trace
```

## Product Contract

The system is not one chatbot with tools. It is an escalation-gated personal agent swarm:

- **Telegram** is fast raw capture: text, links, voice, images, files, and messy thoughts.
- **Discord** is the primary interaction layer: review cards, approvals, corrections, status, trackers, and lightweight chat.
- **WebUI** is the command center: run traces, approvals, providers, tool permissions, audit, health, and debugging.
- **Vault/filesystem** is durable infrastructure: raw evidence, ledger, curated memory, wiki, reports, and artifacts.

The core invariant:

> Evidence before truth. Autonomy before interruption. Escalation before risky mutation. Correction before bureaucracy.

Agents may autonomously perform low-risk, reversible, permissioned actions and must report them afterward. They must escalate before high-impact, ambiguous, sensitive, destructive, external, or hard-to-reverse actions.

## Current Runtime

This repository currently contains the executable vNext spine:

- Monorepo structure for API, worker, Discord gateway, Telegram gateway, WebUI, shared packages, configs, docs, and vault.
- FastAPI app with capture, review, run, handoff, tool, provider, memory, job, audit, event, and Today APIs.
- Hybrid capture router that uses configured AI providers first and deterministic routing as fallback.
- Policy engine with `manual`, `review_gated`, `balanced`, and `safe` autonomy modes, where `balanced` supports low-risk autonomous actions.
- Agent sessions with Discord channel/thread bindings, active agent selection, iteration caps, cancellation, message history, correction refs, and structured run results.
- Bounded agent runtime for session chat, handoffs, low-risk autonomous actions, clarification/review escalation, and correction-driven preference candidates.
- Approval Manager flow through `/api/reviews/{id}/decision` with audited command-bus state mutation.
- Discord slash commands, `/lifeos new`, `/lifeos thread`, `/lifeos agent`, `/lifeos iterations`, `/lifeos cancel`, normal message-to-session chat, legacy `!` fallbacks, review buttons, and correction/clarification modals.
- Telegram quick capture with quieter replies: raw-only notes no longer create review spam.
- WebUI command center for captures, review decisions, agents, provider/model config, tool permissions, runs, audit, and health.
- Vault writer for raw evidence, manifests, memory facts, dead-letter payloads, reports, and state snapshots.
- YAML bootstrap config plus DB-backed runtime overrides for agents, models, providers, tools, and settings.
- Doctor and smoke scripts for validating the repo shape, config syntax, and running API.
- Docker Compose for API, WebUI, worker, Postgres, and Redis.
- Architecture docs and ADRs for the non-negotiable design choices.

## Quick Start

```bash
cp .env.example .env
python3 scripts/doctor.py
docker compose up --build
```

Expected local services:

- API: `http://localhost:8000/api/health`
- WebUI: `http://localhost:5173`
- Postgres: `localhost:5432`
- Redis: `localhost:6379`

Read-only, no-pollution probe:

```bash
python3 scripts/safe_probe.py --discord-read-only
```

This uses GET requests and Docker log reads only. It creates no captures, reviews, audit rows, vault files, Discord messages, or Telegram messages.

The Discord and Telegram gateways are thin adapters. They validate configuration and are intentionally kept free of business logic; all state changes flow through the API command bus.

Gateway profiles can be started when tokens/channel ids are configured:

```bash
docker compose --profile gateways up -d
```

Register Discord commands without starting the gateway:

```bash
python3 scripts/setup_discord_commands.py --dry-run
python3 scripts/setup_discord_commands.py
```

Day-to-day surfaces:

- Discord: `/lifeos new`, `/lifeos thread`, `/lifeos agent`, `/lifeos iterations`, `/lifeos cancel`, `/lifeos capture`, `/lifeos ask`, `/lifeos today`, `/lifeos reviews`, `/lifeos status`, `/lifeos agents`, `/lifeos providers`.
- Discord review cards: Approve, Reject, Correct, Clarify, Snooze, Done buttons.
- Telegram: `/capture`, `/ask`, `/today`, `/status`, plus normal quick captures.
- WebUI: `http://localhost:5173` for capture, review, agents/models/providers/tools/runs.

## API Spine

Key endpoints:

```text
POST /api/captures
POST /api/chat
GET  /api/sessions
POST /api/sessions
POST /api/sessions/resolve
POST /api/sessions/{id}/messages
PATCH /api/sessions/{id}/agent
PATCH /api/sessions/{id}/iterations
POST /api/sessions/{id}/cancel
POST /api/ask
GET  /api/today
GET  /api/reviews
POST /api/reviews/{id}/decision
GET  /api/runs
GET  /api/runs/{id}
GET  /api/handoffs
GET  /api/tools
POST /api/tools/calls
GET  /api/providers
POST /api/providers/{provider_id}/test
GET  /api/agents
PATCH /api/agents/{agent_id}
PATCH /api/agents/{agent_id}/model
GET  /api/tools/permissions
PUT  /api/tools/permissions
GET  /api/settings
PATCH /api/settings
GET  /api/memory/candidates
POST /api/memory/candidates
GET  /api/jobs
POST /api/jobs
GET  /api/audit
GET  /api/events
GET  /api/events/stream
```

## Build Order

1. DB + command bus + audit events.
2. Discord review cards.
3. Telegram raw capture.
4. Capture Router.
5. Approval Manager.
6. Generic Work + Finance review flows.
7. Provider router with OpenRouter/NVIDIA NIM fallback.
8. WebUI run/review/audit visibility.
9. Memory Curator + vault.
10. Tool gateway + Systems/DevOps.
11. Handoff graph and swarm board.
12. More domain agents and automations.

## Repository Map

```text
apps/
  api/                FastAPI command core.
  discord-gateway/    Thin Discord platform gateway.
  telegram-gateway/   Thin Telegram raw-capture gateway.
  worker/             Async job runner.
  web/                React command center.

packages/
  core/               Shared IDs, time, events, risks, permissions.
  agents/             Agent registry and specialist implementations.
  tools/              Tool registry and sandbox contracts.
  providers/          Provider router and model adapters.
  protocols/          JSON schemas for handoffs/reviews/tool calls.

configs/              YAML runtime configuration.
vault/                Durable evidence, memory, wiki, reports, artifacts.
docs/                 Architecture docs and ADRs.
scripts/              Doctor, setup, backup/restore, smoke scripts.
```

## Implementation Invariants

1. Raw captures are immutable.
2. AI drafts are not durable truth.
3. Important state mutations go through controlled services/command bus.
4. Discord is the main review surface.
5. Telegram is raw capture first, not the main review UI.
6. WebUI is visibility/configuration, not required daily operation.
7. Every tool call is logged.
8. Every state mutation is audited.
9. Every handoff is traceable.
10. Every memory fact has evidence.
11. Sensitive raw data is not indexed by default.
12. Work Agent starts generic.
13. Provider/model config is per-agent and editable.
14. Key fallback and provider fallback are built into the router.
15. Failures surface clearly instead of disappearing.
16. Low-risk, reversible, permissioned actions may complete autonomously and report afterward.
17. Corrections link to prior runs/actions and may create low-risk preference candidates.

## Guides

- [User guide](docs/user_guide.md) - startup, health checks, safe end-to-end tests, and troubleshooting.
- [Discord channel structure](docs/discord_channel_structure.md) - ideal server layout, setup script, and manual Discord tests.
- [WebUI usage](docs/webui_usage.md) - captures, reviews, agent/model config, provider tests, tool permissions, run detail.
- [Provider router](docs/provider_router.md) - hybrid AI routing and fallback behavior.
- [Approval policy](docs/approval_policy.md) - autonomy modes and what still needs review.
