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
  ShieldCheck,
  Sparkles,
  WalletCards
} from "lucide-react";
import type { ReactNode } from "react";
import { useEffect, useMemo, useState } from "react";
import {
  fetchAudit,
  fetchCaptures,
  fetchProviders,
  fetchReadiness,
  fetchReviews,
  fetchRuns,
  fetchToday,
  type AuditItem,
  type CaptureItem,
  type ProviderItem,
  type ReadinessResponse,
  type ReviewItem,
  type RunItem,
  type TodayResponse
} from "../api/client";
import { StatusPill } from "../components/StatusPill";

const navItems = [
  { label: "Today", icon: ListChecks },
  { label: "Inbox", icon: Inbox },
  { label: "Review Queue", icon: ShieldCheck },
  { label: "Runs", icon: Activity },
  { label: "Audit Log", icon: FileClock },
  { label: "Providers", icon: KeyRound },
  { label: "System Health", icon: Database }
];

type Snapshot = {
  readiness: ReadinessResponse | null;
  today: TodayResponse | null;
  reviews: ReviewItem[];
  runs: RunItem[];
  captures: CaptureItem[];
  providers: ProviderItem[];
  audit: AuditItem[];
};

const emptySnapshot: Snapshot = {
  readiness: null,
  today: null,
  reviews: [],
  runs: [],
  captures: [],
  providers: [],
  audit: []
};

export function App() {
  const [snapshot, setSnapshot] = useState<Snapshot>(emptySnapshot);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([
      fetchReadiness(),
      fetchToday(),
      fetchReviews(),
      fetchRuns(),
      fetchCaptures(),
      fetchProviders(),
      fetchAudit()
    ])
      .then(([readiness, today, reviews, runs, captures, providers, audit]) => {
        setSnapshot({
          readiness,
          today,
          reviews: reviews.items,
          runs: runs.items,
          captures: captures.items,
          providers: providers.items,
          audit: audit.items
        });
      })
      .catch((caught: Error) => setError(caught.message));
  }, []);

  const readyCount = useMemo(() => {
    const checks = snapshot.readiness?.checks ?? [];
    return checks.filter((check) => check.ok).length;
  }, [snapshot.readiness]);

  return (
    <div className="shell">
      <aside className="sidebar" aria-label="LifeOS navigation">
        <div className="brand">
          <div className="brand-mark">
            <Sparkles size={18} />
          </div>
          <div>
            <strong>LifeOS</strong>
            <span>Hermos Swarm</span>
          </div>
        </div>

        <nav className="nav-list">
          {navItems.map((item) => (
            <a key={item.label} className="nav-item" href={`#${item.label.toLowerCase().replaceAll(" ", "-")}`}>
              <item.icon size={18} />
              <span>{item.label}</span>
            </a>
          ))}
        </nav>
      </aside>

      <main className="workspace">
        <header className="topbar">
          <div>
            <h1>Today</h1>
            <p>{snapshot.today?.focus ?? "Loading LifeOS state"}</p>
          </div>
          <div className="topbar-actions">
            <button className="icon-button" type="button" aria-label="Notifications" title="Notifications">
              <Bell size={18} />
            </button>
            <button className="primary-button" type="button">
              <MessageSquareMore size={18} />
              Add Capture
            </button>
          </div>
        </header>

        {error ? (
          <section className="alert-band">
            <CircleAlert size={18} />
            <span>{error}</span>
          </section>
        ) : null}

        <section className="metrics-grid" aria-label="Daily status">
          <Metric
            label="Pending Review"
            value={String(snapshot.today?.counts.pending_reviews ?? snapshot.reviews.length)}
            icon={<ShieldCheck size={20} />}
            tone="amber"
          />
          <Metric label="Active Runs" value={String(snapshot.runs.length)} icon={<Bot size={20} />} tone="blue" />
          <Metric
            label="Open Tasks"
            value={String(snapshot.today?.counts.open_tasks ?? 0)}
            icon={<ListChecks size={20} />}
            tone="green"
          />
          <Metric
            label="System Checks"
            value={snapshot.readiness ? `${readyCount}/${snapshot.readiness.checks.length}` : "..."}
            icon={<Database size={20} />}
            tone={snapshot.readiness?.status === "ready" ? "green" : "amber"}
          />
        </section>

        <section className="content-grid" id="review-queue">
          <Panel title="Review Queue" marker={<ShieldCheck size={18} />}>
            <Rows
              empty="No review items"
              items={snapshot.reviews.map((item) => ({
                id: item.id,
                title: item.title,
                subtitle: `${item.kind} · ${item.proposed_by_agent_id ?? "agent"}`,
                meta: item.status,
                icon: item.risk_level.includes("finance") ? <WalletCards size={18} /> : <ShieldCheck size={18} />,
                tone: item.status === "pending" ? "amber" : item.status === "applied" ? "green" : "neutral"
              }))}
            />
          </Panel>

          <Panel title="Inbox" marker={<Inbox size={18} />}>
            <Rows
              empty="No captures"
              items={snapshot.captures.map((item) => ({
                id: item.id,
                title: item.raw_text || item.capture_kind,
                subtitle: `${item.source_platform} · ${item.sensitivity}`,
                meta: item.status,
                icon: <Inbox size={18} />,
                tone: item.status === "routed" ? "blue" : "neutral"
              }))}
            />
          </Panel>
        </section>

        <section className="content-grid content-grid--bottom" id="runs">
          <Panel title="Runs" marker={<Activity size={18} />}>
            <div className="run-table" role="table" aria-label="Agent runs">
              <div className="run-table-head" role="row">
                <span>Run</span>
                <span>Agent</span>
                <span>Status</span>
                <span>Provider</span>
                <span>Cost</span>
              </div>
              {snapshot.runs.length ? (
                snapshot.runs.map((run) => (
                  <div className="run-table-row" role="row" key={run.id}>
                    <span>{run.id}</span>
                    <span>{run.active_agent_id ?? "orchestrator"}</span>
                    <span>{run.status}</span>
                    <span>{run.provider_used ?? "n/a"}</span>
                    <span>{run.cost_usd ?? 0}</span>
                  </div>
                ))
              ) : (
                <div className="empty-state">
                  <Activity size={22} />
                  <span>No runs</span>
                </div>
              )}
            </div>
          </Panel>

          <Panel title="Providers" marker={<KeyRound size={18} />}>
            <Rows
              empty="No providers"
              items={snapshot.providers.map((provider) => ({
                id: provider.id,
                title: provider.display_name,
                subtitle: provider.type,
                meta: `${provider.keys.filter((key) => key.configured).length}/${provider.keys.length}`,
                icon: <KeyRound size={18} />,
                tone: provider.keys.some((key) => key.configured) ? "green" : "amber"
              }))}
            />
          </Panel>
        </section>

        <section className="content-grid content-grid--bottom" id="audit-log">
          <Panel title="Audit Log" marker={<FileClock size={18} />}>
            <Rows
              empty="No audit events"
              items={snapshot.audit.map((event) => ({
                id: event.id,
                title: event.summary,
                subtitle: `${event.actor_type}:${event.actor_id}`,
                meta: event.event_type,
                icon: <FileClock size={18} />,
                tone: "neutral"
              }))}
            />
          </Panel>

          <Panel title="System Health" marker={<Database size={18} />}>
            <div className="health-list">
              {snapshot.readiness ? (
                snapshot.readiness.checks.map((check) => (
                  <div className="health-row" key={check.name}>
                    {check.ok ? <CheckCircle2 size={17} /> : <CircleAlert size={17} />}
                    <span>{check.name.replaceAll("_", " ")}</span>
                    <StatusPill label={check.ok ? "ok" : "config"} tone={check.ok ? "green" : "amber"} />
                  </div>
                ))
              ) : (
                <div className="empty-state">
                  <Database size={22} />
                  <span>Loading checks</span>
                </div>
              )}
            </div>
          </Panel>
        </section>
      </main>
    </div>
  );
}

type PanelProps = {
  title: string;
  marker: ReactNode;
  children: ReactNode;
};

function Panel({ title, marker, children }: PanelProps) {
  return (
    <section className="panel">
      <div className="panel-header">
        <div className="panel-title">
          <span>{marker}</span>
          <h2>{title}</h2>
        </div>
      </div>
      {children}
    </section>
  );
}

type RowItem = {
  id: string;
  title: string;
  subtitle: string;
  meta: string;
  icon: ReactNode;
  tone: "green" | "amber" | "red" | "blue" | "neutral";
};

function Rows({ items, empty }: { items: RowItem[]; empty: string }) {
  if (!items.length) {
    return (
      <div className="empty-state">
        <Inbox size={22} />
        <span>{empty}</span>
      </div>
    );
  }
  return (
    <div className="review-list">
      {items.map((item) => (
        <article className="review-row" key={item.id}>
          <div className="review-icon">{item.icon}</div>
          <div className="review-main">
            <strong>{item.title}</strong>
            <span>{item.subtitle}</span>
          </div>
          <div className="review-meta">
            <StatusPill label={item.meta} tone={item.tone} />
          </div>
        </article>
      ))}
    </div>
  );
}

type MetricProps = {
  label: string;
  value: string;
  icon: ReactNode;
  tone: "green" | "amber" | "red" | "blue" | "neutral";
};

function Metric({ label, value, icon, tone }: MetricProps) {
  return (
    <div className={`metric metric--${tone}`}>
      <div className="metric-icon">{icon}</div>
      <div>
        <span>{label}</span>
        <strong>{value}</strong>
      </div>
    </div>
  );
}
