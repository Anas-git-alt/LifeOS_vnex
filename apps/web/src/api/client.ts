export type ApiList<T> = {
  items: T[];
  count: number;
};

export type ReadinessResponse = {
  service: string;
  status: string;
  environment: string;
  timezone: string;
  checks: Array<{ name: string; ok: boolean; detail?: string | null }>;
  provider_key_counts: Record<string, number>;
};

export type ReviewItem = {
  id: string;
  kind: string;
  title: string;
  body_md: string;
  status: string;
  risk_level: string;
  sensitivity: string;
  proposed_by_agent_id?: string | null;
  confidence?: number | null;
  created_at: string;
};

export type RunItem = {
  id: string;
  root_capture_id?: string | null;
  active_agent_id?: string | null;
  status: string;
  status_summary?: string | null;
  provider_used?: string | null;
  model_used?: string | null;
  cost_usd?: number | null;
  created_at: string;
};

export type CaptureItem = {
  id: string;
  source_platform: string;
  capture_kind: string;
  raw_text?: string | null;
  status: string;
  sensitivity: string;
  created_at: string;
};

export type ProviderItem = {
  id: string;
  display_name: string;
  type: string;
  enabled: boolean;
  keys: Array<{ label: string; env: string; configured: boolean }>;
};

export type AuditItem = {
  id: string;
  actor_type: string;
  actor_id: string;
  event_type: string;
  entity_type: string;
  entity_id: string;
  summary: string;
  created_at: string;
};

export type TodayResponse = {
  focus: string;
  counts: {
    pending_reviews: number;
    open_tasks: number;
  };
  recent_captures: CaptureItem[];
  tasks: Array<{
    id: string;
    domain: string;
    item_type: string;
    title: string;
    status: string;
    priority: string;
    due_at?: string | null;
    created_at: string;
  }>;
  finance_entries: Array<{
    id: string;
    local_date: string;
    entry_type: string;
    amount: number;
    currency: string;
    category: string;
    status: string;
  }>;
  prayer_logs: Array<{
    id: string;
    local_date: string;
    prayer: string;
    status: string;
    created_at: string;
  }>;
};

const configuredApiUrl = import.meta.env.VITE_LIFEOS_API_URL as string | undefined;
const apiUrl = configuredApiUrl?.trim() ? configuredApiUrl.replace(/\/$/, "") : "";

async function getJson<T>(path: string): Promise<T> {
  const response = await fetch(`${apiUrl}${path}`);
  if (!response.ok) {
    throw new Error(`${path} failed: ${response.status}`);
  }
  return response.json();
}

export function fetchReadiness(): Promise<ReadinessResponse> {
  return getJson<ReadinessResponse>("/api/readiness");
}

export function fetchToday(): Promise<TodayResponse> {
  return getJson<TodayResponse>("/api/today");
}

export function fetchReviews(): Promise<ApiList<ReviewItem>> {
  return getJson<ApiList<ReviewItem>>("/api/reviews?limit=20");
}

export function fetchRuns(): Promise<ApiList<RunItem>> {
  return getJson<ApiList<RunItem>>("/api/runs?limit=20");
}

export function fetchCaptures(): Promise<ApiList<CaptureItem>> {
  return getJson<ApiList<CaptureItem>>("/api/captures?limit=20");
}

export function fetchProviders(): Promise<{ items: ProviderItem[]; count: number }> {
  return getJson<{ items: ProviderItem[]; count: number }>("/api/providers");
}

export function fetchAudit(): Promise<ApiList<AuditItem>> {
  return getJson<ApiList<AuditItem>>("/api/audit?limit=20");
}
