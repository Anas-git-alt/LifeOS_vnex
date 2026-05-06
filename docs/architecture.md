# Architecture

LifeOS vNext is organized around a simple boundary: channels capture and render, the API commands and audits, workers execute background jobs, and the vault preserves human-readable evidence and truth.

```text
Telegram -> API -> Worker -> Orchestrator -> Specialist -> Approval Manager -> Discord
Discord  -> API -> Command Bus -> Audit/Event Log -> WebUI
```

## Services

- `api`: FastAPI command core. Only service intended to mutate operational DB state.
- `discord-gateway`: primary review and interaction gateway.
- `telegram-gateway`: fast raw-capture gateway.
- `worker`: async jobs, agent runs, tool execution, memory review, scheduled jobs.
- `web`: command center for traces, queues, configuration, health, and audit.
- `vault`: raw evidence, ledger, curated memory, wiki, reports, artifacts.

## Invariants

Raw captures are immutable evidence. Agent output is draft interpretation. Important durable changes become true only after Approval Manager policy and audit.
