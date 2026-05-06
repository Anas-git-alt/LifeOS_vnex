# LifeOS Vault

The vault is durable, human-readable infrastructure. It is not the daily UI.

Rules:

1. `raw/` is append-only evidence.
2. `ledger/` is append-only except explicit correction events.
3. `memory/review/` contains candidates, not truth.
4. `memory/curated/` and `wiki/` contain approved durable understanding.
5. `state/` contains operational snapshots that can be regenerated.
6. `reports/` are readable summaries, not raw dumps.
7. `system/dead-letter/` stores items that could not be processed safely.
8. Sensitive raw data is not indexed by default.
9. Every generated update needs source refs, confidence, status, and last-updated metadata.
