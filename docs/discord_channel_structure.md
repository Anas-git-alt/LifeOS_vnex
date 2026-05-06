# Discord Channel Structure

LifeOS uses Discord as the daily command surface, not as raw storage. The ideal server is private by default, split into four categories.

## Ideal Layout

`COMMAND CENTER`:

- `#dashboard`: high-level status and links.
- `#daily-plan`: morning plan, shutdown plan, day adjustments.
- `#approval-queue`: review cards only.
- `#quick-capture`: fast owner capture.
- `#bot-testing`: safe bot tests.

`TRACKERS`:

- `#work-tracker`: commitments, blockers, next actions.
- `#finance-tracker`: finance reviews and approved summaries.
- `#prayer-tracker`: prayer logs and summaries.
- `#habits-health`: health-sensitive habits/review.
- `#family-commitments`: private family commitments.

`AGENTS`:

- `#agent-handoffs`: compact handoff trace.
- `#agent-runs`: run lifecycle summaries.
- `#memory-review`: memory candidates before promotion.
- `#research-lab`: source-backed research drafts.

`OPERATIONS`:

- `#system-notifications`: system notices and warnings.
- `#audit-log`: human-readable audit summaries.
- `#dead-letter`: failed delivery and repair queue.

All LifeOS channels should deny `@everyone` view access and allow only the owner and bot.

## Setup

Read-only plan:

```bash
python3 scripts/setup_discord_server.py
```

Create missing categories/channels only:

```bash
python3 scripts/setup_discord_server.py --apply
```

Create missing categories/channels, move existing channels into configured categories, update topics, and write channel IDs into `.env`:

```bash
python3 scripts/setup_discord_server.py --apply --sync-existing --write-env
```

Restart gateways after `.env` changes:

```bash
docker compose --profile gateways up -d --force-recreate discord-gateway web
```

Register slash commands:

```bash
python3 scripts/setup_discord_commands.py --dry-run
python3 scripts/setup_discord_commands.py
```

Required command env:

- `DISCORD_BOT_TOKEN`
- `DISCORD_APPLICATION_ID` or a valid bot token that can resolve application metadata
- `DISCORD_OWNER_USER_ID`
- `DISCORD_GUILD_ID` for fast guild command registration, optional for global
- `DISCORD_APPROVAL_CHANNEL_ID`

## Commands

Slash commands:

- `/lifeos help`
- `/lifeos new agent:<agent_id> title:<title> iteration_cap:<n>`
- `/lifeos thread agent:<agent_id> title:<title> iteration_cap:<n>`
- `/lifeos agent [agent:<agent_id>]`
- `/lifeos iterations [iteration_cap:<n>]`
- `/lifeos cancel`
- `/lifeos status`
- `/lifeos capture text:<text>`
- `/lifeos today`
- `/lifeos reviews`
- `/lifeos ask message:<message>`
- `/lifeos agents`
- `/lifeos providers`
- `/lifeos model agent:<agent_id> provider:<provider_id> model:<model>`
- `/lifeos autonomy agent:<agent_id> mode:<safe|balanced|review_gated|manual>`
- `/lifeos sync`

Legacy fallbacks:

- `!lifeos help`
- normal owner messages in configured channels route to the active agent session
- `!capture ...`
- `!ask ...`
- `!today`
- `!reviews`
- `!status`

## Review Cards

Pending reviews post to `#approval-queue` with buttons:

- Approve applies the proposed command through API command bus.
- Reject closes the review without mutation.
- Correct opens a modal and appends correction text or replaces payload when provided by API clients.
- Clarify opens a modal and marks the item `needs_clarification`.
- Snooze hides it until later.
- Done marks no-op/manual items complete.

All button clicks call `POST /api/reviews/{review_id}/decision` with `source_platform=discord` and the Discord message id when available.

## Agent Sessions

- `/lifeos new` creates a session in the current channel and defaults to `orchestrator`.
- `/lifeos thread` creates or binds a Discord thread where possible and stores the thread id on the session.
- `/lifeos agent` shows or changes the selected agent for the current channel/thread.
- `/lifeos iterations` shows or changes the session iteration cap.
- Normal owner messages in LifeOS channels/threads call `/api/chat`.
- Discord shows compact status and final answers; full traces stay in WebUI run/session pages.

## Manual Tests

Read-only full probe:

```bash
python3 scripts/safe_probe.py --discord-read-only --discord-structure
```

Expected: Discord auth/channel checks OK. Structure checks should be OK after setup; before setup they may warn about missing channels.

Read-only bot-testing channel check:

```bash
python3 scripts/discord_manual_test.py
```

Send one test message to `#bot-testing`, wait five seconds, delete it:

```bash
python3 scripts/discord_manual_test.py --send-delete
```

Check gateway logs:

```bash
docker compose logs discord-gateway --tail=80
```

Expected:

- `discord-gateway review posting enabled api_base=http://api:8000`
- `discord-gateway websocket connected`
- `discord-gateway websocket ready session_id=...`
- No `connection refused`
- No `Traceback`

Discord shows the bot online only when the websocket is connected. REST-only checks can send messages but still look offline in Discord.

Safe WebUI check:

```bash
curl -fsS http://localhost:5173/api/health
```

Expected:

```json
{"service":"lifeos-api","status":"ok"}
```
