# WebUI Usage

Open `http://localhost:5173`.

## Capture

Use `Add Capture`.

Fields:

- Text.
- Source platform, default `web`.
- Capture kind, default `text`.
- Sensitivity, default `normal`.

Submit calls `POST /api/captures` and refreshes Today, Inbox, Reviews, Sessions, Runs, Providers, Agents, Tools, and Audit.

## Sessions

`Sessions` shows active agent conversations:

- selected agent,
- iteration cap,
- visibility,
- last run status,
- paused clarification run when present.

Discord `/lifeos new`, `/lifeos thread`, normal owner messages, and `POST /api/chat` all create or reuse these sessions.

## Reviews

`Review Queue` buttons call `POST /api/reviews/{id}/decision`:

- Approve.
- Reject.
- Correct, with prompt text.
- Clarify, with prompt text.
- Snooze.
- Done.

Approve applies state only through the API command bus and writes audit.

## Agents

`Agents` lists DB-backed runtime config. Save updates:

- Enabled.
- Autonomy mode.
- Primary provider/model.
- Secondary provider/model.
- Fallback allowed.

YAML remains bootstrap only; WebUI edits DB overrides.

## Providers

`Providers` shows configured key counts by env var label. Raw secrets are never shown. `test` writes a provider call log and returns configured/missing-key status.

## Tool Permissions

`Tool Permissions` edits agent x tool rules:

- `allow`
- `ask`
- `deny`

Modes:

- `read_only`
- `dry_run`
- `write`
- `external_side_effect`

## Runs

`Runs` shows run list. Select a run to see:

- Status and summary.
- Iteration cap/current iteration.
- Status events.
- Handoffs.
- Provider calls.
- Review items.
- Tool calls.
- Audit events.

Live refresh polls every seven seconds.
