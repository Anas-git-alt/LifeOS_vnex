# Conversational Action Loop

LifeOS uses Discord as the first-class MVP chat surface. Normal conversation stays read-only. Explicit low-risk commands can execute immediately. Inferred useful actions become inline proposals. Risky, sensitive, recurring, destructive, file, terminal, provider, external side-effect, and memory actions go to formal review.

## UX Policy

- Answer questions and advice without creating tasks, logs, or memory.
- Execute explicit low-risk commands immediately, then summarize what happened.
- Ask inline before creating inferred tasks from natural language.
- Store pending proposals so follow-ups like "yes", "ignore it", and "make it Saturday morning" target the prior proposal.
- Use formal review for actions that are recurring, sensitive, destructive, external, hard to reverse, or related to file/terminal/provider/tool/memory changes.
- Keep Discord simple: plain answer, plain success, inline proposal card, or formal review card.

## Execution Modes

- `answer_only`: send a normal Discord reply; no durable mutation.
- `execute_now`: create or update state through `CommandBus` for explicit low-risk commands.
- `propose_inline`: persist `PendingActionProposal` and render Create/Edit/Ignore buttons in Discord.
- `formal_review`: create a `ReviewItem`; existing review cards and decisions handle approval.
- `clarify`: ask one compact question before acting.

## Examples

- "remind me tomorrow at 9 to call the dentist" -> creates a one-time reminder job immediately.
- "create a task to send invoice tomorrow" -> creates a task immediately.
- "I need to take my suit to the ironing shop before the wedding" -> creates an inline task proposal.
- "yes" after an inline proposal -> executes the stored proposal through `CommandBus`.
- "make pickup Saturday morning" -> revises the stored proposal and keeps it pending.
- "give me a cheap high protein dinner idea" -> answers only.
- "I prefer evening reminders" -> creates formal memory review, not durable memory.
- "every Friday remind me to review expenses" -> creates formal recurring-job review.
- "delete old task files" -> creates formal review and does not execute.

## Data Flow

```text
Discord message
-> POST /api/chat
-> Agent session runtime records Message + AgentRun
-> pending proposal follow-up check
-> conversation_action_planner returns structured plan
-> deterministic policy enforcement
-> answer / CommandBus / PendingActionProposal / ReviewItem
-> audit + status events
-> Discord renders plain reply, proposal buttons, or existing review card
```

Inline proposal buttons call:

```text
POST /api/action-proposals/{proposal_id}/decision
```

Formal review buttons continue to call:

```text
POST /api/reviews/{review_id}/decision
```

## Risk Policy

Low-risk explicit commands may execute when reversible and permissioned. Anything ambiguous, sensitive, recurring, destructive, external, hard to reverse, or involving memory/tool/file/terminal/provider changes must not execute from the planner directly.

The LLM/planner never writes durable operational state itself. Durable mutations go through `CommandBus`, review decisions, and audited service paths.

## Current Implementation

- Planner: `apps/api/lifeos_api/services/conversation_action_planner.py`
- Proposal persistence/execution: `apps/api/lifeos_api/services/conversation_action_service.py`
- Runtime integration: `apps/api/lifeos_api/services/agent_runtime.py`
- API endpoint: `apps/api/lifeos_api/routers/action_proposals.py`
- DB model: `PendingActionProposal`
- Migration: `apps/api/lifeos_api/db/migrations/versions/0005_pending_action_proposals.py`
- Discord rendering/buttons: `apps/discord-gateway/discord_gateway/main.py`

## Test Commands

This checkout uses the `apps/` layout rather than legacy `backend/` and `discord-bot/` top-level directories.

```bash
python3 -m compileall apps packages scripts
python3 -m pytest -q apps/api/tests
python3 -m pytest -q apps/discord-gateway/tests
```

The current gateway-specific directory has no standalone tests; Discord helper tests live under `apps/api/tests/test_gateway_helpers.py`.
