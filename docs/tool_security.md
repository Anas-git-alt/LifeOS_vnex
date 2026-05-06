# Tool Security

Tools are centrally registered and policy-controlled.

Effects:

- `allow`
- `ask`
- `deny`
- `dry_run`
- `read_only`
- `scoped`

Risk levels run from safe internal read to destructive or sensitive action. File writes require diff preview and approval. Destructive commands require explicit owner approval and dry-run where possible.
