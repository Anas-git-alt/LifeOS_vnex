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
  proposed_action_json?: Record<string, unknown>;
  validation_json?: Record<string, unknown>;
  created_at: string;
};

export type RunItem = {
  id: string;
  session_id?: string | null;
  root_capture_id?: string | null;
  active_agent_id?: string | null;
  status: string;
  status_summary?: string | null;
  iteration_cap?: number;
  current_iteration?: number;
  result_json?: Record<string, unknown>;
  provider_used?: string | null;
  model_used?: string | null;
  cost_usd?: number | null;
  created_at: string;
};

export type SessionItem = {
  id: string;
  agent_id: string;
  title?: string | null;
  status: string;
  iteration_cap: number;
  visibility: string;
  source_platform?: string | null;
  external_channel_id?: string | null;
  external_thread_id?: string | null;
  last_run_id?: string | null;
  paused_run_id?: string | null;
  created_at: string;
  updated_at?: string | null;
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
  base_url?: string | null;
  enabled: boolean;
  keys: Array<{ label: string; env: string; configured: boolean }>;
  settings?: Record<string, unknown>;
};

export type AgentItem = {
  id: string;
  display_name: string;
  domain: string;
  role?: string;
  enabled: boolean;
  autonomy_level: string;
  model?: AgentModelEffective | null;
};

export type AgentModelEffective = {
  primary?: { provider?: string | null; model?: string | null };
  secondary?: { provider?: string | null; model?: string | null };
  fallback_allowed?: boolean;
  [key: string]: unknown;
};

export type ToolItem = {
  id: string;
  display_name: string;
  category: string;
  risk_level: string;
  persisted: boolean;
};

export type ToolPermission = {
  id: string;
  agent_id: string;
  tool_id: string;
  effect: string;
  mode: string;
  scopes: Record<string, unknown>;
  requires_approval_when: Record<string, unknown>;
};

export type CaptureRouteResponse = {
  capture: CaptureItem;
  run_id: string;
  route?: {
    agent_id: string;
    domain: string;
    decision: string;
    reason: string;
    confidence: number;
    provider?: string;
    model?: string;
    fallback_used?: boolean;
  };
  review_item_id?: string | null;
  state_change_id?: string | null;
  message: string;
};

export type RunDetail = {
  run: RunItem;
  events: Array<{ id: string; event_type: string; title: string; detail_json: Record<string, unknown>; created_at: string }>;
  handoffs: Array<{ id: string; from_agent_id: string; to_agent_id: string; reason: string; status: string; created_at: string }>;
  tool_calls: Array<{ id: string; agent_id: string; tool_id: string; status: string; input_json: Record<string, unknown>; output_json?: Record<string, unknown> | null; created_at: string }>;
  review_items: ReviewItem[];
  provider_calls: Array<{ id: string; provider_id: string; model: string; status: string; latency_ms?: number | null; error_json?: Record<string, unknown> | null; created_at: string }>;
  audit_events: AuditItem[];
};

export type AskResponse = {
  ok: boolean;
  run_id: string;
  agent_id: string;
  status: string;
  answer: string;
  review_item_id?: string | null;
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

async function sendJson<T>(method: "POST" | "PATCH" | "PUT", path: string, payload?: unknown): Promise<T> {
  const response = await fetch(`${apiUrl}${path}`, {
    method,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload ?? {})
  });
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

export function fetchSessions(): Promise<ApiList<SessionItem>> {
  return getJson<ApiList<SessionItem>>("/api/sessions?limit=20");
}

export function fetchCaptures(): Promise<ApiList<CaptureItem>> {
  return getJson<ApiList<CaptureItem>>("/api/captures?limit=20");
}

export function fetchProviders(): Promise<{ items: ProviderItem[]; agent_models: Record<string, AgentModelEffective>; count: number }> {
  return getJson<{ items: ProviderItem[]; agent_models: Record<string, AgentModelEffective>; count: number }>("/api/providers");
}

export function fetchAudit(): Promise<ApiList<AuditItem>> {
  return getJson<ApiList<AuditItem>>("/api/audit?limit=20");
}

export function createCapture(payload: {
  raw_text: string;
  source_platform?: string;
  capture_kind?: string;
  sensitivity?: string;
  metadata?: Record<string, unknown>;
}): Promise<CaptureRouteResponse> {
  return sendJson<CaptureRouteResponse>("POST", "/api/captures", {
    source_platform: payload.source_platform ?? "web",
    capture_kind: payload.capture_kind ?? "text",
    raw_text: payload.raw_text,
    sensitivity: payload.sensitivity ?? "normal",
    metadata: payload.metadata ?? { owner_authenticated: true }
  });
}

export function decideReview(
  reviewId: string,
  decision: string,
  decisionText?: string,
  decisionPayload: Record<string, unknown> = {}
): Promise<{ ok: boolean; status: string; result: Record<string, unknown> }> {
  return sendJson("POST", `/api/reviews/${encodeURIComponent(reviewId)}/decision`, {
    decision,
    decision_text: decisionText || null,
    decision_payload: decisionPayload,
    source_platform: "web"
  });
}

export function fetchAgents(): Promise<ApiList<AgentItem>> {
  return getJson<ApiList<AgentItem>>("/api/agents");
}

export function patchAgent(agentId: string, payload: { enabled?: boolean; autonomy_level?: string }) {
  return sendJson<{ ok: boolean; agent: AgentItem }>("PATCH", `/api/agents/${encodeURIComponent(agentId)}`, payload);
}

export function patchAgentModel(
  agentId: string,
  payload: {
    primary_provider_id?: string;
    primary_model?: string;
    secondary_provider_id?: string;
    secondary_model?: string;
    fallback_allowed?: boolean;
  }
) {
  return sendJson<{ ok: boolean; model: Record<string, unknown>; effective: AgentModelEffective }>(
    "PATCH",
    `/api/agents/${encodeURIComponent(agentId)}/model`,
    payload
  );
}

export function testProvider(providerId: string): Promise<{ ok: boolean; status: string; log_id?: string }> {
  return sendJson("POST", `/api/providers/${encodeURIComponent(providerId)}/test`);
}

export function fetchTools(): Promise<ApiList<ToolItem>> {
  return getJson<ApiList<ToolItem>>("/api/tools");
}

export function fetchToolPermissions(): Promise<ApiList<ToolPermission>> {
  return getJson<ApiList<ToolPermission>>("/api/tools/permissions");
}

export function upsertToolPermission(payload: {
  agent_id: string;
  tool_id: string;
  effect: string;
  mode: string;
  scopes?: Record<string, unknown>;
  requires_approval_when?: Record<string, unknown>;
}): Promise<ToolPermission> {
  return sendJson("PUT", "/api/tools/permissions", {
    ...payload,
    scopes: payload.scopes ?? {},
    requires_approval_when: payload.requires_approval_when ?? {}
  });
}

export function fetchRun(runId: string): Promise<RunDetail> {
  return getJson<RunDetail>(`/api/runs/${encodeURIComponent(runId)}`);
}

export function askLifeOS(message: string): Promise<AskResponse> {
  return sendJson("POST", "/api/ask", { source_platform: "web", message });
}
