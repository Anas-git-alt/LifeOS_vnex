# LifeOS vNext User Guide

This guide helps you verify that LifeOS vNext is working as a Discord-first, escalation-gated personal agent swarm. It focuses on the local development stack and safe checks you can run without mutating anything important.

## What Working Well Looks Like

A healthy local LifeOS stack should have:

- API, WebUI, worker, Postgres, and Redis containers running.
- `/api/health` returning `ok`.
- `/api/readiness` returning `ready` or clear configuration warnings.
- WebUI loading at `http://localhost:5173`.
- A capture creating vault evidence, an agent run, status events, and a policy result.
- Random low-intent notes archived raw-only without review clutter.
- Low-risk reversible notes/tasks can complete autonomously and report afterward.
- Finance/family/health/sensitive memory/tool/provider/file actions escalate when risky or ambiguous.
- Approval of that review item creating state only through the command bus.
- Audit events recording the mutation.
- Provider and gateway configuration visible without exposing secrets.

The key invariant: raw capture is evidence, AI output is contextual working state, and durable state changes happen only through controlled audited services. Review is for risk, ambiguity, sensitivity, external effects, destructive actions, and weak evidence.

## Start The System

From the repo root:

```bash
cp .env.example .env
python3 scripts/doctor.py
docker compose up -d --build
```

Then check the containers:

```bash
docker compose ps
```

Expected core services:

- `api`
- `web`
- `worker`
- `postgres`
- `redis`

Useful URLs:

- API health: `http://localhost:8000/api/health`
- API readiness: `http://localhost:8000/api/readiness`
- API docs: `http://localhost:8000/docs`
- WebUI: `http://localhost:5173`

Do not commit `.env`, provider keys, bot tokens, Codex auth caches, DB dumps, or raw private exports.

## Basic Health Checks

Run the local doctor:

```bash
python3 scripts/doctor.py
```

Doctor warnings about missing bot/provider environment variables mean those values are not present in your current shell. Docker Compose may still have them if `.env` is filled correctly.

Run the smoke test:

```bash
python3 scripts/smoke_test.py
```

Check API health directly:

```bash
curl -fsS http://localhost:8000/api/health
curl -fsS http://localhost:8000/api/readiness
curl -fsS http://localhost:8000/api/today
```

A clean dev stack may return an empty Today state. That is fine.

## Read-Only Safe Probe

Use this when you want to know whether API, WebUI, Docker services, and Discord auth/channel access are working without adding any LifeOS data:

```bash
python3 scripts/safe_probe.py --discord-read-only
```

The probe uses only GET requests, Docker log reads, and optional read-only Discord API checks. It creates no captures, reviews, audit events, vault files, Discord messages, or Telegram messages.

Expected strong result:

- `api.health` is OK.
- `web.index` is OK.
- `web.proxy.api_health` is OK.
- `docker.discord_gateway.api_reachable` is OK.
- `discord.auth.me` is OK.
- `discord.channel.read` is OK.

If you do not want the probe to contact Discord, omit `--discord-read-only`.

## Daily Use

Discord:

```text
/lifeos status
/lifeos new agent:orchestrator title:Plan today iteration_cap:5
/lifeos thread agent:research title:Research references iteration_cap:5
/lifeos agent agent:work.generic
/lifeos iterations iteration_cap:8
/lifeos cancel
/lifeos capture text:submit HR paper Monday
/lifeos ask message:what should I do today?
/lifeos reviews
/lifeos agents
/lifeos providers
/lifeos model agent:work.generic provider:openrouter model:openai/gpt-5.2-mini
/lifeos autonomy agent:deen-prayer mode:balanced
```

Legacy fallbacks:

```text
!status
!capture submit HR paper Monday
!today
!reviews
```

Telegram:

```text
/capture submit HR paper Monday
/ask summarize my pending work
/today
/status
```

Normal Telegram messages are still captured. Low-intent notes are archived raw-only; complex decisions move to Discord review.

WebUI:

- Use `Add Capture` for web captures.
- Use `Review Queue` buttons to approve, reject, correct, clarify, snooze, or mark done.
- Use `Agents` to enable/disable agents, choose autonomy, and edit primary/secondary provider models.
- Use `Providers` to test provider readiness without exposing raw keys.
- Use `Tool Permissions` to set `allow`, `ask`, or `deny`.
- Use `Runs` to inspect status events, handoffs, provider calls, tool calls, reviews, and audit events.

## Agent Session Test

Create or reuse a WebUI/API session and run one low-risk message:

```bash
curl -fsS -X POST http://localhost:8000/api/chat \
  -H 'Content-Type: application/json' \
  -d '{
    "source_platform": "web",
    "external_channel_id": "manual-test",
    "message": "File this as a low-risk planning note for LifeOS testing.",
    "iteration_cap": 3,
    "metadata": {"owner_authenticated": true}
  }'
```

Expected behavior:

- A session is created or reused.
- A run is created with an iteration cap.
- Status events show receive/classify/select/act.
- If policy allows it, a low-risk note is created autonomously through the command bus and audited.
- The response includes a compact final answer and `what_i_did_md`.

Send a correction:

```bash
curl -fsS -X POST http://localhost:8000/api/chat \
  -H 'Content-Type: application/json' \
  -d '{
    "source_platform": "web",
    "external_channel_id": "manual-test",
    "message": "Actually do not make similar notes into reminders unless I ask.",
    "iteration_cap": 3,
    "metadata": {"owner_authenticated": true}
  }'
```

Expected behavior: the correction links to the prior session/run where possible and creates a low-risk preference candidate without promoting sensitive durable memory.

## Write-Path End-To-End Test

Use a harmless test capture you are comfortable keeping in the local dev audit trail.

Create a capture:

```bash
curl -fsS -X POST http://localhost:8000/api/captures \
  -H 'Content-Type: application/json' \
  -d '{
    "source_platform": "web",
    "capture_kind": "text",
    "raw_text": "Test task: confirm LifeOS review loop is working",
    "metadata": {"manual_test": true}
  }'
```

The response includes `route.decision`. Random notes can return `raw_only`; work/finance/actions usually return a `review_item_id`.

Find pending reviews:

```bash
curl -fsS 'http://localhost:8000/api/reviews?status=pending'
```

Approve the review item, replacing `<review_item_id>` with the id from the response:

```bash
curl -fsS -X POST http://localhost:8000/api/reviews/<review_item_id>/decision \
  -H 'Content-Type: application/json' \
  -d '{
    "decision": "approve",
    "source_platform": "web",
    "decision_text": "Manual test approval"
  }'
```

Verify the result:

```bash
curl -fsS http://localhost:8000/api/today
curl -fsS http://localhost:8000/api/audit
curl -fsS http://localhost:8000/api/events
curl -fsS http://localhost:8000/api/runs
```

You should see:

- A raw capture saved under `vault/raw/web/...`.
- A run and status events for classification/routing/review creation.
- A pending review before approval.
- An audit event after approval.
- A new open task in Today after approval.

## Escalation Domain Checks

These checks verify that sensitive or high-impact domain captures become review items before state changes.

Work task:

```bash
curl -fsS -X POST http://localhost:8000/api/captures \
  -H 'Content-Type: application/json' \
  -d '{"source_platform":"web","capture_kind":"text","raw_text":"Need to submit the HR tax return paper request before Monday at 4:30pm"}'
```

Expected behavior: if the work action is ambiguous or high impact, a review item is created. Clear low-risk work notes/tasks may auto-apply in `balanced` mode and report afterward.

Finance capture:

```bash
curl -fsS -X POST http://localhost:8000/api/captures \
  -H 'Content-Type: application/json' \
  -d '{"source_platform":"web","capture_kind":"text","raw_text":"Spent 42 MAD on lunch today"}'
```

Expected behavior: a finance-sensitive review item is created. A finance entry should not be applied silently.

Memory candidate:

```bash
curl -fsS -X POST http://localhost:8000/api/memory/candidates \
  -H 'Content-Type: application/json' \
  -d '{
    "domain": "planning",
    "candidate_kind": "preference",
    "statement_md": "User prefers quick raw capture followed by Discord review.",
    "evidence_refs": [{"kind":"manual_test"}],
    "confidence": 0.8,
    "sensitivity": "normal"
  }'
```

Expected behavior: the candidate waits for review before becoming curated memory.

Job proposal:

```bash
curl -fsS -X POST http://localhost:8000/api/jobs \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Manual test reminder",
    "description_md": "Verify job review flow.",
    "schedule_type": "one_time",
    "schedule_json": {"at":"2099-01-01T09:00:00Z"},
    "command_json": {"type":"notify","body":"test"}
  }'
```

Expected behavior: job creation is escalation-gated and waits for review.

Tool approval:

```bash
curl -fsS -X POST http://localhost:8000/api/tools/calls \
  -H 'Content-Type: application/json' \
  -d '{
    "run_id": "00000000-0000-0000-0000-000000000000",
    "agent_id": "systems-devops",
    "tool_id": "terminal.run",
    "input_json": {"command":"pytest apps/api/tests -q"},
    "risk_level": "destructive_or_sensitive_action"
  }'
```

Expected behavior: high-risk or side-effecting tools require review instead of running silently.

## WebUI Checklist

Open `http://localhost:5173` and check:

- System health panel loads.
- Today count changes after an approved task.
- Review queue shows pending review items.
- Runs list shows recent capture processing.
- Providers page shows configured/unconfigured provider status without secret values.
- Audit log shows approval and state mutation events.

The WebUI is the command center. Daily review should still be possible through Discord once the gateway is configured.

## Provider Checks

List providers:

```bash
curl -fsS http://localhost:8000/api/providers
```

Test individual providers:

```bash
curl -fsS -X POST 'http://localhost:8000/api/providers/test?provider_id=openrouter'
curl -fsS -X POST 'http://localhost:8000/api/providers/test?provider_id=nvidia_nim'
curl -fsS -X POST 'http://localhost:8000/api/providers/test?provider_id=codex_oauth'
```

Expected behavior:

- Configured providers report usable status.
- Missing keys or auth caches are reported as configuration warnings.
- Raw key values are never returned.

## Gateway Checks

Gateways are optional in the local stack and run under the `gateways` Docker Compose profile.

Recommended Discord structure and setup commands live in [Discord channel structure](discord_channel_structure.md).

Required Discord settings:

- `DISCORD_BOT_TOKEN`
- `DISCORD_OWNER_USER_ID`
- `DISCORD_APPROVAL_CHANNEL_ID`

Required Telegram settings:

- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_OWNER_USER_ID`

Start gateways:

```bash
docker compose --profile gateways up -d discord-gateway telegram-gateway
```

Watch logs:

```bash
docker compose logs -f discord-gateway
docker compose logs -f telegram-gateway
```

Telegram test:

1. Send a message to the bot from the configured owner account.
2. Expect a quick capture acknowledgement.
3. Check WebUI or `/api/captures` for the raw capture.
4. Check `/api/reviews?status=pending` for anything that needs review.

Discord test:

1. Create a pending review through the API or Telegram.
2. Confirm a review card appears in the configured approval channel.
3. Approve through API/WebUI if interactive Discord controls are not enabled in your current adapter build.

## Vault Checks

The vault should show evidence and curated state, not become the daily UI.

Check raw evidence:

```bash
find vault/raw -type f | tail -20
```

Check manifests:

```bash
tail -20 vault/manifests/hashes.jsonl
tail -20 vault/manifests/sources.csv
```

Check curated memory and state snapshots:

```bash
find vault/memory/curated -type f -maxdepth 4
find vault/state -type f -maxdepth 2
```

Rules to preserve:

- `vault/raw` is append-only.
- Sensitive raw finance, family, health, secrets, backups, and auth caches are not indexed by default.
- Curated memory needs evidence and policy review.

## Troubleshooting

API is unhealthy:

```bash
docker compose logs api --tail=120
docker compose exec postgres pg_isready -U lifeos -d lifeos
```

WebUI is blank or stale:

```bash
docker compose logs web --tail=120
curl -fsS http://localhost:8000/api/readiness
```

Smoke test fails:

```bash
docker compose ps
docker compose logs api --tail=120
python3 scripts/doctor.py
```

Provider test fails:

- Confirm the relevant env var is present in `.env`.
- Restart API/worker after changing `.env`.
- Check `/api/providers` again.

Gateway is quiet:

- Confirm the `gateways` profile was started.
- Confirm owner user IDs match the real Discord/Telegram accounts.
- Confirm the Discord approval channel id is correct.
- Check gateway logs for auth or permission errors.

Review item does not apply:

- Check the review status.
- Check `/api/audit` for failed state changes.
- Check API logs for validation errors.
- Prefer creating a corrected review item over editing state directly.

## Stop Or Restart

Restart core services:

```bash
docker compose restart api web worker
```

Stop the stack:

```bash
docker compose down
```

Run a backup when needed:

```bash
bash scripts/backup.sh
```

## Final Working-Well Checklist

Before trusting a local build, confirm:

- `docker compose ps` shows core services running.
- `python3 scripts/doctor.py` has no unexpected failures.
- `python3 scripts/smoke_test.py` passes.
- `/api/health` is healthy.
- `/api/readiness` warnings are understood.
- WebUI loads at `http://localhost:5173`.
- A test capture creates raw evidence, run events, and a review item.
- Approval creates state through the command bus.
- Audit log records the state mutation.
- Provider status is visible without exposing secrets.
- Discord/Telegram gateways are either working or intentionally disabled.
