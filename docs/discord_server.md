# Discord Server

Discord is the main structured interaction layer for chat, status, and escalation.

Channels:

- `#dashboard`
- `#daily-plan`
- `#approval-queue`
- `#agent-handoffs`
- `#quick-capture`
- `#work-tracker`
- `#finance-tracker`
- `#prayer-tracker`
- `#habits-health`
- `#system-notifications`
- `#audit-log`
- `#bot-testing`

Review cards should include source, interpretation, proposed action, confidence, risk, agent, and review id. Reply corrections are interpreted and validated by the Approval Manager before anything is applied.

Session chat:

- `/lifeos new` starts a channel-bound session.
- `/lifeos thread` creates or binds a thread session.
- `/lifeos agent` switches the active agent.
- `/lifeos iterations` controls bounded loops.
- `/lifeos cancel` cancels the latest cancellable run.
- Normal owner messages in configured LifeOS channels route to `/api/chat` and default to Orchestrator unless a session/thread selected another agent.

Discord should stay compact: received/routing/handoff/review/done statuses are visible, while provider payloads, raw tool data, and stack traces stay in WebUI.
