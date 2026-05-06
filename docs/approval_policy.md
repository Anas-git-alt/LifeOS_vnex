# Approval Policy

LifeOS uses escalation-gated autonomy: safe reversible work can finish and report afterward; risky work escalates before mutation.

Policy decision shape:

```json
{
  "decision": "auto_apply | review_required | ask_clarification | reject | raw_only",
  "reason": "...",
  "risk_level": "...",
  "confidence": 0.0,
  "requires_user_visible_status": true
}
```

Autonomy modes:

- `manual`: everything actionable becomes review.
- `review_gated`: only raw-only archive and explicit no-op review actions auto-complete.
- `balanced`: default agentic mode; low-risk reversible notes/tasks/logs/preference candidates can auto-apply.
- `safe`: broader low-risk auto-apply, still blocks sensitive/destructive/external actions.

Always review:

- Finance mutations.
- Durable memory writes.
- Family-sensitive facts.
- Health-sensitive durable facts.
- File write/edit/move/delete.
- Terminal commands.
- External API side effects.
- Provider/tool permission changes.
- New automations/jobs.
- Low-confidence or missing-context interpretations.
- Ambiguous actions where multiple plausible interpretations could harm outcome.

Can auto-apply in `balanced` or `safe` when owner-authenticated, high-confidence, non-sensitive, and allowlisted:

- Explicit prayer logs.
- Simple daily logs.
- Clear low-risk LifeOS notes/tasks.
- Low-risk behavior or routing preference candidates from corrections.
- Marking review done.
- Raw-only archive for non-action notes.

Telegram random thoughts should become raw-only ledger context unless they contain clear action intent. AI drafts are never durable sensitive truth by themselves. Follow-up corrections should fix forward where safe and create preference candidates when useful.
