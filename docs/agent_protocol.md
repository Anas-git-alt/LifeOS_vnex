# Agent Protocol

Agents communicate through structured run results, handoffs, corrections, and review items instead of vague chat.

Run lifecycle:

```text
received -> session-bound message -> bounded orchestrator loop
-> intent classified -> agent selected -> optional handoff
-> autonomous low-risk action or clarification/review escalation
-> command bus for mutation -> audit/status events
-> final answer with what-I-did summary
```

Every handoff has a parent run, source agent, target agent, reason, task, known context, context refs, constraints, expected output schema, risk level, visibility, user visibility flag, result, summary, and status.

Corrections are first-class follow-ups. They link to the prior session/run/action when possible, apply safe fixes through the command bus, create low-risk preference candidates where useful, and escalate if the correction affects sensitive or high-impact state.
