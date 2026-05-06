# ADR 0003: Postgres Plus Vault

Status: accepted

Postgres stores operational truth and queryable workflow state. The vault stores durable human-readable evidence, memory, wiki, reports, and artifacts.

Every important DB row should reference source evidence or an audit/event id.
