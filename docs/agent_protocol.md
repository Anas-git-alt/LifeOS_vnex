# Agent Protocol

Agents communicate through structured handoffs and review items instead of vague chat.

Run lifecycle:

```text
received -> normalized -> grounded -> classified -> routed -> specialist run
-> optional handoff -> optional tool calls -> draft result/action
-> approval policy check -> Discord/WebUI surface -> decision
-> command bus -> audit -> memory/report updates
```

Every handoff has a parent run, source agent, target agent, reason, task, context refs, constraints, expected output schema, visibility, and status.
