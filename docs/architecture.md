# Architecture

LifeOS vNext is organized around a simple boundary: channels capture and render, the API commands and audits, workers execute background jobs, and the vault preserves human-readable evidence and truth.

```text
Telegram -> API -> Worker -> Orchestrator -> Specialist -> Approval Manager -> Discord
Discord  -> API -> Agent Session Runtime -> Command Bus -> Audit/Event Log -> WebUI
```

## Services

- `api`: FastAPI command core. Owns sessions, commands, validation, policy, audit, and operational DB mutation.
- `discord-gateway`: primary review and interaction gateway. Converts slash commands/messages into API session commands.
- `telegram-gateway`: fast raw-capture gateway.
- `worker`: async jobs, agent runs, tool execution, memory review, scheduled jobs.
- `web`: command center for traces, queues, configuration, health, and audit.
- `vault`: raw evidence, ledger, curated memory, wiki, reports, artifacts.

## Invariants

Raw captures are immutable evidence. Agent output is contextual working state. Low-risk reversible actions may complete autonomously through controlled services and audit. Ambiguous, sensitive, high-impact, destructive, external, or hard-to-reverse changes escalate to clarification or review before mutation.
