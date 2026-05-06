import {
  Activity,
  Bell,
  Bot,
  CheckCircle2,
  CircleAlert,
  Database,
  FileClock,
  Inbox,
  KeyRound,
  ListChecks,
  MessageSquareMore,
  Save,
  ShieldCheck,
  SlidersHorizontal,
  Sparkles,
  TestTube2,
  WalletCards,
  X
} from "lucide-react";
import type { ReactNode } from "react";
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  askLifeOS,
  createCapture,
  decideReview,
  fetchAgents,
  fetchAudit,
  fetchCaptures,
  fetchProviders,
  fetchReadiness,
  fetchReviews,
  fetchRun,
  fetchRuns,
  fetchSessions,
  fetchToday,
  fetchToolPermissions,
  fetchTools,
  patchAgent,
  patchAgentModel,
  testProvider,
  upsertToolPermission,
  type AgentItem,
  type AgentModelEffective,
  type AuditItem,
  type CaptureItem,
  type ProviderItem,
  type ReadinessResponse,
  type ReviewItem,
  type RunDetail,
  type RunItem,
  type SessionItem,
  type TodayResponse,
  type ToolItem,
  type ToolPermission
} from "../api/client";
import { StatusPill } from "../components/StatusPill";

const navItems = [
  { label: "Today", icon: ListChecks },
  { label: "Inbox", icon: Inbox },
  { label: "Review Queue", icon: ShieldCheck },
  { label: "Ask", icon: MessageSquareMore },
  { label: "Sessions", icon: Bot },
  { label: "Agents", icon: Bot },
  { label: "Providers", icon: KeyRound },
  { label: "Tool Permissions", icon: SlidersHorizontal },
  { label: "Runs", icon: Activity },
  { label: "Audit Log", icon: FileClock },
  { label: "System Health", icon: Database }
];

type Snapshot = {
  readiness: ReadinessResponse | null;
  today: TodayResponse | null;
  reviews: ReviewItem[];
  runs: RunItem[];
  sessions: SessionItem[];
  captures: CaptureItem[];
  providers: ProviderItem[];
  agentModels: Record<string, AgentModelEffective>;
  agents: AgentItem[];
  tools: ToolItem[];
  permissions: ToolPermission[];
  audit: AuditItem[];
};

const emptySnapshot: Snapshot = {
  readiness: null,
  today: null,
  reviews: [],
  runs: [],
  sessions: [],
  captures: [],
  providers: [],
  agentModels: {},
  agents: [],
  tools: [],
  permissions: [],
  audit: []
};

export function App() {
  const [active, setActive] = useState("Today");
  const [snapshot, setSnapshot] = useState<Snapshot>(emptySnapshot);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [captureOpen, setCaptureOpen] = useState(false);
  const [runDetail, setRunDetail] = useState<RunDetail | null>(null);

  const refresh = useCallback(async () => {
    const [readiness, today, reviews, runs, sessions, captures, providers, agents, tools, permissions, audit] =
      await Promise.all([
        fetchReadiness(),
        fetchToday(),
        fetchReviews(),
        fetchRuns(),
        fetchSessions(),
        fetchCaptures(),
        fetchProviders(),
        fetchAgents(),
        fetchTools(),
        fetchToolPermissions(),
        fetchAudit()
      ]);
    setSnapshot({
      readiness,
      today,
      reviews: reviews.items,
      runs: runs.items,
      sessions: sessions.items,
      captures: captures.items,
      providers: providers.items,
      agentModels: providers.agent_models ?? {},
      agents: agents.items,
      tools: tools.items,
      permissions: permissions.items,
      audit: audit.items
    });
    setError(null);
  }, []);

  useEffect(() => {
    refresh().catch((caught: Error) => setError(caught.message));
    const timer = window.setInterval(() => {
      refresh().catch((caught: Error) => setError(caught.message));
    }, 7000);
    return () => window.clearInterval(timer);
  }, [refresh]);

  const readyCount = useMemo(() => {
    const checks = snapshot.readiness?.checks ?? [];
    return checks.filter((check) => check.ok).length;
  }, [snapshot.readiness]);

  async function action<T>(fn: () => Promise<T>, label: string) {
    try {
      await fn();
      setNotice(label);
      await refresh();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : String(caught));
    }
  }

  return (
    <div className="shell">
      <aside className="sidebar" aria-label="LifeOS navigation">
        <div className="brand">
          <div className="brand-mark">
            <Sparkles size={18} />
          </div>
          <div>
            <strong>LifeOS</strong>
            <span>Command Core</span>
          </div>
        </div>

        <nav className="nav-list">
          {navItems.map((item) => (
            <button
              key={item.label}
              className={`nav-item ${active === item.label ? "nav-item--active" : ""}`}
              type="button"
              onClick={() => setActive(item.label)}
            >
              <item.icon size={18} />
              <span>{item.label}</span>
            </button>
          ))}
        </nav>
      </aside>

      <main className="workspace">
        <header className="topbar">
          <div>
            <h1>{active}</h1>
            <p>{snapshot.today?.focus ?? "Loading LifeOS state"}</p>
          </div>
          <div className="topbar-actions">
            <button className="icon-button" type="button" aria-label="Notifications" title="Notifications">
              <Bell size={18} />
            </button>
            <button className="primary-button" type="button" onClick={() => setCaptureOpen(true)}>
              <MessageSquareMore size={18} />
              Add Capture
            </button>
          </div>
        </header>

        {error ? <Banner tone="red" icon={<CircleAlert size={18} />} text={error} onClose={() => setError(null)} /> : null}
        {notice ? <Banner tone="green" icon={<CheckCircle2 size={18} />} text={notice} onClose={() => setNotice(null)} /> : null}

        <section className="metrics-grid" aria-label="Daily status">
          <Metric label="Pending Review" value={String(snapshot.today?.counts.pending_reviews ?? snapshot.reviews.length)} icon={<ShieldCheck size={20} />} tone="amber" />
          <Metric label="Active Runs" value={String(snapshot.runs.length)} icon={<Bot size={20} />} tone="blue" />
          <Metric label="Open Tasks" value={String(snapshot.today?.counts.open_tasks ?? 0)} icon={<ListChecks size={20} />} tone="green" />
          <Metric label="System Checks" value={snapshot.readiness ? `${readyCount}/${snapshot.readiness.checks.length}` : "..."} icon={<Database size={20} />} tone={snapshot.readiness?.status === "ready" ? "green" : "amber"} />
        </section>

        {active === "Today" ? <TodayPage snapshot={snapshot} /> : null}
        {active === "Inbox" ? <InboxPage captures={snapshot.captures} /> : null}
        {active === "Review Queue" ? (
          <ReviewsPage
            reviews={snapshot.reviews}
            onDecision={(review, decision) =>
              action(async () => {
                const text =
                  decision === "correct" || decision === "clarify"
                    ? window.prompt(decision === "correct" ? "Correction" : "Clarifying detail") || ""
                    : "";
                await decideReview(review.id, decision, text, decision === "snooze" ? { hours: 8 } : {});
              }, `Review ${decision}`)
            }
          />
        ) : null}
        {active === "Ask" ? (
          <AskPage
            onAsk={async (message) => {
              try {
                const response = await askLifeOS(message);
                setNotice(response.answer);
                await refresh();
              } catch (caught) {
                setError(caught instanceof Error ? caught.message : String(caught));
              }
            }}
          />
        ) : null}
        {active === "Sessions" ? <SessionsPage sessions={snapshot.sessions} runs={snapshot.runs} /> : null}
        {active === "Agents" ? (
          <AgentsPage
            agents={snapshot.agents}
            providers={snapshot.providers}
            onSave={(agent, patch, modelPatch) =>
              action(async () => {
                await patchAgent(agent.id, patch);
                await patchAgentModel(agent.id, modelPatch);
              }, `Saved ${agent.id}`)
            }
          />
        ) : null}
        {active === "Providers" ? (
          <ProvidersPage
            providers={snapshot.providers}
            agentModels={snapshot.agentModels}
            onTest={(providerId) =>
              action(async () => {
                const result = await testProvider(providerId);
                setNotice(`${providerId}: ${result.status}`);
              }, "Provider tested")
            }
          />
        ) : null}
        {active === "Tool Permissions" ? (
          <ToolsPage
            tools={snapshot.tools}
            agents={snapshot.agents}
            permissions={snapshot.permissions}
            onSave={(permission) => action(async () => void (await upsertToolPermission(permission)), "Tool permission saved")}
          />
        ) : null}
        {active === "Runs" ? (
          <RunsPage
            runs={snapshot.runs}
            detail={runDetail}
            onSelect={(runId) => action(async () => setRunDetail(await fetchRun(runId)), "Run loaded")}
          />
        ) : null}
        {active === "Audit Log" ? <AuditPage audit={snapshot.audit} /> : null}
        {active === "System Health" ? <HealthPage readiness={snapshot.readiness} /> : null}
      </main>

      {captureOpen ? (
        <CaptureModal
          onClose={() => setCaptureOpen(false)}
          onSubmit={(payload) =>
            action(async () => {
              const response = await createCapture(payload);
              setCaptureOpen(false);
              setNotice(response.message);
            }, "Capture routed")
          }
        />
      ) : null}
    </div>
  );
}

function SessionsPage({ sessions, runs }: { sessions: SessionItem[]; runs: RunItem[] }) {
  const runById = new Map(runs.map((run) => [run.id, run]));
  return (
    <Panel title="Agent Sessions" marker={<Bot size={18} />}>
      <Rows
        empty="No sessions"
        items={sessions.map((session) => {
          const run = session.last_run_id ? runById.get(session.last_run_id) : undefined;
          return {
            id: session.id,
            title: session.title || session.id,
            subtitle: `${session.agent_id} · cap ${session.iteration_cap} · ${session.visibility}`,
            meta: run?.status ?? session.status,
            icon: <MessageSquareMore size={18} />,
            tone: session.paused_run_id ? "amber" : run?.status === "failed" ? "red" : "blue"
          };
        })}
      />
    </Panel>
  );
}

function TodayPage({ snapshot }: { snapshot: Snapshot }) {
  return (
    <section className="content-grid">
      <Panel title="Today" marker={<ListChecks size={18} />}>
        <Rows
          empty="No open tasks"
          items={(snapshot.today?.tasks ?? []).map((item) => ({
            id: item.id,
            title: item.title,
            subtitle: `${item.domain} · ${item.priority}`,
            meta: item.status,
            icon: <ListChecks size={18} />,
            tone: "green"
          }))}
        />
      </Panel>
      <Panel title="Recent Captures" marker={<Inbox size={18} />}>
        <Rows
          empty="No captures"
          items={(snapshot.today?.recent_captures ?? []).map((item) => ({
            id: item.id,
            title: item.raw_text || item.capture_kind,
            subtitle: item.source_platform,
            meta: item.status,
            icon: <Inbox size={18} />,
            tone: item.status === "raw_only" ? "neutral" : "blue"
          }))}
        />
      </Panel>
    </section>
  );
}

function InboxPage({ captures }: { captures: CaptureItem[] }) {
  return (
    <Panel title="Inbox" marker={<Inbox size={18} />}>
      <Rows
        empty="No captures"
        items={captures.map((item) => ({
          id: item.id,
          title: item.raw_text || item.capture_kind,
          subtitle: `${item.source_platform} · ${item.sensitivity}`,
          meta: item.status,
          icon: <Inbox size={18} />,
          tone: item.status === "waiting_approval" ? "amber" : item.status === "auto_applied" ? "green" : "neutral"
        }))}
      />
    </Panel>
  );
}

function ReviewsPage({ reviews, onDecision }: { reviews: ReviewItem[]; onDecision: (review: ReviewItem, decision: string) => void }) {
  if (!reviews.length) {
    return <Panel title="Review Queue" marker={<ShieldCheck size={18} />}><Empty icon={<ShieldCheck size={22} />} text="No review items" /></Panel>;
  }
  return (
    <section className="review-list">
      {reviews.map((review) => (
        <article className="review-card" key={review.id}>
          <div className="review-card-main">
            <div className="review-icon">{review.risk_level.includes("finance") ? <WalletCards size={18} /> : <ShieldCheck size={18} />}</div>
            <div>
              <h2>{review.title}</h2>
              <p>{review.body_md}</p>
              <div className="pill-row">
                <StatusPill label={review.status} tone={review.status === "pending" ? "amber" : "neutral"} />
                <StatusPill label={review.risk_level} tone={review.risk_level.includes("finance") ? "red" : "blue"} />
                <StatusPill label={review.proposed_by_agent_id ?? "agent"} tone="neutral" />
              </div>
            </div>
          </div>
          <div className="button-row">
            {["approve", "reject", "correct", "clarify", "snooze", "done"].map((decision) => (
              <button className={`small-button small-button--${decision}`} type="button" key={decision} onClick={() => onDecision(review, decision)}>
                {decision}
              </button>
            ))}
          </div>
        </article>
      ))}
    </section>
  );
}

function AskPage({ onAsk }: { onAsk: (message: string) => void | Promise<void> }) {
  const [message, setMessage] = useState("");
  return (
    <Panel title="Ask LifeOS" marker={<MessageSquareMore size={18} />}>
      <form className="form-stack" onSubmit={(event) => { event.preventDefault(); if (message.trim()) onAsk(message.trim()); }}>
        <textarea value={message} onChange={(event) => setMessage(event.target.value)} rows={5} placeholder="What should I do today?" />
        <button className="primary-button form-submit" type="submit"><MessageSquareMore size={18} /> Ask</button>
      </form>
    </Panel>
  );
}

function AgentsPage({ agents, providers, onSave }: { agents: AgentItem[]; providers: ProviderItem[]; onSave: (agent: AgentItem, patch: { enabled: boolean; autonomy_level: string }, modelPatch: { primary_provider_id?: string; primary_model?: string; secondary_provider_id?: string; secondary_model?: string; fallback_allowed?: boolean }) => void }) {
  return (
    <section className="settings-list">
      {agents.map((agent) => (
        <AgentRow key={agent.id} agent={agent} providers={providers} onSave={onSave} />
      ))}
    </section>
  );
}

function AgentRow({ agent, providers, onSave }: { agent: AgentItem; providers: ProviderItem[]; onSave: (agent: AgentItem, patch: { enabled: boolean; autonomy_level: string }, modelPatch: { primary_provider_id?: string; primary_model?: string; secondary_provider_id?: string; secondary_model?: string; fallback_allowed?: boolean }) => void }) {
  const [enabled, setEnabled] = useState(agent.enabled);
  const [autonomy, setAutonomy] = useState(agent.autonomy_level);
  const [primaryProvider, setPrimaryProvider] = useState(agent.model?.primary?.provider ?? providers[0]?.id ?? "");
  const [primaryModel, setPrimaryModel] = useState(agent.model?.primary?.model ?? "");
  const [secondaryProvider, setSecondaryProvider] = useState(agent.model?.secondary?.provider ?? "");
  const [secondaryModel, setSecondaryModel] = useState(agent.model?.secondary?.model ?? "");
  const [fallbackAllowed, setFallbackAllowed] = useState(Boolean(agent.model?.fallback_allowed ?? true));

  return (
    <article className="settings-row">
      <div>
        <h2>{agent.display_name}</h2>
        <span>{agent.id} · {agent.domain}</span>
      </div>
      <label><input type="checkbox" checked={enabled} onChange={(event) => setEnabled(event.target.checked)} /> enabled</label>
      <select value={autonomy} onChange={(event) => setAutonomy(event.target.value)}>
        {["manual", "review_gated", "balanced", "safe"].map((mode) => <option key={mode}>{mode}</option>)}
      </select>
      <select value={primaryProvider} onChange={(event) => setPrimaryProvider(event.target.value)}>
        {providers.map((provider) => <option key={provider.id} value={provider.id}>{provider.id}</option>)}
      </select>
      <input value={primaryModel} onChange={(event) => setPrimaryModel(event.target.value)} placeholder="primary model" />
      <select value={secondaryProvider} onChange={(event) => setSecondaryProvider(event.target.value)}>
        <option value="">none</option>
        {providers.map((provider) => <option key={provider.id} value={provider.id}>{provider.id}</option>)}
      </select>
      <input value={secondaryModel} onChange={(event) => setSecondaryModel(event.target.value)} placeholder="secondary model" />
      <label><input type="checkbox" checked={fallbackAllowed} onChange={(event) => setFallbackAllowed(event.target.checked)} /> fallback</label>
      <button className="icon-button" type="button" title="Save" onClick={() => onSave(agent, { enabled, autonomy_level: autonomy }, { primary_provider_id: primaryProvider, primary_model: primaryModel, secondary_provider_id: secondaryProvider || undefined, secondary_model: secondaryModel || undefined, fallback_allowed: fallbackAllowed })}>
        <Save size={18} />
      </button>
    </article>
  );
}

function ProvidersPage({ providers, agentModels, onTest }: { providers: ProviderItem[]; agentModels: Record<string, AgentModelEffective>; onTest: (providerId: string) => void }) {
  return (
    <section className="content-grid">
      <Panel title="Providers" marker={<KeyRound size={18} />}>
        <div className="review-list">
          {providers.map((provider) => (
            <article className="review-row review-row--wide" key={provider.id}>
              <div className="review-icon"><KeyRound size={18} /></div>
              <div className="review-main">
                <strong>{provider.display_name}</strong>
                <span>{provider.type} · {provider.base_url ?? "local"}</span>
              </div>
              <div className="review-meta">
                <StatusPill label={`${provider.keys.filter((key) => key.configured).length}/${provider.keys.length}`} tone={provider.keys.some((key) => key.configured) ? "green" : "amber"} />
                <button className="small-button" type="button" onClick={() => onTest(provider.id)}><TestTube2 size={14} /> test</button>
              </div>
            </article>
          ))}
        </div>
      </Panel>
      <Panel title="Agent Models" marker={<Bot size={18} />}>
        <Rows
          empty="No model config"
          items={Object.entries(agentModels).map(([agent, model]) => ({
            id: agent,
            title: agent,
            subtitle: `${model.primary?.provider ?? "provider"} · ${model.primary?.model ?? "model"}`,
            meta: model.fallback_allowed ? "fallback" : "strict",
            icon: <Bot size={18} />,
            tone: "blue"
          }))}
        />
      </Panel>
    </section>
  );
}

function ToolsPage({ tools, agents, permissions, onSave }: { tools: ToolItem[]; agents: AgentItem[]; permissions: ToolPermission[]; onSave: (permission: { agent_id: string; tool_id: string; effect: string; mode: string }) => void }) {
  const [agentId, setAgentId] = useState(agents[0]?.id ?? "");
  const [toolId, setToolId] = useState(tools[0]?.id ?? "");
  const [effect, setEffect] = useState("ask");
  const [mode, setMode] = useState("read_only");
  return (
    <section className="content-grid">
      <Panel title="Tool Permissions" marker={<SlidersHorizontal size={18} />}>
        <form className="inline-form" onSubmit={(event) => { event.preventDefault(); onSave({ agent_id: agentId, tool_id: toolId, effect, mode }); }}>
          <select value={agentId} onChange={(event) => setAgentId(event.target.value)}>{agents.map((agent) => <option key={agent.id}>{agent.id}</option>)}</select>
          <select value={toolId} onChange={(event) => setToolId(event.target.value)}>{tools.map((tool) => <option key={tool.id}>{tool.id}</option>)}</select>
          <select value={effect} onChange={(event) => setEffect(event.target.value)}>{["allow", "ask", "deny"].map((item) => <option key={item}>{item}</option>)}</select>
          <select value={mode} onChange={(event) => setMode(event.target.value)}>{["read_only", "dry_run", "write", "external_side_effect"].map((item) => <option key={item}>{item}</option>)}</select>
          <button className="primary-button" type="submit"><Save size={18} /> Save</button>
        </form>
        <Rows
          empty="No permissions"
          items={permissions.map((item) => ({
            id: item.id,
            title: `${item.agent_id} -> ${item.tool_id}`,
            subtitle: item.mode,
            meta: item.effect,
            icon: <SlidersHorizontal size={18} />,
            tone: item.effect === "allow" ? "green" : item.effect === "ask" ? "amber" : "red"
          }))}
        />
      </Panel>
      <Panel title="Tools" marker={<Database size={18} />}>
        <Rows empty="No tools" items={tools.map((tool) => ({ id: tool.id, title: tool.display_name, subtitle: tool.category, meta: tool.risk_level, icon: <Database size={18} />, tone: "neutral" }))} />
      </Panel>
    </section>
  );
}

function RunsPage({ runs, detail, onSelect }: { runs: RunItem[]; detail: RunDetail | null; onSelect: (runId: string) => void }) {
  return (
    <section className="content-grid">
      <Panel title="Runs" marker={<Activity size={18} />}>
        <div className="run-table" role="table" aria-label="Agent runs">
          <div className="run-table-head" role="row"><span>Run</span><span>Agent</span><span>Status</span><span>Provider</span><span>Cost</span></div>
          {runs.map((run) => (
            <button className="run-table-row run-table-button" role="row" key={run.id} type="button" onClick={() => onSelect(run.id)}>
              <span>{run.id}</span><span>{run.active_agent_id ?? "orchestrator"}</span><span>{run.status}</span><span>{run.provider_used ?? "n/a"}</span><span>{run.cost_usd ?? 0}</span>
            </button>
          ))}
        </div>
      </Panel>
      <Panel title="Run Detail" marker={<Activity size={18} />}>
        {detail ? <RunDetailView detail={detail} /> : <Empty icon={<Activity size={22} />} text="Select run" />}
      </Panel>
    </section>
  );
}

function RunDetailView({ detail }: { detail: RunDetail }) {
  return (
    <div className="detail-stack">
      <StatusPill label={detail.run.status} tone={detail.run.status === "failed" ? "red" : detail.run.status === "waiting_approval" ? "amber" : "green"} />
      <p>{detail.run.status_summary}</p>
      <h3>Events</h3>
      {detail.events.map((event) => <span key={event.id}>{event.event_type}: {event.title}</span>)}
      <h3>Handoffs</h3>
      {detail.handoffs.map((handoff) => <span key={handoff.id}>{handoff.from_agent_id} {"->"} {handoff.to_agent_id}: {handoff.status}</span>)}
      <h3>Provider</h3>
      {detail.provider_calls.map((call) => <span key={call.id}>{call.provider_id}/{call.model}: {call.status}</span>)}
      <h3>Reviews</h3>
      {detail.review_items.map((review) => <span key={review.id}>{review.title}: {review.status}</span>)}
      <h3>Tool Calls</h3>
      {detail.tool_calls.map((call) => <span key={call.id}>{call.tool_id}: {call.status}</span>)}
    </div>
  );
}

function AuditPage({ audit }: { audit: AuditItem[] }) {
  return <Panel title="Audit Log" marker={<FileClock size={18} />}><Rows empty="No audit events" items={audit.map((event) => ({ id: event.id, title: event.summary, subtitle: `${event.actor_type}:${event.actor_id}`, meta: event.event_type, icon: <FileClock size={18} />, tone: "neutral" }))} /></Panel>;
}

function HealthPage({ readiness }: { readiness: ReadinessResponse | null }) {
  return (
    <Panel title="System Health" marker={<Database size={18} />}>
      <div className="health-list">
        {readiness ? readiness.checks.map((check) => (
          <div className="health-row" key={check.name}>
            {check.ok ? <CheckCircle2 size={17} /> : <CircleAlert size={17} />}
            <span>{check.name.replaceAll("_", " ")}</span>
            <StatusPill label={check.ok ? "ok" : "config"} tone={check.ok ? "green" : "amber"} />
          </div>
        )) : <Empty icon={<Database size={22} />} text="Loading checks" />}
      </div>
    </Panel>
  );
}

function CaptureModal({ onClose, onSubmit }: { onClose: () => void; onSubmit: (payload: { raw_text: string; source_platform: string; capture_kind: string; sensitivity: string }) => void }) {
  const [text, setText] = useState("");
  const [platform, setPlatform] = useState("web");
  const [kind, setKind] = useState("text");
  const [sensitivity, setSensitivity] = useState("normal");
  return (
    <div className="modal-backdrop">
      <form className="modal" onSubmit={(event) => { event.preventDefault(); if (text.trim()) onSubmit({ raw_text: text.trim(), source_platform: platform, capture_kind: kind, sensitivity }); }}>
        <div className="modal-header"><h2>Add Capture</h2><button className="icon-button" type="button" onClick={onClose}><X size={18} /></button></div>
        <textarea rows={7} value={text} onChange={(event) => setText(event.target.value)} autoFocus />
        <div className="inline-form">
          <select value={platform} onChange={(event) => setPlatform(event.target.value)}><option>web</option><option>discord</option><option>telegram</option></select>
          <select value={kind} onChange={(event) => setKind(event.target.value)}><option>text</option><option>link</option><option>mixed</option></select>
          <select value={sensitivity} onChange={(event) => setSensitivity(event.target.value)}><option>normal</option><option>finance</option><option>health</option><option>family</option><option>secret</option></select>
        </div>
        <button className="primary-button form-submit" type="submit"><MessageSquareMore size={18} /> Submit</button>
      </form>
    </div>
  );
}

type PanelProps = { title: string; marker: ReactNode; children: ReactNode };

function Panel({ title, marker, children }: PanelProps) {
  return <section className="panel"><div className="panel-header"><div className="panel-title"><span>{marker}</span><h2>{title}</h2></div></div>{children}</section>;
}

type RowItem = { id: string; title: string; subtitle: string; meta: string; icon: ReactNode; tone: "green" | "amber" | "red" | "blue" | "neutral" };

function Rows({ items, empty }: { items: RowItem[]; empty: string }) {
  if (!items.length) return <Empty icon={<Inbox size={22} />} text={empty} />;
  return (
    <div className="review-list">
      {items.map((item) => (
        <article className="review-row" key={item.id}>
          <div className="review-icon">{item.icon}</div>
          <div className="review-main"><strong>{item.title}</strong><span>{item.subtitle}</span></div>
          <div className="review-meta"><StatusPill label={item.meta} tone={item.tone} /></div>
        </article>
      ))}
    </div>
  );
}

function Empty({ icon, text }: { icon: ReactNode; text: string }) {
  return <div className="empty-state">{icon}<span>{text}</span></div>;
}

type MetricProps = { label: string; value: string; icon: ReactNode; tone: "green" | "amber" | "red" | "blue" | "neutral" };

function Metric({ label, value, icon, tone }: MetricProps) {
  return <div className={`metric metric--${tone}`}><div className="metric-icon">{icon}</div><div><span>{label}</span><strong>{value}</strong></div></div>;
}

function Banner({ icon, text, tone, onClose }: { icon: ReactNode; text: string; tone: "red" | "green"; onClose: () => void }) {
  return <section className={`alert-band alert-band--${tone}`}>{icon}<span>{text}</span><button className="icon-button" type="button" onClick={onClose}><X size={16} /></button></section>;
}
