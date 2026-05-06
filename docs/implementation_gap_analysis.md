# Implementation Gap Analysis

LifeOS vNext already has strong spine: FastAPI command core, raw capture vault writes, audited command bus, review items, status events, handoffs, provider config, Discord review cards, Telegram capture, and WebUI observability.

## What Already Exists

- Raw captures are preserved under `vault/raw` and linked to DB rows.
- Capture routing can use a provider first and deterministic fallback.
- Review items, decisions, state changes, audit events, tool calls, provider logs, runs, handoffs, memory candidates, and jobs exist in the DB model.
- Discord gateway is thin and supports `/lifeos` subcommands, review buttons, modals, and legacy commands.
- Telegram gateway is raw-capture-first.
- WebUI shows Today, captures, reviews, agents, providers, tools, runs, audit, and health.
- Provider config supports OpenRouter, NVIDIA NIM, and Codex OAuth as configured providers.

## What Is Missing

- First-class agent session APIs for Discord chat/thread binding, active agent selection, iteration caps, cancellation, and message history.
- Normal Discord messages do not yet become agent-session messages.
- `/new`, `/thread`, `/agent`, `/iterations`, and `/cancel` are not implemented.
- Runs do not yet store iteration cap, iteration count, cancellation refs, or structured result JSON.
- Handoff protocol is present but too small for task ownership, known context, risk, constraints, and structured response.
- Correction handling is not first-class; follow-up corrections are not linked to prior runs/actions.
- Low-risk preference learning needs an automatic candidate path separate from sensitive durable memory.
- Current wording still says review-gated by default in several docs/configs.
- Provider fallback exists as config but router code only uses the first configured key/model.

## Enhancement Path In This Pass

- Add session/message lifecycle APIs and DB fields.
- Add bounded agent runtime with iteration cap, status events, structured result, autonomous low-risk action path, clarification/review path, and correction path.
- Add Discord `/lifeos new`, `/lifeos thread`, `/lifeos agent`, `/lifeos iterations`, `/lifeos cancel`, and normal message-to-session flow.
- Extend handoff/tool/provider configs and schemas.
- Add WebUI visibility for sessions and richer run details.
- Update docs from review-gated default to escalation-gated autonomy.
- Add tests for routing policy, session runtime, Discord formatting/parsing, provider fallback, and correction preference candidates.

## Intentionally Deferred

- True streaming status delivery from API to Discord over a push channel.
- Full multi-agent concurrent execution.
- Real external tool execution beyond logged/dry-run approval gateway.
- Full Discord thread lifecycle polish for every guild permission edge case.
- Automatic sensitive memory promotion.
- Production-grade provider circuit breaker persistence.

## Invariants To Protect

- Raw captures stay immutable evidence.
- Sensitive raw finance, family, health, secrets, backups, and auth caches are not indexed by default.
- Important state mutation still uses controlled services/command bus.
- Every state mutation is audited.
- Every tool call is logged with run id, agent id, input/output, and risk.
- Handoffs are traceable.
- Durable memory facts keep evidence refs.
- Gateways stay thin; API/worker/packages own business logic.
- Work Agent stays generic until approved context proves real work domain.

## Review-Gated To Escalation-Gated

Old default: make most interpretations into review items.

New default:

- Evidence before truth.
- Autonomy before interruption.
- Escalation before risky mutation.
- Correction before bureaucracy.

Low-risk, reversible, permissioned actions may complete autonomously and report afterward. Ambiguous, sensitive, high-impact, destructive, external, or hard-to-reverse actions escalate to clarification or review. Follow-up corrections link to prior runs, fix what can be fixed, and create low-risk preference candidates when useful.

## Reference Ideas Used

- Hermes Agent: shared slash commands across CLI/messaging, `/new`, gateway-first chat, visible status/tool progress, provider choice, learning loop.
- OpenClaw: local gateway control plane, session commands, channel bindings, trace/verbose controls.
- OpenSwarm/VRSEN OpenSwarm: orchestrator plus specialists, task ownership, explicit handoff trace.
- Old LifeOS/Hermos-LifeOS: Discord-first personal ops, vault/evidence layout, Today/review loop, domain agents.
