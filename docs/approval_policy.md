# Approval Policy

Approval levels:

- `none`: read-only or harmless response.
- `confirm_light`: reaction/button confirmation is enough.
- `review_card`: structured approve/reject/correct flow.
- `explicit_owner_approval`: owner identity plus clear action text.
- `dry_run_then_approval`: plan or diff before approval.

Always ask for durable memory writes, finance mutations, sensitive family/health changes, external side effects, file writes, provider config changes, tool permission changes, new agents, and natural-language job creation.
