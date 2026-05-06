--
-- PostgreSQL database dump
--

\restrict uNeES93Dzw3ntqvaAc3OJ2GWTvgEoGDB23STWQKeutcvXASGqb4470iUScAqf2j

-- Dumped from database version 16.13 (Debian 16.13-1.pgdg12+1)
-- Dumped by pg_dump version 16.13 (Debian 16.13-1.pgdg12+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: agent_model_configs; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.agent_model_configs (
    id character varying(64) NOT NULL,
    agent_id character varying(128) NOT NULL,
    primary_provider_id character varying(64),
    primary_model text,
    secondary_provider_id character varying(64),
    secondary_model text,
    fallback_allowed boolean NOT NULL,
    settings_json json NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.agent_model_configs OWNER TO lifeos;

--
-- Name: agent_runs; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.agent_runs (
    id character varying(64) NOT NULL,
    root_capture_id character varying(64),
    initiating_user_id character varying(64),
    orchestrator_agent_id character varying(128) NOT NULL,
    active_agent_id character varying(128),
    status character varying(64) NOT NULL,
    status_summary text,
    provider_used character varying(64),
    model_used character varying(128),
    cost_usd numeric,
    token_usage_json json,
    trace_id character varying(128),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    finished_at timestamp with time zone,
    session_id character varying(64),
    iteration_cap integer DEFAULT 5 NOT NULL,
    current_iteration integer DEFAULT 0 NOT NULL,
    cancel_requested boolean DEFAULT false NOT NULL,
    cancelled_at timestamp with time zone,
    result_json json DEFAULT '{}'::json NOT NULL
);


ALTER TABLE public.agent_runs OWNER TO lifeos;

--
-- Name: agent_sessions; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.agent_sessions (
    id character varying(64) NOT NULL,
    agent_id character varying(128) NOT NULL,
    user_id character varying(64),
    channel_id character varying(64),
    title text,
    status character varying(32) NOT NULL,
    memory_scope json NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    iteration_cap integer DEFAULT 5 NOT NULL,
    visibility character varying(32) DEFAULT 'private'::character varying NOT NULL,
    source_platform character varying(32),
    external_channel_id text,
    external_thread_id text,
    external_message_id text,
    last_run_id character varying(64),
    last_user_correction_id character varying(64),
    paused_run_id character varying(64),
    metadata_json json DEFAULT '{}'::json NOT NULL
);


ALTER TABLE public.agent_sessions OWNER TO lifeos;

--
-- Name: agents; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.agents (
    id character varying(128) NOT NULL,
    display_name text NOT NULL,
    domain character varying(64) NOT NULL,
    registry_uri text NOT NULL,
    enabled boolean NOT NULL,
    autonomy_level character varying(64) NOT NULL,
    version integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.agents OWNER TO lifeos;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO lifeos;

--
-- Name: audit_events; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.audit_events (
    id character varying(64) NOT NULL,
    actor_type character varying(32) NOT NULL,
    actor_id character varying(128) NOT NULL,
    event_type character varying(128) NOT NULL,
    entity_type character varying(128) NOT NULL,
    entity_id character varying(128) NOT NULL,
    summary text NOT NULL,
    before_json json,
    after_json json,
    metadata_json json NOT NULL,
    trace_id character varying(128),
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.audit_events OWNER TO lifeos;

--
-- Name: capture_attachments; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.capture_attachments (
    id character varying(64) NOT NULL,
    capture_id character varying(64) NOT NULL,
    kind character varying(32) NOT NULL,
    original_filename text,
    mime_type text,
    storage_uri text NOT NULL,
    content_hash character varying(128),
    extracted_text_uri text,
    metadata_json json NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.capture_attachments OWNER TO lifeos;

--
-- Name: capture_interpretations; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.capture_interpretations (
    id character varying(64) NOT NULL,
    capture_id character varying(64) NOT NULL,
    agent_id character varying(128) NOT NULL,
    intent_labels json NOT NULL,
    draft_json json NOT NULL,
    confidence numeric NOT NULL,
    missing_context json NOT NULL,
    risk_level character varying(64) NOT NULL,
    status character varying(32) NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.capture_interpretations OWNER TO lifeos;

--
-- Name: channels; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.channels (
    id character varying(64) NOT NULL,
    platform character varying(32) NOT NULL,
    external_channel_id text,
    guild_id text,
    name text,
    purpose character varying(64) NOT NULL,
    default_agent_id character varying(128),
    enabled boolean NOT NULL,
    metadata_json json NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.channels OWNER TO lifeos;

--
-- Name: daily_logs; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.daily_logs (
    id character varying(64) NOT NULL,
    user_id character varying(64),
    local_date character varying(10) NOT NULL,
    domain character varying(64) NOT NULL,
    log_type character varying(64) NOT NULL,
    value_json json NOT NULL,
    source_capture_id character varying(64),
    review_item_id character varying(64),
    confidence numeric,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.daily_logs OWNER TO lifeos;

--
-- Name: dead_letter_items; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.dead_letter_items (
    id character varying(64) NOT NULL,
    source_kind character varying(64) NOT NULL,
    source_id character varying(64),
    reason text NOT NULL,
    payload_json json NOT NULL,
    vault_uri text,
    status character varying(32) NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.dead_letter_items OWNER TO lifeos;

--
-- Name: finance_entries; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.finance_entries (
    id character varying(64) NOT NULL,
    local_date character varying(10) NOT NULL,
    entry_type character varying(32) NOT NULL,
    amount numeric NOT NULL,
    currency character varying(8) NOT NULL,
    category character varying(64) NOT NULL,
    note_md text,
    status character varying(32) NOT NULL,
    source_capture_id character varying(64),
    review_item_id character varying(64),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.finance_entries OWNER TO lifeos;

--
-- Name: handoffs; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.handoffs (
    id character varying(64) NOT NULL,
    parent_run_id character varying(64),
    from_agent_id character varying(128) NOT NULL,
    to_agent_id character varying(128) NOT NULL,
    reason text NOT NULL,
    task_md text NOT NULL,
    context_refs json NOT NULL,
    expected_output_schema json,
    status character varying(32) NOT NULL,
    visibility character varying(32) NOT NULL,
    discord_summary_posted boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    completed_at timestamp with time zone,
    known_context json DEFAULT '[]'::json NOT NULL,
    constraints json DEFAULT '[]'::json NOT NULL,
    result_json json DEFAULT '{}'::json NOT NULL,
    summary_md text,
    risk_level character varying(32) DEFAULT 'normal'::character varying NOT NULL,
    requires_user_visibility boolean DEFAULT true NOT NULL
);


ALTER TABLE public.handoffs OWNER TO lifeos;

--
-- Name: job_runs; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.job_runs (
    id character varying(64) NOT NULL,
    job_id character varying(64) NOT NULL,
    run_id character varying(64),
    status character varying(32) NOT NULL,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    output_summary_md text,
    error_json json,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.job_runs OWNER TO lifeos;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.jobs (
    id character varying(64) NOT NULL,
    name text NOT NULL,
    description_md text,
    schedule_type character varying(32) NOT NULL,
    schedule_json json NOT NULL,
    timezone text NOT NULL,
    target_agent_id character varying(128),
    command_json json NOT NULL,
    approval_policy character varying(64) NOT NULL,
    enabled boolean NOT NULL,
    created_by_user_id character varying(64),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.jobs OWNER TO lifeos;

--
-- Name: life_items; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.life_items (
    id character varying(64) NOT NULL,
    domain character varying(64) NOT NULL,
    item_type character varying(64) NOT NULL,
    title text NOT NULL,
    description_md text,
    status character varying(32) NOT NULL,
    priority character varying(32) NOT NULL,
    due_at timestamp with time zone,
    scheduled_at timestamp with time zone,
    source_capture_id character varying(64),
    approved_state_change_id character varying(64),
    metadata_json json NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.life_items OWNER TO lifeos;

--
-- Name: memory_candidates; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.memory_candidates (
    id character varying(64) NOT NULL,
    source_capture_id character varying(64),
    proposed_by_agent_id character varying(128) NOT NULL,
    candidate_kind character varying(64) NOT NULL,
    statement_md text NOT NULL,
    evidence_refs json NOT NULL,
    confidence numeric NOT NULL,
    sensitivity character varying(32) NOT NULL,
    status character varying(32) NOT NULL,
    review_item_id character varying(64),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.memory_candidates OWNER TO lifeos;

--
-- Name: memory_facts; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.memory_facts (
    id character varying(64) NOT NULL,
    fact_kind character varying(64) NOT NULL,
    statement_md text NOT NULL,
    domain character varying(64) NOT NULL,
    confidence numeric NOT NULL,
    sensitivity character varying(32) NOT NULL,
    status character varying(32) NOT NULL,
    source_candidate_id character varying(64),
    evidence_refs json NOT NULL,
    vault_uri text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.memory_facts OWNER TO lifeos;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.messages (
    id character varying(64) NOT NULL,
    session_id character varying(64),
    run_id character varying(64),
    role character varying(32) NOT NULL,
    content_md text,
    content_json json,
    source_platform character varying(32),
    source_external_message_id text,
    created_at timestamp with time zone NOT NULL,
    source_external_channel_id text,
    source_external_thread_id text,
    metadata_json json DEFAULT '{}'::json NOT NULL
);


ALTER TABLE public.messages OWNER TO lifeos;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.notifications (
    id character varying(64) NOT NULL,
    target_platform character varying(32) NOT NULL,
    target_channel_id character varying(64),
    notification_type character varying(64) NOT NULL,
    title text NOT NULL,
    body_md text NOT NULL,
    status character varying(32) NOT NULL,
    related_run_id character varying(64),
    related_review_item_id character varying(64),
    external_message_id text,
    error_json json,
    created_at timestamp with time zone NOT NULL,
    sent_at timestamp with time zone
);


ALTER TABLE public.notifications OWNER TO lifeos;

--
-- Name: prayer_logs; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.prayer_logs (
    id character varying(64) NOT NULL,
    user_id character varying(64),
    local_date character varying(10) NOT NULL,
    prayer character varying(32) NOT NULL,
    status character varying(32) NOT NULL,
    source_platform character varying(32),
    source_external_message_id text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.prayer_logs OWNER TO lifeos;

--
-- Name: provider_call_logs; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.provider_call_logs (
    id character varying(64) NOT NULL,
    run_id character varying(64),
    agent_id character varying(128),
    provider_id character varying(64) NOT NULL,
    model text NOT NULL,
    key_label text,
    status character varying(32) NOT NULL,
    latency_ms integer,
    input_tokens integer,
    output_tokens integer,
    cost_usd numeric,
    error_json json,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.provider_call_logs OWNER TO lifeos;

--
-- Name: provider_runtime_configs; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.provider_runtime_configs (
    id character varying(64) NOT NULL,
    provider_id character varying(64) NOT NULL,
    display_name text NOT NULL,
    provider_type character varying(64) NOT NULL,
    base_url text,
    enabled boolean NOT NULL,
    key_refs_json json NOT NULL,
    settings_json json NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.provider_runtime_configs OWNER TO lifeos;

--
-- Name: raw_captures; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.raw_captures (
    id character varying(64) NOT NULL,
    source_platform character varying(32) NOT NULL,
    source_external_message_id character varying(255),
    source_thread_id character varying(255),
    capture_kind character varying(32) NOT NULL,
    raw_text text,
    raw_uri text NOT NULL,
    content_hash character varying(128) NOT NULL,
    status character varying(32) NOT NULL,
    sensitivity character varying(32) NOT NULL,
    received_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    source_channel_id character varying(64),
    source_user_id character varying(64)
);


ALTER TABLE public.raw_captures OWNER TO lifeos;

--
-- Name: review_bindings; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.review_bindings (
    id character varying(64) NOT NULL,
    review_item_id character varying(64) NOT NULL,
    platform character varying(32) NOT NULL,
    channel_id character varying(64),
    external_message_id text,
    external_thread_id text,
    card_version integer NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.review_bindings OWNER TO lifeos;

--
-- Name: review_decisions; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.review_decisions (
    id character varying(64) NOT NULL,
    review_item_id character varying(64) NOT NULL,
    user_id character varying(64),
    decision character varying(32) NOT NULL,
    decision_text text,
    decision_payload json NOT NULL,
    source_platform character varying(32) NOT NULL,
    source_external_message_id character varying(255),
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.review_decisions OWNER TO lifeos;

--
-- Name: review_items; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.review_items (
    id character varying(64) NOT NULL,
    kind character varying(64) NOT NULL,
    title text NOT NULL,
    body_md text NOT NULL,
    source_capture_id character varying(64),
    proposed_by_agent_id character varying(128),
    assigned_agent_id character varying(128),
    priority character varying(32) NOT NULL,
    confidence numeric,
    risk_level character varying(64) NOT NULL,
    sensitivity character varying(32) NOT NULL,
    proposed_action_json json NOT NULL,
    validation_json json NOT NULL,
    status character varying(32) NOT NULL,
    expires_at timestamp with time zone,
    snoozed_until timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    source_uri text
);


ALTER TABLE public.review_items OWNER TO lifeos;

--
-- Name: state_changes; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.state_changes (
    id character varying(64) NOT NULL,
    review_item_id character varying(64),
    command_type character varying(128) NOT NULL,
    command_payload json NOT NULL,
    status character varying(32) NOT NULL,
    applied_by character varying(64) NOT NULL,
    before_snapshot_uri text,
    after_snapshot_uri text,
    error_json json,
    created_at timestamp with time zone NOT NULL,
    applied_at timestamp with time zone
);


ALTER TABLE public.state_changes OWNER TO lifeos;

--
-- Name: status_events; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.status_events (
    id character varying(64) NOT NULL,
    run_id character varying(64),
    event_type character varying(128) NOT NULL,
    visibility character varying(32) NOT NULL,
    title text NOT NULL,
    detail_json json NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.status_events OWNER TO lifeos;

--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.system_settings (
    key character varying(128) NOT NULL,
    value_json json NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.system_settings OWNER TO lifeos;

--
-- Name: tool_calls; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.tool_calls (
    id character varying(64) NOT NULL,
    run_id character varying(64),
    agent_id character varying(128) NOT NULL,
    tool_id character varying(128) NOT NULL,
    status character varying(32) NOT NULL,
    input_json json NOT NULL,
    output_json json,
    redacted_input_json json,
    redacted_output_json json,
    approval_review_item_id character varying(64),
    error_json json,
    created_at timestamp with time zone NOT NULL,
    started_at timestamp with time zone,
    finished_at timestamp with time zone
);


ALTER TABLE public.tool_calls OWNER TO lifeos;

--
-- Name: tool_permissions; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.tool_permissions (
    id character varying(64) NOT NULL,
    agent_id character varying(128) NOT NULL,
    tool_id character varying(128) NOT NULL,
    effect character varying(32) NOT NULL,
    mode character varying(32) NOT NULL,
    scopes json NOT NULL,
    requires_approval_when json NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.tool_permissions OWNER TO lifeos;

--
-- Name: tools; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.tools (
    id character varying(128) NOT NULL,
    display_name text NOT NULL,
    category character varying(64) NOT NULL,
    description text,
    risk_level character varying(64) NOT NULL,
    enabled boolean NOT NULL,
    schema_json json NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.tools OWNER TO lifeos;

--
-- Name: users; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.users (
    id character varying(64) NOT NULL,
    display_name text NOT NULL,
    timezone text NOT NULL,
    locale text,
    role character varying(32) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.users OWNER TO lifeos;

--
-- Name: vault_index_entries; Type: TABLE; Schema: public; Owner: lifeos
--

CREATE TABLE public.vault_index_entries (
    id character varying(64) NOT NULL,
    vault_uri text NOT NULL,
    content_hash character varying(128) NOT NULL,
    index_kind character varying(64) NOT NULL,
    domain character varying(64),
    sensitivity character varying(32) NOT NULL,
    indexed_text text,
    metadata_json json NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.vault_index_entries OWNER TO lifeos;

--
-- Data for Name: agent_model_configs; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.agent_model_configs (id, agent_id, primary_provider_id, primary_model, secondary_provider_id, secondary_model, fallback_allowed, settings_json, created_at, updated_at) FROM stdin;
amodel_ea038cfd99e24fbfab42964c66fd48dd	work.generic	openrouter		nvidia_nim	nvidia/nemotron-3-super-120b-a12b	t	{}	2026-05-06 12:50:44.774018+00	2026-05-06 12:52:45.370171+00
amodel_37936753655a417cbec4e4074d5971bd	systems-devops	openrouter	tencent/hy3-preview:free	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	t	{"require_workspace_scope": true}	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:45.840379+00
amodel_6da908b6ce1a49a094b77e823e29005d	research	openrouter	tencent/hy3-preview:free	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	t	{}	2026-05-06 12:50:46.040426+00	2026-05-06 12:52:46.566313+00
amodel_f9eccb2fdaad467d813c8f5d49164968	orchestrator	openrouter	tencent/hy3-preview:free	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	t	{"max_cost_usd_per_run": 0.25}	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:47.475666+00
amodel_389689f0a6824a9c962a8db8be68cba6	memory-curator	openrouter	tencent/hy3-preview:free	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:48.03328+00
amodel_78740a3514074cb2ad41c83d12c9b8bb	health-fitness	openrouter	tencent/hy3-preview:free	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	t	{}	2026-05-06 12:50:49.072881+00	2026-05-06 12:52:48.449114+00
amodel_f6dd846429b7482b8add352e4f1640af	finance	openrouter	tencent/hy3-preview:free	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	t	{}	2026-05-06 12:50:49.657338+00	2026-05-06 12:52:48.871743+00
amodel_9c4ef0e33b774e1a8a077a26ea1abb80	family-commitments	openrouter	tencent/hy3-preview:free	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	t	{}	2026-05-06 12:50:50.073092+00	2026-05-06 12:52:49.313976+00
amodel_af5504813c2141ae816ba87f784f5f59	deen-prayer	openrouter	tencent/hy3-preview:free	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	t	{}	2026-05-06 12:50:50.512553+00	2026-05-06 12:52:49.681991+00
amodel_182a0eb09e83412091f76a17622e2a4a	daily-planner	openrouter	tencent/hy3-preview:free	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:52.701237+00
amodel_1e04e2926de8452e81db5c849e5a8e77	capture-router	openrouter	tencent/hy3-preview:free	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	t	{"max_cost_usd_per_run": 0.05}	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:53.536614+00
amodel_a2f6808d79fd4e25bfb16937be53f0a4	approval-manager	openrouter	tencent/hy3-preview:free	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	t	{"temperature": 0}	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:54.160963+00
\.


--
-- Data for Name: agent_runs; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.agent_runs (id, root_capture_id, initiating_user_id, orchestrator_agent_id, active_agent_id, status, status_summary, provider_used, model_used, cost_usd, token_usage_json, trace_id, created_at, updated_at, finished_at, session_id, iteration_cap, current_iteration, cancel_requested, cancelled_at, result_json) FROM stdin;
run_e74bd4a2fa7446dfb8681f1ff1c95902	cap_8015f24b491c47abb1c379f28522d5dd	\N	orchestrator	memory-curator	waiting_approval	Routed to memory-curator	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_0249f1672bab4839bd259bc7038eaebe	2026-05-06 11:22:29.209022+00	2026-05-06 11:22:29.209022+00	\N	\N	5	0	f	\N	{}
run_4927bce4bff6431299a248cb3fbb4eb3	cap_e68e6163c02a478a9a6a553de44cf0fc	\N	orchestrator	memory-curator	waiting_approval	Routed to memory-curator	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_1d35848ff2ce4cd4b6674229f4888482	2026-05-06 11:23:32.746568+00	2026-05-06 11:23:32.746568+00	\N	\N	5	0	f	\N	{}
run_c3f5d9dfe2a341028ceb17dd598b323c	cap_47cac0ac72864934bbc418e19b4d58a8	\N	orchestrator	work.generic	waiting_approval	Routed to work.generic	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_38d76cf551e44965aed98ef8275a8883	2026-05-06 11:25:24.376647+00	2026-05-06 11:25:24.376647+00	\N	\N	5	0	f	\N	{}
run_e4d19a1c2cd84b799d1dde6ce4d56501	cap_4d62c7dcfedc4907a27f8952f4c5054b	\N	orchestrator	memory-curator	waiting_approval	Routed to memory-curator	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_0adcb1ab08694565a5548d0f3ff12461	2026-05-06 12:02:05.003737+00	2026-05-06 12:02:05.003737+00	\N	\N	5	0	f	\N	{}
run_787fd5a401604cb2b902e17cd28bea33	cap_2f464156a4384621921149d4586807d3	\N	orchestrator	memory-curator	completed	Captured as raw context; no approval needed.	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_bfe6e48e335a41fc923e6d09c31020ed	2026-05-06 12:03:00.707578+00	2026-05-06 12:03:00.707578+00	2026-05-06 12:03:00.707578+00	\N	5	0	f	\N	{}
run_f9e31bcd6aef4773b98f1ef9895e9539	cap_ca43ce4689da485a923a16124f148ebc	\N	orchestrator	finance	waiting_approval	Waiting for approval: Finance entry candidate	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_f641579b51f64db6ae138a567245896e	2026-05-06 12:03:01.634849+00	2026-05-06 12:03:01.634849+00	\N	\N	5	0	f	\N	{}
run_4485b6600ee641c8b6abd6e4c797ebee	cap_a57b14d51ecf4c29af3c014ee2325d24	\N	orchestrator	work.generic	completed	Captured as raw context; no approval needed.	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	0	{"input_tokens": 0, "output_tokens": 0}	trace_d53d8ccb2b864c798c20046d9bca5f07	2026-05-06 14:21:14.05516+00	2026-05-06 14:21:14.05516+00	2026-05-06 14:21:14.05516+00	\N	5	0	f	\N	{}
run_ecf75fb7fc0048e29e8d71a65f430268	cap_db6e45e9c04943bc85bf9d0ee436aeff	\N	orchestrator	memory-curator	completed	Captured as raw context; no approval needed.	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_89989ab81afc4cf48374483eaded1a03	2026-05-06 12:05:06.676937+00	2026-05-06 12:05:06.676937+00	2026-05-06 12:05:06.676937+00	\N	5	0	f	\N	{}
run_4d6dd79f17454ba38768b05f28b68a88	cap_655320e1513b457181a225065ec8cec3	\N	orchestrator	finance	waiting_approval	Waiting for approval: Finance entry candidate	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_7a6ba733ced9433488bc6f58f4ce05d7	2026-05-06 12:05:07.019443+00	2026-05-06 12:05:07.019443+00	\N	\N	5	0	f	\N	{}
run_f603f2b6bde046d4b8d32f2c5357a083	\N	\N	orchestrator	orchestrator	answered	Answered directly	deterministic	ask-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_7bb0fd9cdf72402e9efa13ff1636c3db	2026-05-06 12:07:53.68533+00	2026-05-06 12:07:53.68533+00	2026-05-06 12:07:53.68533+00	\N	5	0	f	\N	{}
run_b7db534588fe46fcb6d5618b46a527f2	\N	\N	orchestrator	orchestrator	answered	Answered directly	deterministic	ask-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_b6bbb8833f9f424c88e24b2991c4a6a8	2026-05-06 12:08:25.589592+00	2026-05-06 12:08:25.589592+00	2026-05-06 12:08:25.589592+00	\N	5	0	f	\N	{}
run_96a2d71b3bc44ad69fe48e8400268030	\N	\N	orchestrator	orchestrator	answered	Answered directly	deterministic	ask-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_11bc06d511d146e0910a969ac22ce09c	2026-05-06 12:08:28.602462+00	2026-05-06 12:08:28.602462+00	2026-05-06 12:08:28.602462+00	\N	5	0	f	\N	{}
run_7292281407f94c0b96216160fb805604	\N	\N	orchestrator	orchestrator	answered	Answered directly	deterministic	ask-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_fa9b0f0d93f148548a22c668f1a94f90	2026-05-06 12:53:17.599593+00	2026-05-06 12:53:17.599593+00	2026-05-06 12:53:17.599593+00	\N	5	0	f	\N	{}
run_92047b1a038942578f8c80933d38bca7	cap_03e86c5ff77b4c6bb3bc0e4251886617	\N	orchestrator	memory-curator	completed	Captured as raw context; no approval needed.	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_ee583b5fb6f4485c9a58efba8720bec3	2026-05-06 12:54:03.396517+00	2026-05-06 12:54:03.396517+00	2026-05-06 12:54:03.396517+00	\N	5	0	f	\N	{}
run_4b45891d111542fcb8958d612ce40a57	\N	\N	orchestrator	systems-devops	completed	Auto-applied life_item.create	\N	\N	0	{"input_tokens": 0, "output_tokens": 0}	trace_ecc389a31fcc4e98bfcfdf494db88173	2026-05-06 14:21:57.162741+00	2026-05-06 14:21:57.178049+00	2026-05-06 14:21:57.178049+00	sess_cdce27c149bd4a59a301488b11878c34	3	2	f	\N	{"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_e3f918e28c9f4dbcbd87631bb4dc6dce", "from_agent_id": "orchestrator", "to_agent_id": "systems-devops", "status": "completed", "summary_md": "systems-devops produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_f02558b5d2ba4b4a97822671d8dcd585", "entity_type": "life_item", "entity_id": "item_816661bc5c954734a99b8446e3c42c38", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_2174062b56084ba283aaa046634abf73"], "status_summary": "Auto-applied life_item.create"}
run_484250866f254c26aca0b18dbeedd0d4	cap_3f2ae3aa5ff54b5999e88b5a5697b393	\N	orchestrator	memory-curator	completed	Captured as raw context; no approval needed.	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_f0ff473e10e64a01831808abb673fb80	2026-05-06 14:21:57.096676+00	2026-05-06 14:21:57.096676+00	2026-05-06 14:21:57.096676+00	\N	5	0	f	\N	{}
run_85a510d22a384fb08a5059e122375ffc	cap_ea5c084b450b45d2ab768ab91562d157	\N	orchestrator	finance	waiting_approval	Waiting for approval: Finance entry candidate	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_70adc9cd780f42d9a8a5f35ddc45bcd1	2026-05-06 14:21:57.111394+00	2026-05-06 14:21:57.111394+00	\N	\N	5	0	f	\N	{}
run_012d4612d2b646289a60b301321711a7	\N	1246911184435675141	orchestrator	daily-planner	completed	Auto-applied life_item.create	\N	\N	0	{"input_tokens": 0, "output_tokens": 0}	trace_e782a3c995eb46dda8ff8d44e7bd4ad7	2026-05-06 14:42:10.03092+00	2026-05-06 14:42:10.052892+00	2026-05-06 14:42:10.052892+00	sess_0ac4fad62b6f44fba991498be03dcf91	5	2	f	\N	{"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_b853ef1fe07c411ba57827dc47556dee", "from_agent_id": "orchestrator", "to_agent_id": "daily-planner", "status": "completed", "summary_md": "daily-planner produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_9a3312324237425895a688c4bd0169ec", "entity_type": "life_item", "entity_id": "item_d3c966e59c9148a9a13a8997ea9a5411", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_86f2e207e8ee488887655678a92c1c78"], "status_summary": "Auto-applied life_item.create"}
run_c34644edcdf04a2794276d98d2bc0cb6	\N	1246911184435675141	orchestrator	orchestrator	completed	Answered directly	\N	\N	0	{"input_tokens": 0, "output_tokens": 0}	trace_34e016796407418fb51275ff5398e0d3	2026-05-06 14:44:15.207134+00	2026-05-06 14:44:15.216057+00	2026-05-06 14:44:15.216057+00	sess_0ac4fad62b6f44fba991498be03dcf91	5	1	f	\N	{"status": "final", "final_message_md": "Hey. I am here.\\n\\nSend a task, note, question, or correction and I will route it through LifeOS.", "what_i_did_md": "- Answered directly from session context.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [], "autonomous_actions": [], "memory_candidates": [], "preference_candidates": [], "audit_refs": [], "status_summary": "Answered directly"}
run_19dbc598042c4f9db05ce6981703698f	cap_454daf5c601d4bd3b68798c4e5483279	\N	orchestrator	memory-curator	completed	Captured as raw context; no approval needed.	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_597617d8ed4d4109a2b28232f61aa927	2026-05-06 14:44:29.820195+00	2026-05-06 14:44:29.820195+00	2026-05-06 14:44:29.820195+00	\N	5	0	f	\N	{}
run_f5274948c59a477186830dc802a2f480	cap_d75ec0874b1a4ac7abcca69658396ac5	\N	orchestrator	finance	waiting_approval	Waiting for approval: Finance entry candidate	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_7614d5242fb245a5977406bd6ca0d149	2026-05-06 14:44:29.846948+00	2026-05-06 14:44:29.846948+00	\N	\N	5	0	f	\N	{}
run_b5304a2705ad4185906215a0ada98218	cap_93390c37a92b44d697ed8bbaefbeaf56	\N	orchestrator	memory-curator	completed	Captured as raw context; no approval needed.	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_8a0acfda33ea4f96b67f0168e655bd9d	2026-05-06 14:46:57.292724+00	2026-05-06 14:46:57.292724+00	2026-05-06 14:46:57.292724+00	\N	5	0	f	\N	{}
run_5be33c728b6f445b8270d9c7591dffd4	\N	\N	orchestrator	systems-devops	completed	Auto-applied life_item.create	\N	\N	0	{"input_tokens": 0, "output_tokens": 0}	trace_baf1ff555c564ae6ac07f05555a8cfab	2026-05-06 14:44:29.895792+00	2026-05-06 14:44:29.914161+00	2026-05-06 14:44:29.914161+00	sess_cdce27c149bd4a59a301488b11878c34	3	2	f	\N	{"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_6831a95626ef4c54b50961debf6b5573", "from_agent_id": "orchestrator", "to_agent_id": "systems-devops", "status": "completed", "summary_md": "systems-devops produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_228e886e0ca5499091af8f3a43e969d7", "entity_type": "life_item", "entity_id": "item_bbefd78c695c4821902b1ab5e6ba3364", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_1be0401f90bf484eaa3c393ff1ba598f"], "status_summary": "Auto-applied life_item.create"}
run_302229626b4a49a3abd02392c31173e3	\N	1246911184435675141	orchestrator	orchestrator	completed	Answered directly	\N	\N	0	{"input_tokens": 0, "output_tokens": 0}	trace_559e0c5432e94fb69a7d4a6e99aee8ab	2026-05-06 14:46:45.042217+00	2026-05-06 14:46:45.052186+00	2026-05-06 14:46:45.052186+00	sess_0ac4fad62b6f44fba991498be03dcf91	5	1	f	\N	{"status": "final", "final_message_md": "Hey. I am here.\\n\\nSend a task, note, question, or correction and I will route it through LifeOS.", "what_i_did_md": "- Answered directly from session context.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [], "autonomous_actions": [], "memory_candidates": [], "preference_candidates": [], "audit_refs": [], "status_summary": "Answered directly"}
run_0bf80e9c8ca347a3bf750b152ae62104	\N	\N	orchestrator	systems-devops	completed	Auto-applied life_item.create	\N	\N	0	{"input_tokens": 0, "output_tokens": 0}	trace_1075e11f6ee043bab2b8574a01dac1bd	2026-05-06 14:46:57.369192+00	2026-05-06 14:46:57.384875+00	2026-05-06 14:46:57.384875+00	sess_cdce27c149bd4a59a301488b11878c34	3	2	f	\N	{"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_fb75f1ed6649422082f873725e2a8724", "from_agent_id": "orchestrator", "to_agent_id": "systems-devops", "status": "completed", "summary_md": "systems-devops produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_206baced4e1c4bb7994738da59812a36", "entity_type": "life_item", "entity_id": "item_17ba033bb47544679227adbb85a0fc6f", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_125555355a824ce6ba967252544f3572"], "status_summary": "Auto-applied life_item.create"}
run_fbb633d89ecd42939345b18887ef347c	cap_23a9118878c64d9f90f05d8b985d730a	\N	orchestrator	finance	waiting_approval	Waiting for approval: Finance entry candidate	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_b8121a838d5e4ca6913fe42510901bac	2026-05-06 14:46:57.318947+00	2026-05-06 14:46:57.318947+00	\N	\N	5	0	f	\N	{}
run_338e8a46e18447a1b16f10d86c44469d	cap_7bd059b3793e459f9af461b29c254e6f	\N	orchestrator	memory-curator	completed	Captured as raw context; no approval needed.	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_30d3b245d50f4278b862c707fb142d6f	2026-05-06 16:36:58.882798+00	2026-05-06 16:36:58.882798+00	2026-05-06 16:36:58.882798+00	\N	5	0	f	\N	{}
run_b4c2536243be496da016b4bb8cb57f6d	cap_1815c12243574fd185773ba74a944a50	\N	orchestrator	finance	waiting_approval	Waiting for approval: Finance entry candidate	deterministic	capture-router-v1	0	{"input_tokens": 0, "output_tokens": 0}	trace_75c8afb3ce0742bda16b556ea0c1183c	2026-05-06 16:36:58.910534+00	2026-05-06 16:36:58.910534+00	\N	\N	5	0	f	\N	{}
run_659f6b5faf754c14a5a9b65d85491860	\N	\N	orchestrator	systems-devops	completed	Auto-applied life_item.create	\N	\N	0	{"input_tokens": 0, "output_tokens": 0}	trace_ef108a9b90134d0b973cec9b54a975e2	2026-05-06 16:36:58.989572+00	2026-05-06 16:36:59.008145+00	2026-05-06 16:36:59.008145+00	sess_cdce27c149bd4a59a301488b11878c34	3	2	f	\N	{"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_97d5c650d3b34e7fbeadc22eaae6ba2a", "from_agent_id": "orchestrator", "to_agent_id": "systems-devops", "status": "completed", "summary_md": "systems-devops produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_c74032dd191547628f8f491b643f6f91", "entity_type": "life_item", "entity_id": "item_a96511a15683433395b49e3be2ea76b9", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_52c41d69e0fb4ccfb1a469ea563764cf"], "status_summary": "Auto-applied life_item.create"}
run_3693a49a498f4617a5ce949dcbf62c37	cap_9e381bbd92c04332ac4759c958cfbe0b	\N	orchestrator	work.generic	completed	Captured as raw context; no approval needed.	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	0	{"input_tokens": 0, "output_tokens": 0}	trace_09add1ae0aaa43f1b17058bdd83f8d72	2026-05-06 16:41:20.355501+00	2026-05-06 16:41:20.355501+00	2026-05-06 16:41:20.355501+00	\N	5	0	f	\N	{}
\.


--
-- Data for Name: agent_sessions; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.agent_sessions (id, agent_id, user_id, channel_id, title, status, memory_scope, created_at, updated_at, iteration_cap, visibility, source_platform, external_channel_id, external_thread_id, external_message_id, last_run_id, last_user_correction_id, paused_run_id, metadata_json) FROM stdin;
sess_0ac4fad62b6f44fba991498be03dcf91	orchestrator	1246911184435675141	\N	LifeOS session	active	{}	2026-05-06 14:42:10.021923+00	2026-05-06 14:46:45.052186+00	5	private	discord	1501484172026314834	1500000000000000000	\N	run_302229626b4a49a3abd02392c31173e3	\N	\N	{"owner_authenticated": true, "probe": "discord-fk-fix"}
sess_cdce27c149bd4a59a301488b11878c34	orchestrator	\N	\N	LifeOS session	active	{}	2026-05-06 14:21:57.160417+00	2026-05-06 16:36:59.008145+00	3	private	web	smoke-test	\N	\N	run_659f6b5faf754c14a5a9b65d85491860	\N	\N	{"owner_authenticated": true, "smoke_test": true}
\.


--
-- Data for Name: agents; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.agents (id, display_name, domain, registry_uri, enabled, autonomy_level, version, created_at, updated_at) FROM stdin;
finance	Finance Agent	finance	configs/agents/finance.yaml	t	safe	5	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:48.853847+00
family-commitments	Family/Personal Commitments Agent	family	configs/agents/family-commitments.yaml	t	safe	4	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:49.293973+00
deen-prayer	Deen/Prayer Agent	deen	configs/agents/deen-prayer.yaml	t	safe	6	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:49.663746+00
daily-planner	Daily Planner	planning	configs/agents/daily-planner.yaml	t	safe	7	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:52.681567+00
capture-router	Capture Router	system	configs/agents/capture-router.yaml	t	safe	6	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:53.517871+00
approval-manager	Approval Manager	system	configs/agents/approval-manager.yaml	t	safe	7	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:54.141959+00
work.generic	Generic Work Agent	work	configs/agents/work-generic.yaml	t	safe	4	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:45.347919+00
systems-devops	Systems/DevOps Agent	system	configs/agents/systems-devops.yaml	t	safe	5	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:45.81963+00
research	Research Agent	research	configs/agents/research.yaml	t	safe	5	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:46.547578+00
orchestrator	Orchestrator Agent	system	configs/agents/orchestrator.yaml	t	safe	5	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:47.454874+00
memory-curator	Memory Curator	memory	configs/agents/memory-curator.yaml	t	safe	5	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:48.014192+00
health-fitness	Health/Fitness Agent	health	configs/agents/health-fitness.yaml	t	safe	5	2026-05-06 12:02:44.599139+00	2026-05-06 12:52:48.430207+00
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.alembic_version (version_num) FROM stdin;
0004_agent_sessions_runtime
\.


--
-- Data for Name: audit_events; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.audit_events (id, actor_type, actor_id, event_type, entity_type, entity_id, summary, before_json, after_json, metadata_json, trace_id, created_at) FROM stdin;
audit_14f40a42aff84fd0a474341be3513538	system	capture-router	capture.routed	raw_capture	cap_8015f24b491c47abb1c379f28522d5dd	Capture routed to memory-curator and promoted to review.	null	{"review_item_id": "rev_6e4c341e3b2f4028aa1e93ee4964b523", "run_id": "run_e74bd4a2fa7446dfb8681f1ff1c95902"}	{}	trace_0249f1672bab4839bd259bc7038eaebe	2026-05-06 11:22:29.22398+00
audit_9806177d04b748e6b017236e07ede51c	system	capture-router	capture.routed	raw_capture	cap_e68e6163c02a478a9a6a553de44cf0fc	Capture routed to memory-curator and promoted to review.	null	{"review_item_id": "rev_03a930b12fc04d35be6b04808654c1b9", "run_id": "run_4927bce4bff6431299a248cb3fbb4eb3"}	{}	trace_1d35848ff2ce4cd4b6674229f4888482	2026-05-06 11:23:32.754351+00
audit_19a771e52a204715bc39092edabcb144	system	capture-router	capture.routed	raw_capture	cap_47cac0ac72864934bbc418e19b4d58a8	Capture routed to work.generic and promoted to review.	null	{"review_item_id": "rev_594064f782564be099ad83986664a389", "run_id": "run_c3f5d9dfe2a341028ceb17dd598b323c"}	{}	trace_38d76cf551e44965aed98ef8275a8883	2026-05-06 11:25:24.38448+00
audit_83d02efca22443179220c3f435aa3ccb	system	capture-router	capture.routed	raw_capture	cap_4d62c7dcfedc4907a27f8952f4c5054b	Capture routed to memory-curator and promoted to review.	null	{"review_item_id": "rev_557dfe60ff294f5d84b7328dd6f24892", "run_id": "run_e4d19a1c2cd84b799d1dde6ce4d56501"}	{}	trace_0adcb1ab08694565a5548d0f3ff12461	2026-05-06 12:02:05.009795+00
audit_c7ab3504f2264963bdf37f76f053834a	agent	memory-curator	capture.policy_routed	raw_capture	cap_2f464156a4384621921149d4586807d3	Capture routed to memory-curator; policy=raw_only.	null	{"review_item_id": null, "run_id": "run_787fd5a401604cb2b902e17cd28bea33", "state_change_id": null, "policy": {"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "provider_call_log_id": "pcall_a4447a952c7a4ca7b72b49bbf3026876", "fallback_used": true, "fallback_reason": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}"}}	{}	trace_bfe6e48e335a41fc923e6d09c31020ed	2026-05-06 12:03:01.622458+00
audit_d3a1cb7b1365466cb016a739b93b4d08	agent	finance	capture.policy_routed	raw_capture	cap_ca43ce4689da485a923a16124f148ebc	Capture routed to finance; policy=review_required.	null	{"review_item_id": "rev_aeeef449e2f44a3896a93b29270dc4e1", "run_id": "run_f9e31bcd6aef4773b98f1ef9895e9539", "state_change_id": null, "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "provider_call_log_id": "pcall_c15949a50dc04246a3bc2b5c2928afc7", "fallback_used": true, "fallback_reason": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}"}}	{}	trace_f641579b51f64db6ae138a567245896e	2026-05-06 12:03:01.787466+00
audit_f59d58b1be3d4364b04e43bcc778f969	user	owner	review.decision_received	review_item	rev_aeeef449e2f44a3896a93b29270dc4e1	Review decision: reject	{"id": "rev_aeeef449e2f44a3896a93b29270dc4e1", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_ca43ce4689da485a923a16124f148ebc", "source_uri": "raw/web/2026/05/06/we_cap_ca43ce4689da485a923a16124f148ebc.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ca43ce4689da485a923a16124f148ebc"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "pending", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:03:01.634849+00:00", "updated_at": "2026-05-06T12:03:01.634849+00:00"}	{"id": "rev_aeeef449e2f44a3896a93b29270dc4e1", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_ca43ce4689da485a923a16124f148ebc", "source_uri": "raw/web/2026/05/06/we_cap_ca43ce4689da485a923a16124f148ebc.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ca43ce4689da485a923a16124f148ebc"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:03:01.634849+00:00", "updated_at": "2026-05-06T12:03:01.800886+00:00"}	{"decision_id": "dec_1ffd8ab2a0c848408d4ee615d5e03361"}	\N	2026-05-06 12:03:01.801136+00
audit_296563383e1048ac8f58e202786ed50d	agent	memory-curator	capture.policy_routed	raw_capture	cap_db6e45e9c04943bc85bf9d0ee436aeff	Capture routed to memory-curator; policy=raw_only.	null	{"review_item_id": null, "run_id": "run_ecf75fb7fc0048e29e8d71a65f430268", "state_change_id": null, "policy": {"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "provider_call_log_id": "pcall_b8fc3942fc874c478b2ce52133f546fd", "fallback_used": true, "fallback_reason": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}"}}	{}	trace_89989ab81afc4cf48374483eaded1a03	2026-05-06 12:05:07.007872+00
audit_2f475e082bd648428b3d8bbe1f652447	agent	finance	capture.policy_routed	raw_capture	cap_655320e1513b457181a225065ec8cec3	Capture routed to finance; policy=review_required.	null	{"review_item_id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "run_id": "run_4d6dd79f17454ba38768b05f28b68a88", "state_change_id": null, "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "provider_call_log_id": "pcall_8b946aba46654057a3c56d8a2dd22af5", "fallback_used": true, "fallback_reason": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}"}}	{}	trace_7a6ba733ced9433488bc6f58f4ce05d7	2026-05-06 12:05:07.173152+00
audit_56f2f5bcc31e4e7983c2a49ad2492239	system	provider-router	provider.tested	provider	codex_oauth	Provider codex_oauth test status: configured	null	{"status": "configured"}	{}	\N	2026-05-06 12:06:37.173645+00
audit_0f0b1f989f23430eb8a0a9170437783a	user	owner	ask_lifeos.created	agent_run	run_f603f2b6bde046d4b8d32f2c5357a083	Ask LifeOS: What should i do?	null	{"answer": "I can answer from approved state or create review-gated proposals. No state mutation needed.", "review_item_id": null}	{}	trace_7bb0fd9cdf72402e9efa13ff1636c3db	2026-05-06 12:07:53.687494+00
audit_d7a0ad4716374a208712b2e86fc2ee8a	user	owner	agent.updated	agent	research	Updated agent research	{"id": "research", "display_name": "Research Agent", "domain": "research", "registry_uri": "configs/agents/research.yaml", "enabled": true, "autonomy_level": "review_gated", "version": 1, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "research", "display_name": "Research Agent", "domain": "research", "registry_uri": "configs/agents/research.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:46.021870+00:00"}	{}	\N	2026-05-06 12:50:46.021937+00
audit_d1705059a38c412295307f13d164a1ef	user	owner	review.decision_received	review_item	rev_1da6d0d84419441ebc38a0b63b5b4161	Review decision: reject	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "pending", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:05:07.019443+00:00"}	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:05:07.187180+00:00"}	{"decision_id": "dec_3bce280e6890401688d134e5a10739e7"}	\N	2026-05-06 12:05:07.18743+00
audit_cae6e904b5984a5e92d51dd542859295	user	owner	review.decision_received	review_item	rev_6e4c341e3b2f4028aa1e93ee4964b523	Review decision: reject	{"id": "rev_6e4c341e3b2f4028aa1e93ee4964b523", "kind": "memory", "title": "Memory candidate", "body_md": "Possible durable memory candidate:\\n\\n> /start", "source_capture_id": "cap_8015f24b491c47abb1c379f28522d5dd", "source_uri": "raw/telegram/2026/05/06/te_cap_8015f24b491c47abb1c379f28522d5dd.md", "proposed_by_agent_id": "memory-curator", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.62, "risk_level": "durable_memory_write", "sensitivity": "normal", "proposed_action_json": {"command_type": "memory_fact.create", "risk_level": "durable_memory_write", "payload": {"fact_kind": "note", "domain": "planning", "statement_md": "/start", "confidence": 0.62, "sensitivity": "normal", "evidence_refs": [{"kind": "raw_capture", "id": "cap_8015f24b491c47abb1c379f28522d5dd"}]}}, "validation_json": {"missing_context": []}, "status": "pending", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T11:22:29.209022+00:00", "updated_at": "2026-05-06T11:22:29.209022+00:00"}	{"id": "rev_6e4c341e3b2f4028aa1e93ee4964b523", "kind": "memory", "title": "Memory candidate", "body_md": "Possible durable memory candidate:\\n\\n> /start", "source_capture_id": "cap_8015f24b491c47abb1c379f28522d5dd", "source_uri": "raw/telegram/2026/05/06/te_cap_8015f24b491c47abb1c379f28522d5dd.md", "proposed_by_agent_id": "memory-curator", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.62, "risk_level": "durable_memory_write", "sensitivity": "normal", "proposed_action_json": {"command_type": "memory_fact.create", "risk_level": "durable_memory_write", "payload": {"fact_kind": "note", "domain": "planning", "statement_md": "/start", "confidence": 0.62, "sensitivity": "normal", "evidence_refs": [{"kind": "raw_capture", "id": "cap_8015f24b491c47abb1c379f28522d5dd"}]}}, "validation_json": {"missing_context": []}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T11:22:29.209022+00:00", "updated_at": "2026-05-06T12:07:05.069161+00:00"}	{"decision_id": "dec_1662bd77950446d88f3e27671f1eaf3e"}	\N	2026-05-06 12:07:05.069415+00
audit_3be33802ab994cb1972485d2eee2963e	user	owner	review.decision_received	review_item	rev_03a930b12fc04d35be6b04808654c1b9	Review decision: reject	{"id": "rev_03a930b12fc04d35be6b04808654c1b9", "kind": "memory", "title": "Memory candidate", "body_md": "Possible durable memory candidate:\\n\\n> Hello", "source_capture_id": "cap_e68e6163c02a478a9a6a553de44cf0fc", "source_uri": "raw/telegram/2026/05/06/te_cap_e68e6163c02a478a9a6a553de44cf0fc.md", "proposed_by_agent_id": "memory-curator", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.62, "risk_level": "durable_memory_write", "sensitivity": "normal", "proposed_action_json": {"command_type": "memory_fact.create", "risk_level": "durable_memory_write", "payload": {"fact_kind": "note", "domain": "planning", "statement_md": "Hello", "confidence": 0.62, "sensitivity": "normal", "evidence_refs": [{"kind": "raw_capture", "id": "cap_e68e6163c02a478a9a6a553de44cf0fc"}]}}, "validation_json": {"missing_context": []}, "status": "pending", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T11:23:32.746568+00:00", "updated_at": "2026-05-06T11:23:32.746568+00:00"}	{"id": "rev_03a930b12fc04d35be6b04808654c1b9", "kind": "memory", "title": "Memory candidate", "body_md": "Possible durable memory candidate:\\n\\n> Hello", "source_capture_id": "cap_e68e6163c02a478a9a6a553de44cf0fc", "source_uri": "raw/telegram/2026/05/06/te_cap_e68e6163c02a478a9a6a553de44cf0fc.md", "proposed_by_agent_id": "memory-curator", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.62, "risk_level": "durable_memory_write", "sensitivity": "normal", "proposed_action_json": {"command_type": "memory_fact.create", "risk_level": "durable_memory_write", "payload": {"fact_kind": "note", "domain": "planning", "statement_md": "Hello", "confidence": 0.62, "sensitivity": "normal", "evidence_refs": [{"kind": "raw_capture", "id": "cap_e68e6163c02a478a9a6a553de44cf0fc"}]}}, "validation_json": {"missing_context": []}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T11:23:32.746568+00:00", "updated_at": "2026-05-06T12:07:07.829504+00:00"}	{"decision_id": "dec_3e0bbf00ce0e4f36b966aff8ba95f5fd"}	\N	2026-05-06 12:07:07.829781+00
audit_b182f9fed5ea40039c7ad16aa85c37c2	user	owner	review.decision_received	review_item	rev_594064f782564be099ad83986664a389	Review decision: reject	{"id": "rev_594064f782564be099ad83986664a389", "kind": "work", "title": "Work task candidate", "body_md": "AI draft from capture:\\n\\n> I need to finish working on that subject proposal and talk to the teacher about it\\n\\nProposed work task: **I need to finish working on that subject proposal and talk to the teacher about**", "source_capture_id": "cap_47cac0ac72864934bbc418e19b4d58a8", "source_uri": "raw/telegram/2026/05/06/te_cap_47cac0ac72864934bbc418e19b4d58a8.md", "proposed_by_agent_id": "work.generic", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.76, "risk_level": "durable_state_mutation", "sensitivity": "normal", "proposed_action_json": {"command_type": "life_item.create", "risk_level": "durable_state_mutation", "payload": {"domain": "work", "item_type": "task", "title": "I need to finish working on that subject proposal and talk to the teacher about", "description_md": "I need to finish working on that subject proposal and talk to the teacher about it", "priority": "normal", "status": "open", "source_capture_id": "cap_47cac0ac72864934bbc418e19b4d58a8"}}, "validation_json": {"missing_context": []}, "status": "pending", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T11:25:24.376647+00:00", "updated_at": "2026-05-06T11:25:24.376647+00:00"}	{"id": "rev_594064f782564be099ad83986664a389", "kind": "work", "title": "Work task candidate", "body_md": "AI draft from capture:\\n\\n> I need to finish working on that subject proposal and talk to the teacher about it\\n\\nProposed work task: **I need to finish working on that subject proposal and talk to the teacher about**", "source_capture_id": "cap_47cac0ac72864934bbc418e19b4d58a8", "source_uri": "raw/telegram/2026/05/06/te_cap_47cac0ac72864934bbc418e19b4d58a8.md", "proposed_by_agent_id": "work.generic", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.76, "risk_level": "durable_state_mutation", "sensitivity": "normal", "proposed_action_json": {"command_type": "life_item.create", "risk_level": "durable_state_mutation", "payload": {"domain": "work", "item_type": "task", "title": "I need to finish working on that subject proposal and talk to the teacher about", "description_md": "I need to finish working on that subject proposal and talk to the teacher about it", "priority": "normal", "status": "open", "source_capture_id": "cap_47cac0ac72864934bbc418e19b4d58a8"}}, "validation_json": {"missing_context": []}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T11:25:24.376647+00:00", "updated_at": "2026-05-06T12:07:13.583001+00:00"}	{"decision_id": "dec_8a90a256e7784ac7a8c08d6c77c10fd9"}	\N	2026-05-06 12:07:13.583241+00
audit_b4bb69273a7344efbe76dd144df58f80	user	owner	review.decision_received	review_item	rev_557dfe60ff294f5d84b7328dd6f24892	Review decision: reject	{"id": "rev_557dfe60ff294f5d84b7328dd6f24892", "kind": "memory", "title": "Memory candidate", "body_md": "Possible durable memory candidate:\\n\\n> random thought: smoke test raw note", "source_capture_id": "cap_4d62c7dcfedc4907a27f8952f4c5054b", "source_uri": "raw/web/2026/05/06/we_cap_4d62c7dcfedc4907a27f8952f4c5054b.md", "proposed_by_agent_id": "memory-curator", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.62, "risk_level": "durable_memory_write", "sensitivity": "normal", "proposed_action_json": {"command_type": "memory_fact.create", "risk_level": "durable_memory_write", "payload": {"fact_kind": "note", "domain": "planning", "statement_md": "random thought: smoke test raw note", "confidence": 0.62, "sensitivity": "normal", "evidence_refs": [{"kind": "raw_capture", "id": "cap_4d62c7dcfedc4907a27f8952f4c5054b"}]}}, "validation_json": {"missing_context": []}, "status": "pending", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:02:05.003737+00:00", "updated_at": "2026-05-06T12:02:05.003737+00:00"}	{"id": "rev_557dfe60ff294f5d84b7328dd6f24892", "kind": "memory", "title": "Memory candidate", "body_md": "Possible durable memory candidate:\\n\\n> random thought: smoke test raw note", "source_capture_id": "cap_4d62c7dcfedc4907a27f8952f4c5054b", "source_uri": "raw/web/2026/05/06/we_cap_4d62c7dcfedc4907a27f8952f4c5054b.md", "proposed_by_agent_id": "memory-curator", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.62, "risk_level": "durable_memory_write", "sensitivity": "normal", "proposed_action_json": {"command_type": "memory_fact.create", "risk_level": "durable_memory_write", "payload": {"fact_kind": "note", "domain": "planning", "statement_md": "random thought: smoke test raw note", "confidence": 0.62, "sensitivity": "normal", "evidence_refs": [{"kind": "raw_capture", "id": "cap_4d62c7dcfedc4907a27f8952f4c5054b"}]}}, "validation_json": {"missing_context": []}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:02:05.003737+00:00", "updated_at": "2026-05-06T12:07:16.997925+00:00"}	{"decision_id": "dec_e63441ac09eb42b5a820748d70e7277f"}	\N	2026-05-06 12:07:16.998212+00
audit_3cf6af0c70ca462bb618dc56b187aa31	user	owner	ask_lifeos.created	agent_run	run_b7db534588fe46fcb6d5618b46a527f2	Ask LifeOS: hello	null	{"answer": "I can answer from approved state or create review-gated proposals. No state mutation needed.", "review_item_id": null}	{}	trace_b6bbb8833f9f424c88e24b2991c4a6a8	2026-05-06 12:08:25.591761+00
audit_c0ed5e1afb654da7815364d26f0a3ce2	user	owner	review.decision_received	review_item	rev_aeeef449e2f44a3896a93b29270dc4e1	Review decision: reject	{"id": "rev_aeeef449e2f44a3896a93b29270dc4e1", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_ca43ce4689da485a923a16124f148ebc", "source_uri": "raw/web/2026/05/06/we_cap_ca43ce4689da485a923a16124f148ebc.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ca43ce4689da485a923a16124f148ebc"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:03:01.634849+00:00", "updated_at": "2026-05-06T12:03:01.800886+00:00"}	{"id": "rev_aeeef449e2f44a3896a93b29270dc4e1", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_ca43ce4689da485a923a16124f148ebc", "source_uri": "raw/web/2026/05/06/we_cap_ca43ce4689da485a923a16124f148ebc.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ca43ce4689da485a923a16124f148ebc"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:03:01.634849+00:00", "updated_at": "2026-05-06T12:07:18.452418+00:00"}	{"decision_id": "dec_fc2ecc0ad2194b999839ed744fa59602"}	\N	2026-05-06 12:07:18.452664+00
audit_8dbfb2d94ee6447381b96e4a27e627e1	user	owner	review.decision_received	review_item	rev_1da6d0d84419441ebc38a0b63b5b4161	Review decision: reject	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:05:07.187180+00:00"}	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:07:19.470040+00:00"}	{"decision_id": "dec_dca39c1211744e2fadfbce2d5980a650"}	\N	2026-05-06 12:07:19.470331+00
audit_85d9a579bc8a4c30b0decd21817ee637	user	owner	ask_lifeos.created	agent_run	run_96a2d71b3bc44ad69fe48e8400268030	Ask LifeOS: hello	null	{"answer": "I can answer from approved state or create review-gated proposals. No state mutation needed.", "review_item_id": null}	{}	trace_11bc06d511d146e0910a969ac22ce09c	2026-05-06 12:08:28.605026+00
audit_7c64d282f83d47818120fffa8fa20bf1	user	owner	agent.updated	agent	work.generic	Updated agent work.generic	{"id": "work.generic", "display_name": "Generic Work Agent", "domain": "work", "registry_uri": "configs/agents/work-generic.yaml", "enabled": true, "autonomy_level": "review_gated", "version": 1, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "work.generic", "display_name": "Generic Work Agent", "domain": "work", "registry_uri": "configs/agents/work-generic.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:44.749836+00:00"}	{}	\N	2026-05-06 12:50:44.749944+00
audit_41606432423c4cf4b8b9714cde461a3b	user	owner	agent_model.updated	agent_model_config	amodel_ea038cfd99e24fbfab42964c66fd48dd	Updated model config for work.generic	{"id": "amodel_ea038cfd99e24fbfab42964c66fd48dd", "agent_id": "work.generic", "primary_provider_id": null, "primary_model": null, "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:44.774018+00:00", "updated_at": "2026-05-06T12:50:44.774018+00:00"}	{"id": "amodel_ea038cfd99e24fbfab42964c66fd48dd", "agent_id": "work.generic", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:44.774018+00:00", "updated_at": "2026-05-06T12:50:44.774018+00:00"}	{}	\N	2026-05-06 12:50:44.776495+00
audit_4fe77c2bbe0843c4a7f1a83e8e733bdb	user	owner	agent.updated	agent	systems-devops	Updated agent systems-devops	{"id": "systems-devops", "display_name": "Systems/DevOps Agent", "domain": "system", "registry_uri": "configs/agents/systems-devops.yaml", "enabled": true, "autonomy_level": "manual", "version": 1, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "systems-devops", "display_name": "Systems/DevOps Agent", "domain": "system", "registry_uri": "configs/agents/systems-devops.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:45.310618+00:00"}	{}	\N	2026-05-06 12:50:45.310691+00
audit_c4554e8dd5f84214b0a5de7dda8bdc78	user	owner	agent_model.updated	agent_model_config	amodel_37936753655a417cbec4e4074d5971bd	Updated model config for systems-devops	{"id": "amodel_37936753655a417cbec4e4074d5971bd", "agent_id": "systems-devops", "primary_provider_id": "codex_oauth", "primary_model": "codex-default", "secondary_provider_id": "openrouter", "secondary_model": "openai/gpt-5.2", "fallback_allowed": true, "settings_json": {"require_workspace_scope": true}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "amodel_37936753655a417cbec4e4074d5971bd", "agent_id": "systems-devops", "primary_provider_id": "codex_oauth", "primary_model": "codex-default", "secondary_provider_id": "openrouter", "secondary_model": "openai/gpt-5.2", "fallback_allowed": true, "settings_json": {"require_workspace_scope": true}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:45.332330+00:00"}	{}	\N	2026-05-06 12:50:45.334593+00
audit_f633132ed44e4f528d42762c49749125	user	owner	agent.updated	agent	finance	Updated agent finance	{"id": "finance", "display_name": "Finance Agent", "domain": "finance", "registry_uri": "configs/agents/finance.yaml", "enabled": true, "autonomy_level": "review_gated", "version": 1, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "finance", "display_name": "Finance Agent", "domain": "finance", "registry_uri": "configs/agents/finance.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:49.637988+00:00"}	{}	\N	2026-05-06 12:50:49.638051+00
audit_275689998d6345efa77f64f56b850d11	user	owner	agent_model.updated	agent_model_config	amodel_6da908b6ce1a49a094b77e823e29005d	Updated model config for research	{"id": "amodel_6da908b6ce1a49a094b77e823e29005d", "agent_id": "research", "primary_provider_id": null, "primary_model": null, "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:46.040426+00:00", "updated_at": "2026-05-06T12:50:46.040426+00:00"}	{"id": "amodel_6da908b6ce1a49a094b77e823e29005d", "agent_id": "research", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:46.040426+00:00", "updated_at": "2026-05-06T12:50:46.040426+00:00"}	{}	\N	2026-05-06 12:50:46.042801+00
audit_fde39b3a8342423bae22ff98509966fc	user	owner	agent.updated	agent	orchestrator	Updated agent orchestrator	{"id": "orchestrator", "display_name": "Orchestrator Agent", "domain": "system", "registry_uri": "configs/agents/orchestrator.yaml", "enabled": true, "autonomy_level": "review_gated", "version": 1, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "orchestrator", "display_name": "Orchestrator Agent", "domain": "system", "registry_uri": "configs/agents/orchestrator.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:46.543247+00:00"}	{}	\N	2026-05-06 12:50:46.543313+00
audit_760fb7e1397248e1a10160e6292c7493	user	owner	agent_model.updated	agent_model_config	amodel_389689f0a6824a9c962a8db8be68cba6	Updated model config for memory-curator	{"id": "amodel_389689f0a6824a9c962a8db8be68cba6", "agent_id": "memory-curator", "primary_provider_id": "openrouter", "primary_model": "anthropic/claude-sonnet-4.6", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "amodel_389689f0a6824a9c962a8db8be68cba6", "agent_id": "memory-curator", "primary_provider_id": "openrouter", "primary_model": "anthropic/claude-sonnet-4.6", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:47.346657+00:00"}	{}	\N	2026-05-06 12:50:47.34864+00
audit_af5d3188fe2c45dfa2266ffe89c63087	user	owner	agent.updated	agent	health-fitness	Updated agent health-fitness	{"id": "health-fitness", "display_name": "Health/Fitness Agent", "domain": "health", "registry_uri": "configs/agents/health-fitness.yaml", "enabled": true, "autonomy_level": "review_gated", "version": 1, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "health-fitness", "display_name": "Health/Fitness Agent", "domain": "health", "registry_uri": "configs/agents/health-fitness.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:49.053537+00:00"}	{}	\N	2026-05-06 12:50:49.0536+00
audit_d0bfec301df84389a1384931a667c01e	user	owner	agent_model.updated	agent_model_config	amodel_f6dd846429b7482b8add352e4f1640af	Updated model config for finance	{"id": "amodel_f6dd846429b7482b8add352e4f1640af", "agent_id": "finance", "primary_provider_id": null, "primary_model": null, "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.657338+00:00", "updated_at": "2026-05-06T12:50:49.657338+00:00"}	{"id": "amodel_f6dd846429b7482b8add352e4f1640af", "agent_id": "finance", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.657338+00:00", "updated_at": "2026-05-06T12:50:49.657338+00:00"}	{}	\N	2026-05-06 12:50:49.659333+00
audit_ec76e1f1498f413fa83a97a8b1b19347	user	owner	agent_model.updated	agent_model_config	amodel_af5504813c2141ae816ba87f784f5f59	Updated model config for deen-prayer	{"id": "amodel_af5504813c2141ae816ba87f784f5f59", "agent_id": "deen-prayer", "primary_provider_id": null, "primary_model": null, "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.512553+00:00", "updated_at": "2026-05-06T12:50:50.512553+00:00"}	{"id": "amodel_af5504813c2141ae816ba87f784f5f59", "agent_id": "deen-prayer", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.512553+00:00", "updated_at": "2026-05-06T12:50:50.512553+00:00"}	{}	\N	2026-05-06 12:50:50.51455+00
audit_51cc12f79c624d5cb80be649640b0cf2	user	owner	agent.updated	agent	deen-prayer	Updated agent deen-prayer	{"id": "deen-prayer", "display_name": "Deen/Prayer Agent", "domain": "deen", "registry_uri": "configs/agents/deen-prayer.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:50.493696+00:00"}	{"id": "deen-prayer", "display_name": "Deen/Prayer Agent", "domain": "deen", "registry_uri": "configs/agents/deen-prayer.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:51.478200+00:00"}	{}	\N	2026-05-06 12:50:51.478261+00
audit_fd34d8e7a6f642c4a26d508c5182bb10	user	owner	agent_model.updated	agent_model_config	amodel_182a0eb09e83412091f76a17622e2a4a	Updated model config for daily-planner	{"id": "amodel_182a0eb09e83412091f76a17622e2a4a", "agent_id": "daily-planner", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "amodel_182a0eb09e83412091f76a17622e2a4a", "agent_id": "daily-planner", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:51.944284+00:00"}	{}	\N	2026-05-06 12:50:51.946092+00
audit_1fa44cc92b5a4c41b76fdb8b03f88c44	user	owner	agent.updated	agent	approval-manager	Updated agent approval-manager	{"id": "approval-manager", "display_name": "Approval Manager", "domain": "system", "registry_uri": "configs/agents/approval-manager.yaml", "enabled": true, "autonomy_level": "manual", "version": 1, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "approval-manager", "display_name": "Approval Manager", "domain": "system", "registry_uri": "configs/agents/approval-manager.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:52.798195+00:00"}	{}	\N	2026-05-06 12:50:52.798258+00
audit_567a2700bfb34a22af5fcb7663180805	user	owner	agent_model.updated	agent_model_config	amodel_f9eccb2fdaad467d813c8f5d49164968	Updated model config for orchestrator	{"id": "amodel_f9eccb2fdaad467d813c8f5d49164968", "agent_id": "orchestrator", "primary_provider_id": "openrouter", "primary_model": "anthropic/claude-sonnet-4.6", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.25}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "amodel_f9eccb2fdaad467d813c8f5d49164968", "agent_id": "orchestrator", "primary_provider_id": "openrouter", "primary_model": "anthropic/claude-sonnet-4.6", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.25}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:46.563403+00:00"}	{}	\N	2026-05-06 12:50:46.56537+00
audit_08c2b81905cb49deab32fd94f6e77874	user	owner	agent.updated	agent	memory-curator	Updated agent memory-curator	{"id": "memory-curator", "display_name": "Memory Curator", "domain": "memory", "registry_uri": "configs/agents/memory-curator.yaml", "enabled": true, "autonomy_level": "review_gated", "version": 1, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "memory-curator", "display_name": "Memory Curator", "domain": "memory", "registry_uri": "configs/agents/memory-curator.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:47.326035+00:00"}	{}	\N	2026-05-06 12:50:47.3261+00
audit_6f704da45f8c40d9a2bc9a3cf7ef1afd	user	owner	agent_model.updated	agent_model_config	amodel_78740a3514074cb2ad41c83d12c9b8bb	Updated model config for health-fitness	{"id": "amodel_78740a3514074cb2ad41c83d12c9b8bb", "agent_id": "health-fitness", "primary_provider_id": null, "primary_model": null, "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.072881+00:00", "updated_at": "2026-05-06T12:50:49.072881+00:00"}	{"id": "amodel_78740a3514074cb2ad41c83d12c9b8bb", "agent_id": "health-fitness", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.072881+00:00", "updated_at": "2026-05-06T12:50:49.072881+00:00"}	{}	\N	2026-05-06 12:50:49.074844+00
audit_8c2cb5f1171149c5b24f77fa86ad4ed5	user	owner	agent.updated	agent	family-commitments	Updated agent family-commitments	{"id": "family-commitments", "display_name": "Family/Personal Commitments Agent", "domain": "family", "registry_uri": "configs/agents/family-commitments.yaml", "enabled": true, "autonomy_level": "review_gated", "version": 1, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "family-commitments", "display_name": "Family/Personal Commitments Agent", "domain": "family", "registry_uri": "configs/agents/family-commitments.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:50.053795+00:00"}	{}	\N	2026-05-06 12:50:50.053857+00
audit_f3be6c6d27de42abb0204a085beb5096	user	owner	agent_model.updated	agent_model_config	amodel_af5504813c2141ae816ba87f784f5f59	Updated model config for deen-prayer	{"id": "amodel_af5504813c2141ae816ba87f784f5f59", "agent_id": "deen-prayer", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.512553+00:00", "updated_at": "2026-05-06T12:50:50.512553+00:00"}	{"id": "amodel_af5504813c2141ae816ba87f784f5f59", "agent_id": "deen-prayer", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.512553+00:00", "updated_at": "2026-05-06T12:50:51.500400+00:00"}	{}	\N	2026-05-06 12:50:51.502493+00
audit_39e7d5536b38449484c330a20c95ec59	user	owner	agent_model.updated	agent_model_config	amodel_1e04e2926de8452e81db5c849e5a8e77	Updated model config for capture-router	{"id": "amodel_1e04e2926de8452e81db5c849e5a8e77", "agent_id": "capture-router", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.05}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "amodel_1e04e2926de8452e81db5c849e5a8e77", "agent_id": "capture-router", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.05}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:52.368147+00:00"}	{}	\N	2026-05-06 12:50:52.370027+00
audit_8b6af505e3974c49a95d72ba84d1a842	user	owner	agent_model.updated	agent_model_config	amodel_af5504813c2141ae816ba87f784f5f59	Updated model config for deen-prayer	{"id": "amodel_af5504813c2141ae816ba87f784f5f59", "agent_id": "deen-prayer", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.512553+00:00", "updated_at": "2026-05-06T12:50:51.500400+00:00"}	{"id": "amodel_af5504813c2141ae816ba87f784f5f59", "agent_id": "deen-prayer", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.512553+00:00", "updated_at": "2026-05-06T12:50:53.363479+00:00"}	{}	\N	2026-05-06 12:50:53.365438+00
audit_5872d19c92eb43ed951a966c8bec2ab4	user	owner	agent_model.updated	agent_model_config	amodel_1e04e2926de8452e81db5c849e5a8e77	Updated model config for capture-router	{"id": "amodel_1e04e2926de8452e81db5c849e5a8e77", "agent_id": "capture-router", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.05}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:52.368147+00:00"}	{"id": "amodel_1e04e2926de8452e81db5c849e5a8e77", "agent_id": "capture-router", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.05}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:54.065393+00:00"}	{}	\N	2026-05-06 12:50:54.067387+00
audit_fb6932671b8c4982a2b8eda61e5dde00	user	owner	agent_model.updated	agent_model_config	amodel_9c4ef0e33b774e1a8a077a26ea1abb80	Updated model config for family-commitments	{"id": "amodel_9c4ef0e33b774e1a8a077a26ea1abb80", "agent_id": "family-commitments", "primary_provider_id": null, "primary_model": null, "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.073092+00:00", "updated_at": "2026-05-06T12:50:50.073092+00:00"}	{"id": "amodel_9c4ef0e33b774e1a8a077a26ea1abb80", "agent_id": "family-commitments", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.073092+00:00", "updated_at": "2026-05-06T12:50:50.073092+00:00"}	{}	\N	2026-05-06 12:50:50.075315+00
audit_ebcab8d183b74076b0e74378d24b2a30	user	owner	agent.updated	agent	deen-prayer	Updated agent deen-prayer	{"id": "deen-prayer", "display_name": "Deen/Prayer Agent", "domain": "deen", "registry_uri": "configs/agents/deen-prayer.yaml", "enabled": true, "autonomy_level": "review_gated", "version": 1, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "deen-prayer", "display_name": "Deen/Prayer Agent", "domain": "deen", "registry_uri": "configs/agents/deen-prayer.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:50.493696+00:00"}	{}	\N	2026-05-06 12:50:50.493784+00
audit_1280193671764523ac147841310e8dab	user	owner	agent.updated	agent	approval-manager	Updated agent approval-manager	{"id": "approval-manager", "display_name": "Approval Manager", "domain": "system", "registry_uri": "configs/agents/approval-manager.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:52.798195+00:00"}	{"id": "approval-manager", "display_name": "Approval Manager", "domain": "system", "registry_uri": "configs/agents/approval-manager.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:54.380503+00:00"}	{}	\N	2026-05-06 12:50:54.380566+00
audit_a6845886900e4534b78e25657d3772f8	user	owner	agent.updated	agent	capture-router	Updated agent capture-router	{"id": "capture-router", "display_name": "Capture Router", "domain": "system", "registry_uri": "configs/agents/capture-router.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:54.044489+00:00"}	{"id": "capture-router", "display_name": "Capture Router", "domain": "system", "registry_uri": "configs/agents/capture-router.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:56.342306+00:00"}	{}	\N	2026-05-06 12:50:56.342369+00
audit_667798a411294197acfe6078e96e8cc7	user	owner	agent_model.updated	agent_model_config	amodel_1e04e2926de8452e81db5c849e5a8e77	Updated model config for capture-router	{"id": "amodel_1e04e2926de8452e81db5c849e5a8e77", "agent_id": "capture-router", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.05}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:56.362456+00:00"}	{"id": "amodel_1e04e2926de8452e81db5c849e5a8e77", "agent_id": "capture-router", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.05}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:34.473397+00:00"}	{}	\N	2026-05-06 12:52:34.475158+00
audit_11fcdaff370d460b857beb8365700983	user	owner	agent_model.updated	agent_model_config	amodel_389689f0a6824a9c962a8db8be68cba6	Updated model config for memory-curator	{"id": "amodel_389689f0a6824a9c962a8db8be68cba6", "agent_id": "memory-curator", "primary_provider_id": "openrouter", "primary_model": "anthropic/claude-sonnet-4.6", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:47.346657+00:00"}	{"id": "amodel_389689f0a6824a9c962a8db8be68cba6", "agent_id": "memory-curator", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:40.136212+00:00"}	{}	\N	2026-05-06 12:52:40.138132+00
audit_147d155d0b334ebd96f5e70b7f2c1ca0	user	owner	agent.updated	agent	work.generic	Updated agent work.generic	{"id": "work.generic", "display_name": "Generic Work Agent", "domain": "work", "registry_uri": "configs/agents/work-generic.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:44.749836+00:00"}	{"id": "work.generic", "display_name": "Generic Work Agent", "domain": "work", "registry_uri": "configs/agents/work-generic.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:42.267985+00:00"}	{}	\N	2026-05-06 12:52:42.268049+00
audit_6d1311cb9f67416c9bff43243b440cce	user	owner	agent_model.updated	agent_model_config	amodel_6da908b6ce1a49a094b77e823e29005d	Updated model config for research	{"id": "amodel_6da908b6ce1a49a094b77e823e29005d", "agent_id": "research", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:46.040426+00:00", "updated_at": "2026-05-06T12:52:41.170983+00:00"}	{"id": "amodel_6da908b6ce1a49a094b77e823e29005d", "agent_id": "research", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:46.040426+00:00", "updated_at": "2026-05-06T12:52:43.034732+00:00"}	{}	\N	2026-05-06 12:52:43.036627+00
audit_864a80a9d41149dd99755646bd6aa135	user	owner	agent.updated	agent	memory-curator	Updated agent memory-curator	{"id": "memory-curator", "display_name": "Memory Curator", "domain": "memory", "registry_uri": "configs/agents/memory-curator.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:40.117578+00:00"}	{"id": "memory-curator", "display_name": "Memory Curator", "domain": "memory", "registry_uri": "configs/agents/memory-curator.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:43.717855+00:00"}	{}	\N	2026-05-06 12:52:43.717918+00
audit_8e786d5a93334e5da67afbca6a20337f	user	owner	agent.updated	agent	daily-planner	Updated agent daily-planner	{"id": "daily-planner", "display_name": "Daily Planner", "domain": "planning", "registry_uri": "configs/agents/daily-planner.yaml", "enabled": true, "autonomy_level": "review_gated", "version": 1, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "daily-planner", "display_name": "Daily Planner", "domain": "planning", "registry_uri": "configs/agents/daily-planner.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:51.925153+00:00"}	{}	\N	2026-05-06 12:50:51.925217+00
audit_cc717142d0ed4707acfab494c1bc9655	user	owner	agent.updated	agent	capture-router	Updated agent capture-router	{"id": "capture-router", "display_name": "Capture Router", "domain": "system", "registry_uri": "configs/agents/capture-router.yaml", "enabled": true, "autonomy_level": "review_gated", "version": 1, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "capture-router", "display_name": "Capture Router", "domain": "system", "registry_uri": "configs/agents/capture-router.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:52.348699+00:00"}	{}	\N	2026-05-06 12:50:52.348807+00
audit_7fd8a9150f3b4f7aa89ffa07c4c497b3	user	owner	agent.updated	agent	daily-planner	Updated agent daily-planner	{"id": "daily-planner", "display_name": "Daily Planner", "domain": "planning", "registry_uri": "configs/agents/daily-planner.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:51.925153+00:00"}	{"id": "daily-planner", "display_name": "Daily Planner", "domain": "planning", "registry_uri": "configs/agents/daily-planner.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:53.709117+00:00"}	{}	\N	2026-05-06 12:50:53.709178+00
audit_1a62e2cc32c44e38a23bfe192c7da972	user	owner	agent.updated	agent	finance	Updated agent finance	{"id": "finance", "display_name": "Finance Agent", "domain": "finance", "registry_uri": "configs/agents/finance.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:49.637988+00:00"}	{"id": "finance", "display_name": "Finance Agent", "domain": "finance", "registry_uri": "configs/agents/finance.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:55.062664+00:00"}	{}	\N	2026-05-06 12:50:55.062752+00
audit_11a131547a61413b986b39be2473dd71	user	owner	agent_model.updated	agent_model_config	amodel_182a0eb09e83412091f76a17622e2a4a	Updated model config for daily-planner	{"id": "amodel_182a0eb09e83412091f76a17622e2a4a", "agent_id": "daily-planner", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:53.727956+00:00"}	{"id": "amodel_182a0eb09e83412091f76a17622e2a4a", "agent_id": "daily-planner", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:55.931341+00:00"}	{}	\N	2026-05-06 12:50:55.933642+00
audit_74a71563e32244f5b44c2e73a397284c	user	owner	agent_model.updated	agent_model_config	amodel_a2f6808d79fd4e25bfb16937be53f0a4	Updated model config for approval-manager	{"id": "amodel_a2f6808d79fd4e25bfb16937be53f0a4", "agent_id": "approval-manager", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"temperature": 0}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:54.399935+00:00"}	{"id": "amodel_a2f6808d79fd4e25bfb16937be53f0a4", "agent_id": "approval-manager", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"temperature": 0}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:56.657024+00:00"}	{}	\N	2026-05-06 12:50:56.658919+00
audit_2b880f3375cf41f2bc15b4f771d307c2	user	owner	agent_model.updated	agent_model_config	amodel_78740a3514074cb2ad41c83d12c9b8bb	Updated model config for health-fitness	{"id": "amodel_78740a3514074cb2ad41c83d12c9b8bb", "agent_id": "health-fitness", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.072881+00:00", "updated_at": "2026-05-06T12:52:38.249977+00:00"}	{"id": "amodel_78740a3514074cb2ad41c83d12c9b8bb", "agent_id": "health-fitness", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.072881+00:00", "updated_at": "2026-05-06T12:52:39.481768+00:00"}	{}	\N	2026-05-06 12:52:39.48383+00
audit_33ffe6a5301647988a60a0bcc7fad7b3	user	owner	agent_model.updated	agent_model_config	amodel_6da908b6ce1a49a094b77e823e29005d	Updated model config for research	{"id": "amodel_6da908b6ce1a49a094b77e823e29005d", "agent_id": "research", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:46.040426+00:00", "updated_at": "2026-05-06T12:50:46.040426+00:00"}	{"id": "amodel_6da908b6ce1a49a094b77e823e29005d", "agent_id": "research", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:46.040426+00:00", "updated_at": "2026-05-06T12:52:41.170983+00:00"}	{}	\N	2026-05-06 12:52:41.172751+00
audit_a80e83a4080543fc91e10aed9a410281	user	owner	agent.updated	agent	systems-devops	Updated agent systems-devops	{"id": "systems-devops", "display_name": "Systems/DevOps Agent", "domain": "system", "registry_uri": "configs/agents/systems-devops.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:45.310618+00:00"}	{"id": "systems-devops", "display_name": "Systems/DevOps Agent", "domain": "system", "registry_uri": "configs/agents/systems-devops.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:41.590455+00:00"}	{}	\N	2026-05-06 12:52:41.590518+00
audit_599450d6c2a44a4197a56acc8eb6553b	user	owner	agent_model.updated	agent_model_config	amodel_a2f6808d79fd4e25bfb16937be53f0a4	Updated model config for approval-manager	{"id": "amodel_a2f6808d79fd4e25bfb16937be53f0a4", "agent_id": "approval-manager", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"temperature": 0}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"id": "amodel_a2f6808d79fd4e25bfb16937be53f0a4", "agent_id": "approval-manager", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"temperature": 0}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:52.817347+00:00"}	{}	\N	2026-05-06 12:50:52.819367+00
audit_9444455797d74eb0a4d2cff04ad99835	user	owner	agent.updated	agent	deen-prayer	Updated agent deen-prayer	{"id": "deen-prayer", "display_name": "Deen/Prayer Agent", "domain": "deen", "registry_uri": "configs/agents/deen-prayer.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:51.478200+00:00"}	{"id": "deen-prayer", "display_name": "Deen/Prayer Agent", "domain": "deen", "registry_uri": "configs/agents/deen-prayer.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:53.344377+00:00"}	{}	\N	2026-05-06 12:50:53.344443+00
audit_0973ed6c454447be93c762c882a3c526	user	owner	agent.updated	agent	capture-router	Updated agent capture-router	{"id": "capture-router", "display_name": "Capture Router", "domain": "system", "registry_uri": "configs/agents/capture-router.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:52.348699+00:00"}	{"id": "capture-router", "display_name": "Capture Router", "domain": "system", "registry_uri": "configs/agents/capture-router.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:54.044489+00:00"}	{}	\N	2026-05-06 12:50:54.044551+00
audit_6e14642be4b04555a6471c977aaf0768	user	owner	agent.updated	agent	daily-planner	Updated agent daily-planner	{"id": "daily-planner", "display_name": "Daily Planner", "domain": "planning", "registry_uri": "configs/agents/daily-planner.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:55.909671+00:00"}	{"id": "daily-planner", "display_name": "Daily Planner", "domain": "planning", "registry_uri": "configs/agents/daily-planner.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:34.894229+00:00"}	{}	\N	2026-05-06 12:52:34.894291+00
audit_cbb7f2e9098f491184a13002cccffb07	user	owner	agent.updated	agent	orchestrator	Updated agent orchestrator	{"id": "orchestrator", "display_name": "Orchestrator Agent", "domain": "system", "registry_uri": "configs/agents/orchestrator.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:46.543247+00:00"}	{"id": "orchestrator", "display_name": "Orchestrator Agent", "domain": "system", "registry_uri": "configs/agents/orchestrator.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:40.662663+00:00"}	{}	\N	2026-05-06 12:52:40.662759+00
audit_4914d7d319614e2184bd357e6d2f6637	user	owner	agent.updated	agent	work.generic	Updated agent work.generic	{"id": "work.generic", "display_name": "Generic Work Agent", "domain": "work", "registry_uri": "configs/agents/work-generic.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:42.267985+00:00"}	{"id": "work.generic", "display_name": "Generic Work Agent", "domain": "work", "registry_uri": "configs/agents/work-generic.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:45.347919+00:00"}	{}	\N	2026-05-06 12:52:45.347982+00
audit_b0be8b2ffeda4f6da123daa305c5e1cd	user	owner	agent.updated	agent	systems-devops	Updated agent systems-devops	{"id": "systems-devops", "display_name": "Systems/DevOps Agent", "domain": "system", "registry_uri": "configs/agents/systems-devops.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:42.677626+00:00"}	{"id": "systems-devops", "display_name": "Systems/DevOps Agent", "domain": "system", "registry_uri": "configs/agents/systems-devops.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:45.819630+00:00"}	{}	\N	2026-05-06 12:52:45.819692+00
audit_bf40192ed5b24264bce1e1149db57e4d	user	owner	agent.updated	agent	finance	Updated agent finance	{"id": "finance", "display_name": "Finance Agent", "domain": "finance", "registry_uri": "configs/agents/finance.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:37.077114+00:00"}	{"id": "finance", "display_name": "Finance Agent", "domain": "finance", "registry_uri": "configs/agents/finance.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:48.853847+00:00"}	{}	\N	2026-05-06 12:52:48.85391+00
audit_0df40b7683274babb33964aa3e2637ef	user	owner	agent.updated	agent	daily-planner	Updated agent daily-planner	{"id": "daily-planner", "display_name": "Daily Planner", "domain": "planning", "registry_uri": "configs/agents/daily-planner.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:34.894229+00:00"}	{"id": "daily-planner", "display_name": "Daily Planner", "domain": "planning", "registry_uri": "configs/agents/daily-planner.yaml", "enabled": true, "autonomy_level": "safe", "version": 6, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:50.923153+00:00"}	{}	\N	2026-05-06 12:52:50.92321+00
audit_00d68dbefd1249e7a25155e92b48ef09	user	owner	agent.updated	agent	approval-manager	Updated agent approval-manager	{"id": "approval-manager", "display_name": "Approval Manager", "domain": "system", "registry_uri": "configs/agents/approval-manager.yaml", "enabled": true, "autonomy_level": "safe", "version": 6, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:33.934784+00:00"}	{"id": "approval-manager", "display_name": "Approval Manager", "domain": "system", "registry_uri": "configs/agents/approval-manager.yaml", "enabled": true, "autonomy_level": "safe", "version": 7, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:54.141959+00:00"}	{}	\N	2026-05-06 12:52:54.142023+00
audit_67bbadebcc01454493aeab8f9c0d6f7d	user	owner	agent_model.updated	agent_model_config	amodel_182a0eb09e83412091f76a17622e2a4a	Updated model config for daily-planner	{"id": "amodel_182a0eb09e83412091f76a17622e2a4a", "agent_id": "daily-planner", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:51.944284+00:00"}	{"id": "amodel_182a0eb09e83412091f76a17622e2a4a", "agent_id": "daily-planner", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:53.727956+00:00"}	{}	\N	2026-05-06 12:50:53.729904+00
audit_ecff6d38b4934ce28e55ec309c82551b	user	owner	agent_model.updated	agent_model_config	amodel_a2f6808d79fd4e25bfb16937be53f0a4	Updated model config for approval-manager	{"id": "amodel_a2f6808d79fd4e25bfb16937be53f0a4", "agent_id": "approval-manager", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"temperature": 0}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:52.817347+00:00"}	{"id": "amodel_a2f6808d79fd4e25bfb16937be53f0a4", "agent_id": "approval-manager", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"temperature": 0}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:54.399935+00:00"}	{}	\N	2026-05-06 12:50:54.401786+00
audit_bca68216593947d392cfdcd2cb36c821	user	owner	agent_model.updated	agent_model_config	amodel_f6dd846429b7482b8add352e4f1640af	Updated model config for finance	{"id": "amodel_f6dd846429b7482b8add352e4f1640af", "agent_id": "finance", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.657338+00:00", "updated_at": "2026-05-06T12:50:49.657338+00:00"}	{"id": "amodel_f6dd846429b7482b8add352e4f1640af", "agent_id": "finance", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.657338+00:00", "updated_at": "2026-05-06T12:50:55.085336+00:00"}	{}	\N	2026-05-06 12:50:55.087218+00
audit_898f1a09106643c58adefc87143ca841	user	owner	agent.updated	agent	daily-planner	Updated agent daily-planner	{"id": "daily-planner", "display_name": "Daily Planner", "domain": "planning", "registry_uri": "configs/agents/daily-planner.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:53.709117+00:00"}	{"id": "daily-planner", "display_name": "Daily Planner", "domain": "planning", "registry_uri": "configs/agents/daily-planner.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:55.909671+00:00"}	{}	\N	2026-05-06 12:50:55.909748+00
audit_a2a21d660e344131bb7e651bbb64c4f0	user	owner	agent.updated	agent	approval-manager	Updated agent approval-manager	{"id": "approval-manager", "display_name": "Approval Manager", "domain": "system", "registry_uri": "configs/agents/approval-manager.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:56.637264+00:00"}	{"id": "approval-manager", "display_name": "Approval Manager", "domain": "system", "registry_uri": "configs/agents/approval-manager.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:33.038239+00:00"}	{}	\N	2026-05-06 12:52:33.038303+00
audit_f537ac26da634059be1e86f0bde1192f	user	owner	agent_model.updated	agent_model_config	amodel_a2f6808d79fd4e25bfb16937be53f0a4	Updated model config for approval-manager	{"id": "amodel_a2f6808d79fd4e25bfb16937be53f0a4", "agent_id": "approval-manager", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"temperature": 0}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:33.058573+00:00"}	{"id": "amodel_a2f6808d79fd4e25bfb16937be53f0a4", "agent_id": "approval-manager", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"temperature": 0}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:33.954237+00:00"}	{}	\N	2026-05-06 12:52:33.9561+00
audit_d3d6fbf8d36d4dea99d055e7ad43ca79	user	owner	agent.updated	agent	capture-router	Updated agent capture-router	{"id": "capture-router", "display_name": "Capture Router", "domain": "system", "registry_uri": "configs/agents/capture-router.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:56.342306+00:00"}	{"id": "capture-router", "display_name": "Capture Router", "domain": "system", "registry_uri": "configs/agents/capture-router.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:34.454293+00:00"}	{}	\N	2026-05-06 12:52:34.454355+00
audit_d602652e510748ccb426abdbb4fcb838	user	owner	agent_model.updated	agent_model_config	amodel_182a0eb09e83412091f76a17622e2a4a	Updated model config for daily-planner	{"id": "amodel_182a0eb09e83412091f76a17622e2a4a", "agent_id": "daily-planner", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:55.931341+00:00"}	{"id": "amodel_182a0eb09e83412091f76a17622e2a4a", "agent_id": "daily-planner", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:34.914042+00:00"}	{}	\N	2026-05-06 12:52:34.915856+00
audit_6b903b1ea6334c448c6ba3486a89ff3b	user	owner	agent.updated	agent	deen-prayer	Updated agent deen-prayer	{"id": "deen-prayer", "display_name": "Deen/Prayer Agent", "domain": "deen", "registry_uri": "configs/agents/deen-prayer.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:53.344377+00:00"}	{"id": "deen-prayer", "display_name": "Deen/Prayer Agent", "domain": "deen", "registry_uri": "configs/agents/deen-prayer.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:35.806310+00:00"}	{}	\N	2026-05-06 12:52:35.806373+00
audit_d58b9a17962649b68e0eaf51a7717e95	user	owner	agent_model.updated	agent_model_config	amodel_1e04e2926de8452e81db5c849e5a8e77	Updated model config for capture-router	{"id": "amodel_1e04e2926de8452e81db5c849e5a8e77", "agent_id": "capture-router", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.05}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:54.065393+00:00"}	{"id": "amodel_1e04e2926de8452e81db5c849e5a8e77", "agent_id": "capture-router", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.05}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:56.362456+00:00"}	{}	\N	2026-05-06 12:50:56.364285+00
audit_f26291d41fb948129304edbd27cd6e9e	user	owner	agent.updated	agent	approval-manager	Updated agent approval-manager	{"id": "approval-manager", "display_name": "Approval Manager", "domain": "system", "registry_uri": "configs/agents/approval-manager.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:54.380503+00:00"}	{"id": "approval-manager", "display_name": "Approval Manager", "domain": "system", "registry_uri": "configs/agents/approval-manager.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:56.637264+00:00"}	{}	\N	2026-05-06 12:50:56.637325+00
audit_aff2e65173774ee5b912f219bef0c0b8	user	owner	agent_model.updated	agent_model_config	amodel_a2f6808d79fd4e25bfb16937be53f0a4	Updated model config for approval-manager	{"id": "amodel_a2f6808d79fd4e25bfb16937be53f0a4", "agent_id": "approval-manager", "primary_provider_id": "openrouter", "primary_model": "openai/gpt-5.2-mini", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"temperature": 0}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:56.657024+00:00"}	{"id": "amodel_a2f6808d79fd4e25bfb16937be53f0a4", "agent_id": "approval-manager", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"temperature": 0}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:33.058573+00:00"}	{}	\N	2026-05-06 12:52:33.060326+00
audit_fd46b8f5116b41189f24b67d00ef6c92	user	owner	agent.updated	agent	approval-manager	Updated agent approval-manager	{"id": "approval-manager", "display_name": "Approval Manager", "domain": "system", "registry_uri": "configs/agents/approval-manager.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:33.038239+00:00"}	{"id": "approval-manager", "display_name": "Approval Manager", "domain": "system", "registry_uri": "configs/agents/approval-manager.yaml", "enabled": true, "autonomy_level": "safe", "version": 6, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:33.934784+00:00"}	{}	\N	2026-05-06 12:52:33.934848+00
audit_e0fb40301bc749a5b6163dcbb0e6bd02	user	owner	agent_model.updated	agent_model_config	amodel_af5504813c2141ae816ba87f784f5f59	Updated model config for deen-prayer	{"id": "amodel_af5504813c2141ae816ba87f784f5f59", "agent_id": "deen-prayer", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.512553+00:00", "updated_at": "2026-05-06T12:50:53.363479+00:00"}	{"id": "amodel_af5504813c2141ae816ba87f784f5f59", "agent_id": "deen-prayer", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.512553+00:00", "updated_at": "2026-05-06T12:52:35.825068+00:00"}	{}	\N	2026-05-06 12:52:35.826925+00
audit_16a0b99d9e084a5e992c5380537f4322	user	owner	agent.updated	agent	family-commitments	Updated agent family-commitments	{"id": "family-commitments", "display_name": "Family/Personal Commitments Agent", "domain": "family", "registry_uri": "configs/agents/family-commitments.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:50.053795+00:00"}	{"id": "family-commitments", "display_name": "Family/Personal Commitments Agent", "domain": "family", "registry_uri": "configs/agents/family-commitments.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:36.450134+00:00"}	{}	\N	2026-05-06 12:52:36.450196+00
audit_733b1f27661647fdbe6e28d3a432611e	user	owner	agent_model.updated	agent_model_config	amodel_f6dd846429b7482b8add352e4f1640af	Updated model config for finance	{"id": "amodel_f6dd846429b7482b8add352e4f1640af", "agent_id": "finance", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.657338+00:00", "updated_at": "2026-05-06T12:50:55.085336+00:00"}	{"id": "amodel_f6dd846429b7482b8add352e4f1640af", "agent_id": "finance", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.657338+00:00", "updated_at": "2026-05-06T12:52:37.096051+00:00"}	{}	\N	2026-05-06 12:52:37.098002+00
audit_c18c7c28748e49c39f62d54ae48c4ff9	user	owner	agent.updated	agent	health-fitness	Updated agent health-fitness	{"id": "health-fitness", "display_name": "Health/Fitness Agent", "domain": "health", "registry_uri": "configs/agents/health-fitness.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:49.053537+00:00"}	{"id": "health-fitness", "display_name": "Health/Fitness Agent", "domain": "health", "registry_uri": "configs/agents/health-fitness.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:38.230076+00:00"}	{}	\N	2026-05-06 12:52:38.230137+00
audit_27f00d4466be440dae8f7f68645ccd55	user	owner	agent.updated	agent	health-fitness	Updated agent health-fitness	{"id": "health-fitness", "display_name": "Health/Fitness Agent", "domain": "health", "registry_uri": "configs/agents/health-fitness.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:38.230076+00:00"}	{"id": "health-fitness", "display_name": "Health/Fitness Agent", "domain": "health", "registry_uri": "configs/agents/health-fitness.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:39.461429+00:00"}	{}	\N	2026-05-06 12:52:39.461491+00
audit_42f813a680f9445e90441b1369ac0291	user	owner	agent_model.updated	agent_model_config	amodel_9c4ef0e33b774e1a8a077a26ea1abb80	Updated model config for family-commitments	{"id": "amodel_9c4ef0e33b774e1a8a077a26ea1abb80", "agent_id": "family-commitments", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.073092+00:00", "updated_at": "2026-05-06T12:50:50.073092+00:00"}	{"id": "amodel_9c4ef0e33b774e1a8a077a26ea1abb80", "agent_id": "family-commitments", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.073092+00:00", "updated_at": "2026-05-06T12:52:36.475228+00:00"}	{}	\N	2026-05-06 12:52:36.477111+00
audit_11e8cc3fabf545ab8d7e0da76081aa81	user	owner	agent.updated	agent	finance	Updated agent finance	{"id": "finance", "display_name": "Finance Agent", "domain": "finance", "registry_uri": "configs/agents/finance.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:55.062664+00:00"}	{"id": "finance", "display_name": "Finance Agent", "domain": "finance", "registry_uri": "configs/agents/finance.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:37.077114+00:00"}	{}	\N	2026-05-06 12:52:37.077178+00
audit_6eb28894528745d681ae89f87517a488	user	owner	agent_model.updated	agent_model_config	amodel_78740a3514074cb2ad41c83d12c9b8bb	Updated model config for health-fitness	{"id": "amodel_78740a3514074cb2ad41c83d12c9b8bb", "agent_id": "health-fitness", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.072881+00:00", "updated_at": "2026-05-06T12:50:49.072881+00:00"}	{"id": "amodel_78740a3514074cb2ad41c83d12c9b8bb", "agent_id": "health-fitness", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.072881+00:00", "updated_at": "2026-05-06T12:52:38.249977+00:00"}	{}	\N	2026-05-06 12:52:38.251864+00
audit_8b5af2d441b74603915c9a5b9d294d75	user	owner	agent.updated	agent	memory-curator	Updated agent memory-curator	{"id": "memory-curator", "display_name": "Memory Curator", "domain": "memory", "registry_uri": "configs/agents/memory-curator.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:47.326035+00:00"}	{"id": "memory-curator", "display_name": "Memory Curator", "domain": "memory", "registry_uri": "configs/agents/memory-curator.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:40.117578+00:00"}	{}	\N	2026-05-06 12:52:40.11764+00
audit_cd959041209144718ac688fade578dc3	user	owner	agent_model.updated	agent_model_config	amodel_f9eccb2fdaad467d813c8f5d49164968	Updated model config for orchestrator	{"id": "amodel_f9eccb2fdaad467d813c8f5d49164968", "agent_id": "orchestrator", "primary_provider_id": "openrouter", "primary_model": "anthropic/claude-sonnet-4.6", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.25}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:46.563403+00:00"}	{"id": "amodel_f9eccb2fdaad467d813c8f5d49164968", "agent_id": "orchestrator", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.25}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:40.682075+00:00"}	{}	\N	2026-05-06 12:52:40.68398+00
audit_22753f631135469db95f17430294ae51	user	owner	agent.updated	agent	research	Updated agent research	{"id": "research", "display_name": "Research Agent", "domain": "research", "registry_uri": "configs/agents/research.yaml", "enabled": true, "autonomy_level": "safe", "version": 2, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:46.021870+00:00"}	{"id": "research", "display_name": "Research Agent", "domain": "research", "registry_uri": "configs/agents/research.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:41.149492+00:00"}	{}	\N	2026-05-06 12:52:41.149551+00
audit_1267caddb9f24ac1b5ca04ebe1f3ed3d	user	owner	agent_model.updated	agent_model_config	amodel_37936753655a417cbec4e4074d5971bd	Updated model config for systems-devops	{"id": "amodel_37936753655a417cbec4e4074d5971bd", "agent_id": "systems-devops", "primary_provider_id": "codex_oauth", "primary_model": "codex-default", "secondary_provider_id": "openrouter", "secondary_model": "openai/gpt-5.2", "fallback_allowed": true, "settings_json": {"require_workspace_scope": true}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:50:45.332330+00:00"}	{"id": "amodel_37936753655a417cbec4e4074d5971bd", "agent_id": "systems-devops", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"require_workspace_scope": true}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:41.609653+00:00"}	{}	\N	2026-05-06 12:52:41.611574+00
audit_efd96c54460b457eac85d1b98127c37e	user	owner	agent_model.updated	agent_model_config	amodel_37936753655a417cbec4e4074d5971bd	Updated model config for systems-devops	{"id": "amodel_37936753655a417cbec4e4074d5971bd", "agent_id": "systems-devops", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"require_workspace_scope": true}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:41.609653+00:00"}	{"id": "amodel_37936753655a417cbec4e4074d5971bd", "agent_id": "systems-devops", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"require_workspace_scope": true}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:42.699280+00:00"}	{}	\N	2026-05-06 12:52:42.701179+00
audit_dcf01a26f76a4b3399e7d2a2dbfaa28c	user	owner	setting.updated	system_setting	router.mode	Updated setting router.mode	{"key": "router.mode", "value_json": {"value": "hybrid"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:42:10.064746+00:00"}	{"key": "router.mode", "value_json": {"value": "deterministic"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:44:29.807884+00:00"}	{}	\N	2026-05-06 14:44:29.810928+00
audit_74112753ad8d4e14a3d1215dae6e88b4	user	owner	agent_model.updated	agent_model_config	amodel_ea038cfd99e24fbfab42964c66fd48dd	Updated model config for work.generic	{"id": "amodel_ea038cfd99e24fbfab42964c66fd48dd", "agent_id": "work.generic", "primary_provider_id": "codex_oauth", "primary_model": "", "secondary_provider_id": null, "secondary_model": null, "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:44.774018+00:00", "updated_at": "2026-05-06T12:50:44.774018+00:00"}	{"id": "amodel_ea038cfd99e24fbfab42964c66fd48dd", "agent_id": "work.generic", "primary_provider_id": "openrouter", "primary_model": "", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:44.774018+00:00", "updated_at": "2026-05-06T12:52:42.298890+00:00"}	{}	\N	2026-05-06 12:52:42.300831+00
audit_bf995fbbcc424d5e9c4e9c5a28b55676	user	owner	agent.updated	agent	research	Updated agent research	{"id": "research", "display_name": "Research Agent", "domain": "research", "registry_uri": "configs/agents/research.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:41.149492+00:00"}	{"id": "research", "display_name": "Research Agent", "domain": "research", "registry_uri": "configs/agents/research.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:43.014584+00:00"}	{}	\N	2026-05-06 12:52:43.014645+00
audit_393f5e9e03314670a260d262b4a8cc0e	user	owner	agent.updated	agent	orchestrator	Updated agent orchestrator	{"id": "orchestrator", "display_name": "Orchestrator Agent", "domain": "system", "registry_uri": "configs/agents/orchestrator.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:40.662663+00:00"}	{"id": "orchestrator", "display_name": "Orchestrator Agent", "domain": "system", "registry_uri": "configs/agents/orchestrator.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:43.359901+00:00"}	{}	\N	2026-05-06 12:52:43.359963+00
audit_cd999b2b3fdf415498dccd7a79052c69	user	owner	agent_model.updated	agent_model_config	amodel_ea038cfd99e24fbfab42964c66fd48dd	Updated model config for work.generic	{"id": "amodel_ea038cfd99e24fbfab42964c66fd48dd", "agent_id": "work.generic", "primary_provider_id": "openrouter", "primary_model": "", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:44.774018+00:00", "updated_at": "2026-05-06T12:52:42.298890+00:00"}	{"id": "amodel_ea038cfd99e24fbfab42964c66fd48dd", "agent_id": "work.generic", "primary_provider_id": "openrouter", "primary_model": "", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:44.774018+00:00", "updated_at": "2026-05-06T12:52:45.370171+00:00"}	{}	\N	2026-05-06 12:52:45.372027+00
audit_3584e919fdbe40b096d5ef51184de0b6	user	owner	agent_model.updated	agent_model_config	amodel_6da908b6ce1a49a094b77e823e29005d	Updated model config for research	{"id": "amodel_6da908b6ce1a49a094b77e823e29005d", "agent_id": "research", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:46.040426+00:00", "updated_at": "2026-05-06T12:52:43.034732+00:00"}	{"id": "amodel_6da908b6ce1a49a094b77e823e29005d", "agent_id": "research", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:46.040426+00:00", "updated_at": "2026-05-06T12:52:46.566313+00:00"}	{}	\N	2026-05-06 12:52:46.568361+00
audit_6df6ce7265874d3f871d1b109daa026e	user	owner	agent.updated	agent	health-fitness	Updated agent health-fitness	{"id": "health-fitness", "display_name": "Health/Fitness Agent", "domain": "health", "registry_uri": "configs/agents/health-fitness.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:39.461429+00:00"}	{"id": "health-fitness", "display_name": "Health/Fitness Agent", "domain": "health", "registry_uri": "configs/agents/health-fitness.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:48.430207+00:00"}	{}	\N	2026-05-06 12:52:48.430268+00
audit_0696b9fb412a4adca1a58debe1c66675	user	owner	agent_model.updated	agent_model_config	amodel_9c4ef0e33b774e1a8a077a26ea1abb80	Updated model config for family-commitments	{"id": "amodel_9c4ef0e33b774e1a8a077a26ea1abb80", "agent_id": "family-commitments", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.073092+00:00", "updated_at": "2026-05-06T12:52:36.475228+00:00"}	{"id": "amodel_9c4ef0e33b774e1a8a077a26ea1abb80", "agent_id": "family-commitments", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.073092+00:00", "updated_at": "2026-05-06T12:52:49.313976+00:00"}	{}	\N	2026-05-06 12:52:49.315642+00
audit_1678042992ae41f6a458e991d0a0c75b	user	owner	agent.updated	agent	deen-prayer	Updated agent deen-prayer	{"id": "deen-prayer", "display_name": "Deen/Prayer Agent", "domain": "deen", "registry_uri": "configs/agents/deen-prayer.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:35.806310+00:00"}	{"id": "deen-prayer", "display_name": "Deen/Prayer Agent", "domain": "deen", "registry_uri": "configs/agents/deen-prayer.yaml", "enabled": true, "autonomy_level": "safe", "version": 6, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:49.663746+00:00"}	{}	\N	2026-05-06 12:52:49.663809+00
audit_660847bac7124fdabfbbd28b53f75a60	user	owner	agent.updated	agent	daily-planner	Updated agent daily-planner	{"id": "daily-planner", "display_name": "Daily Planner", "domain": "planning", "registry_uri": "configs/agents/daily-planner.yaml", "enabled": true, "autonomy_level": "safe", "version": 6, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:50.923153+00:00"}	{"id": "daily-planner", "display_name": "Daily Planner", "domain": "planning", "registry_uri": "configs/agents/daily-planner.yaml", "enabled": true, "autonomy_level": "safe", "version": 7, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:52.681567+00:00"}	{}	\N	2026-05-06 12:52:52.681628+00
audit_dd07770a57294abc97afcd9e65ce3396	user	owner	agent.updated	agent	systems-devops	Updated agent systems-devops	{"id": "systems-devops", "display_name": "Systems/DevOps Agent", "domain": "system", "registry_uri": "configs/agents/systems-devops.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:41.590455+00:00"}	{"id": "systems-devops", "display_name": "Systems/DevOps Agent", "domain": "system", "registry_uri": "configs/agents/systems-devops.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:42.677626+00:00"}	{}	\N	2026-05-06 12:52:42.677688+00
audit_592b22f868d64723ac9d90fe1d3e3b3f	user	owner	agent_model.updated	agent_model_config	amodel_f9eccb2fdaad467d813c8f5d49164968	Updated model config for orchestrator	{"id": "amodel_f9eccb2fdaad467d813c8f5d49164968", "agent_id": "orchestrator", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.25}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:40.682075+00:00"}	{"id": "amodel_f9eccb2fdaad467d813c8f5d49164968", "agent_id": "orchestrator", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.25}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:43.382110+00:00"}	{}	\N	2026-05-06 12:52:43.384066+00
audit_dc0b969b8d95434e873db8a11eb5d80c	user	owner	agent.updated	agent	orchestrator	Updated agent orchestrator	{"id": "orchestrator", "display_name": "Orchestrator Agent", "domain": "system", "registry_uri": "configs/agents/orchestrator.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:43.359901+00:00"}	{"id": "orchestrator", "display_name": "Orchestrator Agent", "domain": "system", "registry_uri": "configs/agents/orchestrator.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:47.454874+00:00"}	{}	\N	2026-05-06 12:52:47.454935+00
audit_74f17124e8f44fe4b0447cd879373922	user	owner	agent_model.updated	agent_model_config	amodel_78740a3514074cb2ad41c83d12c9b8bb	Updated model config for health-fitness	{"id": "amodel_78740a3514074cb2ad41c83d12c9b8bb", "agent_id": "health-fitness", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.072881+00:00", "updated_at": "2026-05-06T12:52:39.481768+00:00"}	{"id": "amodel_78740a3514074cb2ad41c83d12c9b8bb", "agent_id": "health-fitness", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.072881+00:00", "updated_at": "2026-05-06T12:52:48.449114+00:00"}	{}	\N	2026-05-06 12:52:48.451095+00
audit_e5422784543545bfa325c65d82709feb	user	owner	agent_model.updated	agent_model_config	amodel_182a0eb09e83412091f76a17622e2a4a	Updated model config for daily-planner	{"id": "amodel_182a0eb09e83412091f76a17622e2a4a", "agent_id": "daily-planner", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:50.944828+00:00"}	{"id": "amodel_182a0eb09e83412091f76a17622e2a4a", "agent_id": "daily-planner", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:52.701237+00:00"}	{}	\N	2026-05-06 12:52:52.703063+00
audit_2066d011aaab44f4990ced40d6aa7e43	user	owner	agent.updated	agent	capture-router	Updated agent capture-router	{"id": "capture-router", "display_name": "Capture Router", "domain": "system", "registry_uri": "configs/agents/capture-router.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:34.454293+00:00"}	{"id": "capture-router", "display_name": "Capture Router", "domain": "system", "registry_uri": "configs/agents/capture-router.yaml", "enabled": true, "autonomy_level": "safe", "version": 6, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:53.517871+00:00"}	{}	\N	2026-05-06 12:52:53.517933+00
audit_2af2957a30204eed9fa71aed8cbfefef	user	owner	agent_model.updated	agent_model_config	amodel_389689f0a6824a9c962a8db8be68cba6	Updated model config for memory-curator	{"id": "amodel_389689f0a6824a9c962a8db8be68cba6", "agent_id": "memory-curator", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:40.136212+00:00"}	{"id": "amodel_389689f0a6824a9c962a8db8be68cba6", "agent_id": "memory-curator", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:43.738686+00:00"}	{}	\N	2026-05-06 12:52:43.740525+00
audit_337f1a51489b40918236b9369254fa88	user	owner	agent_model.updated	agent_model_config	amodel_37936753655a417cbec4e4074d5971bd	Updated model config for systems-devops	{"id": "amodel_37936753655a417cbec4e4074d5971bd", "agent_id": "systems-devops", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"require_workspace_scope": true}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:42.699280+00:00"}	{"id": "amodel_37936753655a417cbec4e4074d5971bd", "agent_id": "systems-devops", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"require_workspace_scope": true}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:45.840379+00:00"}	{}	\N	2026-05-06 12:52:45.842222+00
audit_6e5f5842b35e4120ad5a2210b5d7058f	user	owner	agent.updated	agent	research	Updated agent research	{"id": "research", "display_name": "Research Agent", "domain": "research", "registry_uri": "configs/agents/research.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:43.014584+00:00"}	{"id": "research", "display_name": "Research Agent", "domain": "research", "registry_uri": "configs/agents/research.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:46.547578+00:00"}	{}	\N	2026-05-06 12:52:46.547639+00
audit_3fd9f4eea82d4173b873799e09cd94aa	user	owner	agent_model.updated	agent_model_config	amodel_f9eccb2fdaad467d813c8f5d49164968	Updated model config for orchestrator	{"id": "amodel_f9eccb2fdaad467d813c8f5d49164968", "agent_id": "orchestrator", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.25}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:43.382110+00:00"}	{"id": "amodel_f9eccb2fdaad467d813c8f5d49164968", "agent_id": "orchestrator", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.25}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:47.475666+00:00"}	{}	\N	2026-05-06 12:52:47.477488+00
audit_2c5eb5ad682f430a8c46903b6eacc34c	user	owner	agent.updated	agent	memory-curator	Updated agent memory-curator	{"id": "memory-curator", "display_name": "Memory Curator", "domain": "memory", "registry_uri": "configs/agents/memory-curator.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:43.717855+00:00"}	{"id": "memory-curator", "display_name": "Memory Curator", "domain": "memory", "registry_uri": "configs/agents/memory-curator.yaml", "enabled": true, "autonomy_level": "safe", "version": 5, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:48.014192+00:00"}	{}	\N	2026-05-06 12:52:48.014256+00
audit_3fb2fd153c264171abee0df6b6c4f4d1	user	owner	agent_model.updated	agent_model_config	amodel_f6dd846429b7482b8add352e4f1640af	Updated model config for finance	{"id": "amodel_f6dd846429b7482b8add352e4f1640af", "agent_id": "finance", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.657338+00:00", "updated_at": "2026-05-06T12:52:37.096051+00:00"}	{"id": "amodel_f6dd846429b7482b8add352e4f1640af", "agent_id": "finance", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:49.657338+00:00", "updated_at": "2026-05-06T12:52:48.871743+00:00"}	{}	\N	2026-05-06 12:52:48.873425+00
audit_c69341136129462f87be8eb22e8dd1ce	user	owner	agent_model.updated	agent_model_config	amodel_af5504813c2141ae816ba87f784f5f59	Updated model config for deen-prayer	{"id": "amodel_af5504813c2141ae816ba87f784f5f59", "agent_id": "deen-prayer", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.512553+00:00", "updated_at": "2026-05-06T12:52:35.825068+00:00"}	{"id": "amodel_af5504813c2141ae816ba87f784f5f59", "agent_id": "deen-prayer", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:50:50.512553+00:00", "updated_at": "2026-05-06T12:52:49.681991+00:00"}	{}	\N	2026-05-06 12:52:49.683637+00
audit_aff8abede7574689a7421423373a7864	user	owner	agent_model.updated	agent_model_config	amodel_182a0eb09e83412091f76a17622e2a4a	Updated model config for daily-planner	{"id": "amodel_182a0eb09e83412091f76a17622e2a4a", "agent_id": "daily-planner", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:34.914042+00:00"}	{"id": "amodel_182a0eb09e83412091f76a17622e2a4a", "agent_id": "daily-planner", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:50.944828+00:00"}	{}	\N	2026-05-06 12:52:50.946801+00
audit_5e6271a2cd7a43d2bc874852c6a64e92	user	owner	agent_model.updated	agent_model_config	amodel_389689f0a6824a9c962a8db8be68cba6	Updated model config for memory-curator	{"id": "amodel_389689f0a6824a9c962a8db8be68cba6", "agent_id": "memory-curator", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:43.738686+00:00"}	{"id": "amodel_389689f0a6824a9c962a8db8be68cba6", "agent_id": "memory-curator", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:48.033280+00:00"}	{}	\N	2026-05-06 12:52:48.035216+00
audit_8b13a6eca6f64083802f1230b8eea78c	user	owner	agent.updated	agent	family-commitments	Updated agent family-commitments	{"id": "family-commitments", "display_name": "Family/Personal Commitments Agent", "domain": "family", "registry_uri": "configs/agents/family-commitments.yaml", "enabled": true, "autonomy_level": "safe", "version": 3, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:36.450134+00:00"}	{"id": "family-commitments", "display_name": "Family/Personal Commitments Agent", "domain": "family", "registry_uri": "configs/agents/family-commitments.yaml", "enabled": true, "autonomy_level": "safe", "version": 4, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:49.293973+00:00"}	{}	\N	2026-05-06 12:52:49.294032+00
audit_465465b01a584839ab69e3145b60ead0	user	owner	ask_lifeos.created	agent_run	run_7292281407f94c0b96216160fb805604	Ask LifeOS: Hello	null	{"answer": "I can answer from approved state or create review-gated proposals. No state mutation needed.", "review_item_id": null}	{}	trace_fa9b0f0d93f148548a22c668f1a94f90	2026-05-06 12:53:17.603355+00
audit_b97e946d14d6428ab59f708974a53995	user	owner	agent_model.updated	agent_model_config	amodel_1e04e2926de8452e81db5c849e5a8e77	Updated model config for capture-router	{"id": "amodel_1e04e2926de8452e81db5c849e5a8e77", "agent_id": "capture-router", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.05}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:34.473397+00:00"}	{"id": "amodel_1e04e2926de8452e81db5c849e5a8e77", "agent_id": "capture-router", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"max_cost_usd_per_run": 0.05}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:53.536614+00:00"}	{}	\N	2026-05-06 12:52:53.538607+00
audit_863d14bdd7524db18c5dad6e310eef81	user	owner	agent_model.updated	agent_model_config	amodel_a2f6808d79fd4e25bfb16937be53f0a4	Updated model config for approval-manager	{"id": "amodel_a2f6808d79fd4e25bfb16937be53f0a4", "agent_id": "approval-manager", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"temperature": 0}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:33.954237+00:00"}	{"id": "amodel_a2f6808d79fd4e25bfb16937be53f0a4", "agent_id": "approval-manager", "primary_provider_id": "openrouter", "primary_model": "tencent/hy3-preview:free", "secondary_provider_id": "nvidia_nim", "secondary_model": "nvidia/nemotron-3-super-120b-a12b", "fallback_allowed": true, "settings_json": {"temperature": 0}, "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:52:54.160963+00:00"}	{}	\N	2026-05-06 12:52:54.162887+00
audit_e7834db7e5854aecb91d1ee01c53ce53	user	owner	review.decision_received	review_item	rev_1da6d0d84419441ebc38a0b63b5b4161	Review decision: reject	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:07:19.470040+00:00"}	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:53:32.266048+00:00"}	{"decision_id": "dec_ce60c4d3da71411ea6372ad88e6aefd6"}	\N	2026-05-06 12:53:32.266327+00
audit_a38625a113e743098024ac71781e6e2a	user	owner	review.decision_received	review_item	rev_1da6d0d84419441ebc38a0b63b5b4161	Review decision: done	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:53:32.266048+00:00"}	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "applied", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:53:34.161240+00:00"}	{"decision_id": "dec_7e5ec60e030d4e1982723b06b5128ebb"}	\N	2026-05-06 12:53:34.161501+00
audit_35059242aede4e979174dcc58ba1ec5d	user	owner	review.decision_received	review_item	rev_1da6d0d84419441ebc38a0b63b5b4161	Review decision: done	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "applied", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:53:34.161240+00:00"}	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "applied", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:53:34.977573+00:00"}	{"decision_id": "dec_4757496e086345b882083df4eb55747a"}	\N	2026-05-06 12:53:34.9779+00
audit_68be7f9e9822439eb7c5baf61a2c5db3	agent	memory-curator	capture.policy_routed	raw_capture	cap_454daf5c601d4bd3b68798c4e5483279	Capture routed to memory-curator; policy=raw_only.	null	{"review_item_id": null, "run_id": "run_19dbc598042c4f9db05ce6981703698f", "state_change_id": null, "policy": {"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "fallback_used": false}}	{}	trace_597617d8ed4d4109a2b28232f61aa927	2026-05-06 14:44:29.835358+00
audit_d2effe9a7df44d989cb57b25f5f03312	user	owner	setting.updated	system_setting	router.mode	Updated setting router.mode	{"key": "router.mode", "value_json": {"value": "deterministic"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:44:29.807884+00:00"}	{"key": "router.mode", "value_json": {"value": "hybrid"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:44:29.929157+00:00"}	{}	\N	2026-05-06 14:44:29.930838+00
audit_726c40e6c4a44fd0bb607276246b3175	user	owner	review.decision_received	review_item	rev_1da6d0d84419441ebc38a0b63b5b4161	Review decision: done	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "applied", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:53:34.977573+00:00"}	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "applied", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:53:35.593235+00:00"}	{"decision_id": "dec_f90e29eef9c8485182a40878df9b3d4a"}	\N	2026-05-06 12:53:35.593479+00
audit_a30fac3484404c3493cc38124ad936c4	user	owner	review.decision_received	review_item	rev_1da6d0d84419441ebc38a0b63b5b4161	Review decision: reject	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "applied", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:53:35.593235+00:00"}	{"id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T12:05:07.019443+00:00", "updated_at": "2026-05-06T12:53:36.760155+00:00"}	{"decision_id": "dec_8c9664bf7a034c8ea195dccf3b015149"}	\N	2026-05-06 12:53:36.760391+00
audit_41b590aba9684f85bbab2ac8d3a810eb	agent	memory-curator	capture.policy_routed	raw_capture	cap_03e86c5ff77b4c6bb3bc0e4251886617	Capture routed to memory-curator; policy=raw_only.	null	{"review_item_id": null, "run_id": "run_92047b1a038942578f8c80933d38bca7", "state_change_id": null, "policy": {"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "provider_call_log_id": "pcall_a041ce2e6d2e46d0ba57c277aa6f5de6", "fallback_used": true, "fallback_reason": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}"}}	{}	trace_ee583b5fb6f4485c9a58efba8720bec3	2026-05-06 12:54:03.743035+00
audit_0148201605f94efdb04a1163c67ad7f6	agent	work.generic	capture.policy_routed	raw_capture	cap_a57b14d51ecf4c29af3c014ee2325d24	Capture routed to work.generic; policy=raw_only.	null	{"review_item_id": null, "run_id": "run_4485b6600ee641c8b6abd6e4c797ebee", "state_change_id": null, "policy": {"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.0, "requires_user_visible_status": false}, "provider": {"provider": "nvidia_nim", "model": "nvidia/nemotron-3-super-120b-a12b", "provider_call_log_id": "pcall_b251089fb0dd447fb364eb655496ccd2", "fallback_used": false}}	{}	trace_d53d8ccb2b864c798c20046d9bca5f07	2026-05-06 14:21:44.735583+00
audit_0f423eab87e74d0aaf629d04ee614a04	user	owner	setting.updated	system_setting	router.mode	Updated setting router.mode	{"key": "router.mode", "value_json": {"value": "hybrid"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T12:02:44.599139+00:00"}	{"key": "router.mode", "value_json": {"value": "deterministic"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:21:57.088305+00:00"}	{}	\N	2026-05-06 14:21:57.090439+00
audit_9870286c72c44b4f871c26a1c54a3d61	agent	memory-curator	capture.policy_routed	raw_capture	cap_3f2ae3aa5ff54b5999e88b5a5697b393	Capture routed to memory-curator; policy=raw_only.	null	{"review_item_id": null, "run_id": "run_484250866f254c26aca0b18dbeedd0d4", "state_change_id": null, "policy": {"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "fallback_used": false}}	{}	trace_f0ff473e10e64a01831808abb673fb80	2026-05-06 14:21:57.104403+00
audit_2b1cf8c7ca52499d88d102db3c0dfd82	agent	finance	capture.policy_routed	raw_capture	cap_ea5c084b450b45d2ab768ab91562d157	Capture routed to finance; policy=review_required.	null	{"review_item_id": "rev_d34c75e9b21b45cabfded6a683413cb8", "run_id": "run_85a510d22a384fb08a5059e122375ffc", "state_change_id": null, "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "fallback_used": false}}	{}	trace_70adc9cd780f42d9a8a5f35ddc45bcd1	2026-05-06 14:21:57.127415+00
audit_79250f0a36974826b1944b9afb97d461	agent	finance	capture.policy_routed	raw_capture	cap_d75ec0874b1a4ac7abcca69658396ac5	Capture routed to finance; policy=review_required.	null	{"review_item_id": "rev_323749ef15024188a89808aab7660c3e", "run_id": "run_f5274948c59a477186830dc802a2f480", "state_change_id": null, "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "fallback_used": false}}	{}	trace_7614d5242fb245a5977406bd6ca0d149	2026-05-06 14:44:29.862474+00
audit_4cfe00112fb5490db0748b96f3552d87	user	owner	review.decision_received	review_item	rev_d34c75e9b21b45cabfded6a683413cb8	Review decision: reject	{"id": "rev_d34c75e9b21b45cabfded6a683413cb8", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157", "source_uri": "raw/web/2026/05/06/we_cap_ea5c084b450b45d2ab768ab91562d157.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "pending", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T14:21:57.111394+00:00", "updated_at": "2026-05-06T14:21:57.111394+00:00"}	{"id": "rev_d34c75e9b21b45cabfded6a683413cb8", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157", "source_uri": "raw/web/2026/05/06/we_cap_ea5c084b450b45d2ab768ab91562d157.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T14:21:57.111394+00:00", "updated_at": "2026-05-06T14:21:57.141441+00:00"}	{"decision_id": "dec_ab4535dec66d4fb4acb87ccbce108342"}	\N	2026-05-06 14:21:57.141683+00
audit_2174062b56084ba283aaa046634abf73	agent	systems-devops	state_change.applied	life_item	item_816661bc5c954734a99b8446e3c42c38	Applied life_item.create	null	{"domain": "system", "item_type": "note", "title": "smoke test note: keep this as a low-risk LifeOS note", "description_md": "smoke test note: keep this as a low-risk LifeOS note", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}	{"state_change_id": "stchg_f02558b5d2ba4b4a97822671d8dcd585"}	\N	2026-05-06 14:21:57.177869+00
audit_eeec9b95f0584c319bfca2a7fb0cd7ac	agent	systems-devops	agent_session.message_processed	agent_run	run_4b45891d111542fcb8958d612ce40a57	Auto-applied life_item.create	null	{"session_id": "sess_cdce27c149bd4a59a301488b11878c34", "user_message_id": "msg_4d47ae467b3a425cb5c626f2c2712d7e", "result": {"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_e3f918e28c9f4dbcbd87631bb4dc6dce", "from_agent_id": "orchestrator", "to_agent_id": "systems-devops", "status": "completed", "summary_md": "systems-devops produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_f02558b5d2ba4b4a97822671d8dcd585", "entity_type": "life_item", "entity_id": "item_816661bc5c954734a99b8446e3c42c38", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_2174062b56084ba283aaa046634abf73"], "status_summary": "Auto-applied life_item.create"}}	{}	trace_ecc389a31fcc4e98bfcfdf494db88173	2026-05-06 14:21:57.178161+00
audit_195a093387164faba4e7f91f09dd7898	user	owner	setting.updated	system_setting	router.mode	Updated setting router.mode	{"key": "router.mode", "value_json": {"value": "deterministic"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:21:57.088305+00:00"}	{"key": "router.mode", "value_json": {"value": "hybrid"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:21:57.194664+00:00"}	{}	\N	2026-05-06 14:21:57.196555+00
audit_3e7ce954575947d387869719d0a1c16f	user	owner	review.decision_received	review_item	rev_d34c75e9b21b45cabfded6a683413cb8	Review decision: reject	{"id": "rev_d34c75e9b21b45cabfded6a683413cb8", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157", "source_uri": "raw/web/2026/05/06/we_cap_ea5c084b450b45d2ab768ab91562d157.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T14:21:57.111394+00:00", "updated_at": "2026-05-06T14:21:57.141441+00:00"}	{"id": "rev_d34c75e9b21b45cabfded6a683413cb8", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157", "source_uri": "raw/web/2026/05/06/we_cap_ea5c084b450b45d2ab768ab91562d157.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T14:21:57.111394+00:00", "updated_at": "2026-05-06T14:32:16.799766+00:00"}	{"decision_id": "dec_1aaaeab42d48472a963467cf1610a3ce"}	\N	2026-05-06 14:32:16.800035+00
audit_f997fb7678d74b9cae4d8e9018c01012	user	owner	review.decision_received	review_item	rev_d34c75e9b21b45cabfded6a683413cb8	Review decision: reject	{"id": "rev_d34c75e9b21b45cabfded6a683413cb8", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157", "source_uri": "raw/web/2026/05/06/we_cap_ea5c084b450b45d2ab768ab91562d157.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T14:21:57.111394+00:00", "updated_at": "2026-05-06T14:32:16.799766+00:00"}	{"id": "rev_d34c75e9b21b45cabfded6a683413cb8", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157", "source_uri": "raw/web/2026/05/06/we_cap_ea5c084b450b45d2ab768ab91562d157.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T14:21:57.111394+00:00", "updated_at": "2026-05-06T14:32:18.281086+00:00"}	{"decision_id": "dec_0c327c733ae14cc299f831a09c7a799e"}	\N	2026-05-06 14:32:18.281339+00
audit_0dc4f2dd98bf4bc1b4a6f54463bd3ef4	user	owner	setting.updated	system_setting	router.mode	Updated setting router.mode	{"key": "router.mode", "value_json": {"value": "hybrid"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:21:57.194664+00:00"}	{"key": "router.mode", "value_json": {"value": "deterministic"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:42:10.003068+00:00"}	{}	\N	2026-05-06 14:42:10.005209+00
audit_86f2e207e8ee488887655678a92c1c78	agent	daily-planner	state_change.applied	life_item	item_d3c966e59c9148a9a13a8997ea9a5411	Applied life_item.create	null	{"domain": "planning", "item_type": "note", "title": "hey", "description_md": "hey", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}	{"state_change_id": "stchg_9a3312324237425895a688c4bd0169ec"}	\N	2026-05-06 14:42:10.052666+00
audit_dd0313c16bbe4aa8bd32c534cb50df6d	agent	daily-planner	agent_session.message_processed	agent_run	run_012d4612d2b646289a60b301321711a7	Auto-applied life_item.create	null	{"session_id": "sess_0ac4fad62b6f44fba991498be03dcf91", "user_message_id": "msg_2ffae008a73248a8b9c8ee1bcbe54cd9", "result": {"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_b853ef1fe07c411ba57827dc47556dee", "from_agent_id": "orchestrator", "to_agent_id": "daily-planner", "status": "completed", "summary_md": "daily-planner produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_9a3312324237425895a688c4bd0169ec", "entity_type": "life_item", "entity_id": "item_d3c966e59c9148a9a13a8997ea9a5411", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_86f2e207e8ee488887655678a92c1c78"], "status_summary": "Auto-applied life_item.create"}}	{}	trace_e782a3c995eb46dda8ff8d44e7bd4ad7	2026-05-06 14:42:10.053012+00
audit_1179b91012764e50b6f63864a97411b3	user	owner	setting.updated	system_setting	router.mode	Updated setting router.mode	{"key": "router.mode", "value_json": {"value": "deterministic"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:42:10.003068+00:00"}	{"key": "router.mode", "value_json": {"value": "hybrid"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:42:10.064746+00:00"}	{}	\N	2026-05-06 14:42:10.067211+00
audit_d3fe2dc972e1404f907029f2dd821a08	agent	orchestrator	agent_session.message_processed	agent_run	run_c34644edcdf04a2794276d98d2bc0cb6	Answered directly	null	{"session_id": "sess_0ac4fad62b6f44fba991498be03dcf91", "user_message_id": "msg_e2e0ea3f0ada4e52b38b6d88b131a30f", "result": {"status": "final", "final_message_md": "Hey. I am here.\\n\\nSend a task, note, question, or correction and I will route it through LifeOS.", "what_i_did_md": "- Answered directly from session context.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [], "autonomous_actions": [], "memory_candidates": [], "preference_candidates": [], "audit_refs": [], "status_summary": "Answered directly"}}	{}	trace_34e016796407418fb51275ff5398e0d3	2026-05-06 14:44:15.216327+00
audit_1be0401f90bf484eaa3c393ff1ba598f	agent	systems-devops	state_change.applied	life_item	item_bbefd78c695c4821902b1ab5e6ba3364	Applied life_item.create	null	{"domain": "system", "item_type": "note", "title": "smoke test note: keep this as a low-risk LifeOS note", "description_md": "smoke test note: keep this as a low-risk LifeOS note", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}	{"state_change_id": "stchg_228e886e0ca5499091af8f3a43e969d7"}	\N	2026-05-06 14:44:29.913773+00
audit_f71027438174415b8652fc018ace37d5	user	owner	review.decision_received	review_item	rev_323749ef15024188a89808aab7660c3e	Review decision: reject	{"id": "rev_323749ef15024188a89808aab7660c3e", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_d75ec0874b1a4ac7abcca69658396ac5", "source_uri": "raw/web/2026/05/06/we_cap_d75ec0874b1a4ac7abcca69658396ac5.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_d75ec0874b1a4ac7abcca69658396ac5"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "pending", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T14:44:29.846948+00:00", "updated_at": "2026-05-06T14:44:29.846948+00:00"}	{"id": "rev_323749ef15024188a89808aab7660c3e", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_d75ec0874b1a4ac7abcca69658396ac5", "source_uri": "raw/web/2026/05/06/we_cap_d75ec0874b1a4ac7abcca69658396ac5.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_d75ec0874b1a4ac7abcca69658396ac5"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T14:44:29.846948+00:00", "updated_at": "2026-05-06T14:44:29.877900+00:00"}	{"decision_id": "dec_f5fc508d5e014f5b94d99993ffaa30e6"}	\N	2026-05-06 14:44:29.878163+00
audit_3faa2a4409a54f0b895186de26f2cbe3	agent	systems-devops	agent_session.message_processed	agent_run	run_5be33c728b6f445b8270d9c7591dffd4	Auto-applied life_item.create	null	{"session_id": "sess_cdce27c149bd4a59a301488b11878c34", "user_message_id": "msg_f67e45fc88654beeb3a743fb112b0fe1", "result": {"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_6831a95626ef4c54b50961debf6b5573", "from_agent_id": "orchestrator", "to_agent_id": "systems-devops", "status": "completed", "summary_md": "systems-devops produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_228e886e0ca5499091af8f3a43e969d7", "entity_type": "life_item", "entity_id": "item_bbefd78c695c4821902b1ab5e6ba3364", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_1be0401f90bf484eaa3c393ff1ba598f"], "status_summary": "Auto-applied life_item.create"}}	{}	trace_baf1ff555c564ae6ac07f05555a8cfab	2026-05-06 14:44:29.914322+00
audit_f4a052e9d1bc45448a0dcdf93fd29b50	agent	orchestrator	agent_session.message_processed	agent_run	run_302229626b4a49a3abd02392c31173e3	Answered directly	null	{"session_id": "sess_0ac4fad62b6f44fba991498be03dcf91", "user_message_id": "msg_14a36731880a4b1abdc7ce2ed79d4bd8", "result": {"status": "final", "final_message_md": "Hey. I am here.\\n\\nSend a task, note, question, or correction and I will route it through LifeOS.", "what_i_did_md": "- Answered directly from session context.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [], "autonomous_actions": [], "memory_candidates": [], "preference_candidates": [], "audit_refs": [], "status_summary": "Answered directly"}}	{}	trace_559e0c5432e94fb69a7d4a6e99aee8ab	2026-05-06 14:46:45.052298+00
audit_1a56321e3fe74446875a5d34ae0f2732	user	owner	setting.updated	system_setting	router.mode	Updated setting router.mode	{"key": "router.mode", "value_json": {"value": "hybrid"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:44:29.929157+00:00"}	{"key": "router.mode", "value_json": {"value": "deterministic"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:46:57.282673+00:00"}	{}	\N	2026-05-06 14:46:57.284374+00
audit_28b6e02ec9b0495a90c3024fd703aa60	agent	memory-curator	capture.policy_routed	raw_capture	cap_93390c37a92b44d697ed8bbaefbeaf56	Capture routed to memory-curator; policy=raw_only.	null	{"review_item_id": null, "run_id": "run_b5304a2705ad4185906215a0ada98218", "state_change_id": null, "policy": {"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "fallback_used": false}}	{}	trace_8a0acfda33ea4f96b67f0168e655bd9d	2026-05-06 14:46:57.307591+00
audit_253ba1a1735b4986b94089467e004c7c	agent	finance	capture.policy_routed	raw_capture	cap_23a9118878c64d9f90f05d8b985d730a	Capture routed to finance; policy=review_required.	null	{"review_item_id": "rev_80875aa15ccc4fbd93bf7ddd67bc0d5e", "run_id": "run_fbb633d89ecd42939345b18887ef347c", "state_change_id": null, "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "fallback_used": false}}	{}	trace_b8121a838d5e4ca6913fe42510901bac	2026-05-06 14:46:57.335931+00
audit_a8ba8ab095114664af1032f35815a6d6	user	owner	review.decision_received	review_item	rev_80875aa15ccc4fbd93bf7ddd67bc0d5e	Review decision: reject	{"id": "rev_80875aa15ccc4fbd93bf7ddd67bc0d5e", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_23a9118878c64d9f90f05d8b985d730a", "source_uri": "raw/web/2026/05/06/we_cap_23a9118878c64d9f90f05d8b985d730a.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_23a9118878c64d9f90f05d8b985d730a"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "pending", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T14:46:57.318947+00:00", "updated_at": "2026-05-06T14:46:57.318947+00:00"}	{"id": "rev_80875aa15ccc4fbd93bf7ddd67bc0d5e", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_23a9118878c64d9f90f05d8b985d730a", "source_uri": "raw/web/2026/05/06/we_cap_23a9118878c64d9f90f05d8b985d730a.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_23a9118878c64d9f90f05d8b985d730a"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T14:46:57.318947+00:00", "updated_at": "2026-05-06T14:46:57.351309+00:00"}	{"decision_id": "dec_1650f1b4a1ef473c8058a4bd4171cb94"}	\N	2026-05-06 14:46:57.351561+00
audit_125555355a824ce6ba967252544f3572	agent	systems-devops	state_change.applied	life_item	item_17ba033bb47544679227adbb85a0fc6f	Applied life_item.create	null	{"domain": "system", "item_type": "note", "title": "smoke test note: keep this as a low-risk LifeOS note", "description_md": "smoke test note: keep this as a low-risk LifeOS note", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}	{"state_change_id": "stchg_206baced4e1c4bb7994738da59812a36"}	\N	2026-05-06 14:46:57.384605+00
audit_27ff29f412bb4fb8a33b1566c366f405	agent	systems-devops	agent_session.message_processed	agent_run	run_0bf80e9c8ca347a3bf750b152ae62104	Auto-applied life_item.create	null	{"session_id": "sess_cdce27c149bd4a59a301488b11878c34", "user_message_id": "msg_84e60bf05573456c9a41f2f8585beef0", "result": {"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_fb75f1ed6649422082f873725e2a8724", "from_agent_id": "orchestrator", "to_agent_id": "systems-devops", "status": "completed", "summary_md": "systems-devops produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_206baced4e1c4bb7994738da59812a36", "entity_type": "life_item", "entity_id": "item_17ba033bb47544679227adbb85a0fc6f", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_125555355a824ce6ba967252544f3572"], "status_summary": "Auto-applied life_item.create"}}	{}	trace_1075e11f6ee043bab2b8574a01dac1bd	2026-05-06 14:46:57.384996+00
audit_468689dcc4884c70bd0a02518157a311	user	owner	setting.updated	system_setting	router.mode	Updated setting router.mode	{"key": "router.mode", "value_json": {"value": "deterministic"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:46:57.282673+00:00"}	{"key": "router.mode", "value_json": {"value": "hybrid"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:46:57.401208+00:00"}	{}	\N	2026-05-06 14:46:57.403023+00
audit_0733b4a195b14b05b6d2b63020f1978b	user	owner	setting.updated	system_setting	router.mode	Updated setting router.mode	{"key": "router.mode", "value_json": {"value": "hybrid"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T14:46:57.401208+00:00"}	{"key": "router.mode", "value_json": {"value": "deterministic"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T16:36:58.869269+00:00"}	{}	\N	2026-05-06 16:36:58.871083+00
audit_a2f42624a2654ee98eb6b2d7f51d7200	agent	memory-curator	capture.policy_routed	raw_capture	cap_7bd059b3793e459f9af461b29c254e6f	Capture routed to memory-curator; policy=raw_only.	null	{"review_item_id": null, "run_id": "run_338e8a46e18447a1b16f10d86c44469d", "state_change_id": null, "policy": {"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "fallback_used": false}}	{}	trace_30d3b245d50f4278b862c707fb142d6f	2026-05-06 16:36:58.89959+00
audit_efb0d2e5f14544819013a7dfc3285f33	agent	finance	capture.policy_routed	raw_capture	cap_1815c12243574fd185773ba74a944a50	Capture routed to finance; policy=review_required.	null	{"review_item_id": "rev_c4bedd5084d044c29220cced23e64dbb", "run_id": "run_b4c2536243be496da016b4bb8cb57f6d", "state_change_id": null, "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}, "provider": {"provider": "deterministic", "model": "capture-router-v1", "fallback_used": false}}	{}	trace_75c8afb3ce0742bda16b556ea0c1183c	2026-05-06 16:36:58.922986+00
audit_48fa61c1ac87454596e3e7bcea01a276	user	owner	review.decision_received	review_item	rev_c4bedd5084d044c29220cced23e64dbb	Review decision: reject	{"id": "rev_c4bedd5084d044c29220cced23e64dbb", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_1815c12243574fd185773ba74a944a50", "source_uri": "raw/web/2026/05/06/we_cap_1815c12243574fd185773ba74a944a50.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_1815c12243574fd185773ba74a944a50"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "pending", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T16:36:58.910534+00:00", "updated_at": "2026-05-06T16:36:58.910534+00:00"}	{"id": "rev_c4bedd5084d044c29220cced23e64dbb", "kind": "finance", "title": "Finance entry candidate", "body_md": "Parsed finance capture:\\n\\n> I spent 40 MAD on lunch\\n\\nAmount: **40.0 MAD**", "source_capture_id": "cap_1815c12243574fd185773ba74a944a50", "source_uri": "raw/web/2026/05/06/we_cap_1815c12243574fd185773ba74a944a50.md", "proposed_by_agent_id": "finance", "assigned_agent_id": "approval-manager", "priority": "normal", "confidence": 0.74, "risk_level": "finance_mutation", "sensitivity": "finance", "proposed_action_json": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_1815c12243574fd185773ba74a944a50"}}, "validation_json": {"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}, "status": "rejected", "expires_at": null, "snoozed_until": null, "created_at": "2026-05-06T16:36:58.910534+00:00", "updated_at": "2026-05-06T16:36:58.936640+00:00"}	{"decision_id": "dec_aa9982c4bc0d4783a5b2421f9d33ddba"}	\N	2026-05-06 16:36:58.936952+00
audit_52c41d69e0fb4ccfb1a469ea563764cf	agent	systems-devops	state_change.applied	life_item	item_a96511a15683433395b49e3be2ea76b9	Applied life_item.create	null	{"domain": "system", "item_type": "note", "title": "smoke test note: keep this as a low-risk LifeOS note", "description_md": "smoke test note: keep this as a low-risk LifeOS note", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}	{"state_change_id": "stchg_c74032dd191547628f8f491b643f6f91"}	\N	2026-05-06 16:36:59.007959+00
audit_10bfbae705264f279411dfc1358aeb91	agent	systems-devops	agent_session.message_processed	agent_run	run_659f6b5faf754c14a5a9b65d85491860	Auto-applied life_item.create	null	{"session_id": "sess_cdce27c149bd4a59a301488b11878c34", "user_message_id": "msg_73a6a92ea7ac432799b5b421cccd3a71", "result": {"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_97d5c650d3b34e7fbeadc22eaae6ba2a", "from_agent_id": "orchestrator", "to_agent_id": "systems-devops", "status": "completed", "summary_md": "systems-devops produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_c74032dd191547628f8f491b643f6f91", "entity_type": "life_item", "entity_id": "item_a96511a15683433395b49e3be2ea76b9", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_52c41d69e0fb4ccfb1a469ea563764cf"], "status_summary": "Auto-applied life_item.create"}}	{}	trace_ef108a9b90134d0b973cec9b54a975e2	2026-05-06 16:36:59.008528+00
audit_61e050f3710c41b5a537a9b100bf5e30	user	owner	setting.updated	system_setting	router.mode	Updated setting router.mode	{"key": "router.mode", "value_json": {"value": "deterministic"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T16:36:58.869269+00:00"}	{"key": "router.mode", "value_json": {"value": "hybrid"}, "description": "agentic, hybrid, or deterministic capture routing", "created_at": "2026-05-06T12:02:44.599139+00:00", "updated_at": "2026-05-06T16:36:59.025083+00:00"}	{}	\N	2026-05-06 16:36:59.026601+00
audit_118bca09fb4a40a4ac34abaafbdd2ab6	agent	work.generic	capture.policy_routed	raw_capture	cap_9e381bbd92c04332ac4759c958cfbe0b	Capture routed to work.generic; policy=raw_only.	null	{"review_item_id": null, "run_id": "run_3693a49a498f4617a5ce949dcbf62c37", "state_change_id": null, "policy": {"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.1, "requires_user_visible_status": false}, "provider": {"provider": "nvidia_nim", "model": "nvidia/nemotron-3-super-120b-a12b", "provider_call_log_id": "pcall_a72a1bba61c04038a0ead33e06c20959", "fallback_used": false}}	{}	trace_09add1ae0aaa43f1b17058bdd83f8d72	2026-05-06 16:41:30.555186+00
\.


--
-- Data for Name: capture_attachments; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.capture_attachments (id, capture_id, kind, original_filename, mime_type, storage_uri, content_hash, extracted_text_uri, metadata_json, created_at) FROM stdin;
\.


--
-- Data for Name: capture_interpretations; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.capture_interpretations (id, capture_id, agent_id, intent_labels, draft_json, confidence, missing_context, risk_level, status, created_at) FROM stdin;
interp_5aaaa6a522884d31877349aaef1f180b	cap_8015f24b491c47abb1c379f28522d5dd	memory-curator	["memory_candidate"]	{"domain": "memory", "title": "Memory candidate", "proposed_action": {"command_type": "memory_fact.create", "risk_level": "durable_memory_write", "payload": {"fact_kind": "note", "domain": "planning", "statement_md": "/start", "confidence": 0.62, "sensitivity": "normal", "evidence_refs": [{"kind": "raw_capture", "id": "cap_8015f24b491c47abb1c379f28522d5dd"}]}}}	0.61999999999999999555910790149937383830547332763671875	[]	durable_memory_write	promoted_to_review	2026-05-06 11:22:29.209022+00
interp_27dec3b8ebfe4200abd51d70f2a8a7cd	cap_e68e6163c02a478a9a6a553de44cf0fc	memory-curator	["memory_candidate"]	{"domain": "memory", "title": "Memory candidate", "proposed_action": {"command_type": "memory_fact.create", "risk_level": "durable_memory_write", "payload": {"fact_kind": "note", "domain": "planning", "statement_md": "Hello", "confidence": 0.62, "sensitivity": "normal", "evidence_refs": [{"kind": "raw_capture", "id": "cap_e68e6163c02a478a9a6a553de44cf0fc"}]}}}	0.61999999999999999555910790149937383830547332763671875	[]	durable_memory_write	promoted_to_review	2026-05-06 11:23:32.746568+00
interp_98d55d14169b4d45852b51997f9ec080	cap_47cac0ac72864934bbc418e19b4d58a8	work.generic	["task", "work"]	{"domain": "work", "title": "Work task candidate", "proposed_action": {"command_type": "life_item.create", "risk_level": "durable_state_mutation", "payload": {"domain": "work", "item_type": "task", "title": "I need to finish working on that subject proposal and talk to the teacher about", "description_md": "I need to finish working on that subject proposal and talk to the teacher about it", "priority": "normal", "status": "open", "source_capture_id": "cap_47cac0ac72864934bbc418e19b4d58a8"}}}	0.7600000000000000088817841970012523233890533447265625	[]	durable_state_mutation	promoted_to_review	2026-05-06 11:25:24.376647+00
interp_12700301dc904fe78c98a879ea1830a3	cap_4d62c7dcfedc4907a27f8952f4c5054b	memory-curator	["memory_candidate"]	{"domain": "memory", "title": "Memory candidate", "proposed_action": {"command_type": "memory_fact.create", "risk_level": "durable_memory_write", "payload": {"fact_kind": "note", "domain": "planning", "statement_md": "random thought: smoke test raw note", "confidence": 0.62, "sensitivity": "normal", "evidence_refs": [{"kind": "raw_capture", "id": "cap_4d62c7dcfedc4907a27f8952f4c5054b"}]}}}	0.61999999999999999555910790149937383830547332763671875	[]	durable_memory_write	promoted_to_review	2026-05-06 12:02:05.003737+00
interp_fee114de29da443daacf14722228a2ad	cap_2f464156a4384621921149d4586807d3	memory-curator	["raw_note"]	{"domain": "ledger", "title": "Raw note archived", "proposed_action": {"command_type": "none", "risk_level": "safe_internal_read", "payload": {"source_capture_id": "cap_2f464156a4384621921149d4586807d3", "summary": "random thought: smoke test raw note"}}}	0.88000000000000000444089209850062616169452667236328125	[]	safe_internal_read	archived_raw_only	2026-05-06 12:03:00.707578+00
interp_68ad2f91dae44352856ad1812f0dcf9f	cap_ca43ce4689da485a923a16124f148ebc	finance	["finance", "expense"]	{"domain": "finance", "title": "Finance entry candidate", "proposed_action": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ca43ce4689da485a923a16124f148ebc"}}}	0.7399999999999999911182158029987476766109466552734375	[]	finance_mutation	promoted_to_review	2026-05-06 12:03:01.634849+00
interp_8beae8381433420fa6f5fab482517045	cap_db6e45e9c04943bc85bf9d0ee436aeff	memory-curator	["raw_note"]	{"domain": "ledger", "title": "Raw note archived", "proposed_action": {"command_type": "none", "risk_level": "safe_internal_read", "payload": {"source_capture_id": "cap_db6e45e9c04943bc85bf9d0ee436aeff", "summary": "random thought: smoke test raw note"}}}	0.88000000000000000444089209850062616169452667236328125	[]	safe_internal_read	archived_raw_only	2026-05-06 12:05:06.676937+00
interp_f782596cdb584deeb237d6c3bac1e7df	cap_655320e1513b457181a225065ec8cec3	finance	["finance", "expense"]	{"domain": "finance", "title": "Finance entry candidate", "proposed_action": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}}	0.7399999999999999911182158029987476766109466552734375	[]	finance_mutation	promoted_to_review	2026-05-06 12:05:07.019443+00
interp_312a17090fb841c8bd202c894da6e441	cap_03e86c5ff77b4c6bb3bc0e4251886617	memory-curator	["raw_note"]	{"domain": "ledger", "title": "Raw note archived", "proposed_action": {"command_type": "none", "risk_level": "safe_internal_read", "payload": {"source_capture_id": "cap_03e86c5ff77b4c6bb3bc0e4251886617", "summary": "Hello"}}}	0.88000000000000000444089209850062616169452667236328125	[]	safe_internal_read	archived_raw_only	2026-05-06 12:54:03.396517+00
interp_1a50fa1fcb9a49d996261f220cfc48ce	cap_a57b14d51ecf4c29af3c014ee2325d24	work.generic	[]	{"domain": "work", "title": "Random thought", "proposed_action": {"command_type": "none", "risk_level": "safe_internal_read", "payload": {"source_capture_id": "cap_a57b14d51ecf4c29af3c014ee2325d24"}}}	0	[]	safe_internal_read	archived_raw_only	2026-05-06 14:21:14.05516+00
interp_fcb82c0297ca46b485858368579aaea7	cap_3f2ae3aa5ff54b5999e88b5a5697b393	memory-curator	["raw_note"]	{"domain": "ledger", "title": "Raw note archived", "proposed_action": {"command_type": "none", "risk_level": "safe_internal_read", "payload": {"source_capture_id": "cap_3f2ae3aa5ff54b5999e88b5a5697b393", "summary": "random thought: smoke test raw note"}}}	0.88000000000000000444089209850062616169452667236328125	[]	safe_internal_read	archived_raw_only	2026-05-06 14:21:57.096676+00
interp_e9a8ac78fe67477ea3b8795673e9f505	cap_ea5c084b450b45d2ab768ab91562d157	finance	["finance", "expense"]	{"domain": "finance", "title": "Finance entry candidate", "proposed_action": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157"}}}	0.7399999999999999911182158029987476766109466552734375	[]	finance_mutation	promoted_to_review	2026-05-06 14:21:57.111394+00
interp_8dbb8de7f4a44d5a8ea4d65d047a9f33	cap_454daf5c601d4bd3b68798c4e5483279	memory-curator	["raw_note"]	{"domain": "ledger", "title": "Raw note archived", "proposed_action": {"command_type": "none", "risk_level": "safe_internal_read", "payload": {"source_capture_id": "cap_454daf5c601d4bd3b68798c4e5483279", "summary": "random thought: smoke test raw note"}}}	0.88000000000000000444089209850062616169452667236328125	[]	safe_internal_read	archived_raw_only	2026-05-06 14:44:29.820195+00
interp_259bb54c522a448b816d86eb7e39eb81	cap_d75ec0874b1a4ac7abcca69658396ac5	finance	["finance", "expense"]	{"domain": "finance", "title": "Finance entry candidate", "proposed_action": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_d75ec0874b1a4ac7abcca69658396ac5"}}}	0.7399999999999999911182158029987476766109466552734375	[]	finance_mutation	promoted_to_review	2026-05-06 14:44:29.846948+00
interp_477abbfe69b44fdb8d91fecbe7a189d0	cap_93390c37a92b44d697ed8bbaefbeaf56	memory-curator	["raw_note"]	{"domain": "ledger", "title": "Raw note archived", "proposed_action": {"command_type": "none", "risk_level": "safe_internal_read", "payload": {"source_capture_id": "cap_93390c37a92b44d697ed8bbaefbeaf56", "summary": "random thought: smoke test raw note"}}}	0.88000000000000000444089209850062616169452667236328125	[]	safe_internal_read	archived_raw_only	2026-05-06 14:46:57.292724+00
interp_675f78f8022742d2ae2afd6e1c5bb099	cap_23a9118878c64d9f90f05d8b985d730a	finance	["finance", "expense"]	{"domain": "finance", "title": "Finance entry candidate", "proposed_action": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_23a9118878c64d9f90f05d8b985d730a"}}}	0.7399999999999999911182158029987476766109466552734375	[]	finance_mutation	promoted_to_review	2026-05-06 14:46:57.318947+00
interp_6e1f9aabe9824b4aa045588f4b858ece	cap_7bd059b3793e459f9af461b29c254e6f	memory-curator	["raw_note"]	{"domain": "ledger", "title": "Raw note archived", "proposed_action": {"command_type": "none", "risk_level": "safe_internal_read", "payload": {"source_capture_id": "cap_7bd059b3793e459f9af461b29c254e6f", "summary": "random thought: smoke test raw note"}}}	0.88000000000000000444089209850062616169452667236328125	[]	safe_internal_read	archived_raw_only	2026-05-06 16:36:58.882798+00
interp_fa6bdbd179bd4e22a03d200579dbe01b	cap_1815c12243574fd185773ba74a944a50	finance	["finance", "expense"]	{"domain": "finance", "title": "Finance entry candidate", "proposed_action": {"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_1815c12243574fd185773ba74a944a50"}}}	0.7399999999999999911182158029987476766109466552734375	[]	finance_mutation	promoted_to_review	2026-05-06 16:36:58.910534+00
interp_64f813c31f2d4becbab861264b237077	cap_9e381bbd92c04332ac4759c958cfbe0b	work.generic	[]	{"domain": "work", "title": "Greeting received", "proposed_action": {"command_type": "none", "risk_level": "safe_internal_read", "payload": {"source_capture_id": "cap_9e381bbd92c04332ac4759c958cfbe0b"}}}	0.1000000000000000055511151231257827021181583404541015625	[]	safe_internal_read	archived_raw_only	2026-05-06 16:41:20.355501+00
\.


--
-- Data for Name: channels; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.channels (id, platform, external_channel_id, guild_id, name, purpose, default_agent_id, enabled, metadata_json, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: daily_logs; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.daily_logs (id, user_id, local_date, domain, log_type, value_json, source_capture_id, review_item_id, confidence, created_at) FROM stdin;
\.


--
-- Data for Name: dead_letter_items; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.dead_letter_items (id, source_kind, source_id, reason, payload_json, vault_uri, status, created_at) FROM stdin;
\.


--
-- Data for Name: finance_entries; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.finance_entries (id, local_date, entry_type, amount, currency, category, note_md, status, source_capture_id, review_item_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: handoffs; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.handoffs (id, parent_run_id, from_agent_id, to_agent_id, reason, task_md, context_refs, expected_output_schema, status, visibility, discord_summary_posted, created_at, updated_at, completed_at, known_context, constraints, result_json, summary_md, risk_level, requires_user_visibility) FROM stdin;
hnd_00967586139542c394a6839b97709dd8	run_e74bd4a2fa7446dfb8681f1ff1c95902	capture-router	memory-curator	Capture classified as memory	Draft review-gated action for capture cap_8015f24b491c47abb1c379f28522d5dd.	[{"kind": "raw_capture", "id": "cap_8015f24b491c47abb1c379f28522d5dd", "uri": "raw/telegram/2026/05/06/te_cap_8015f24b491c47abb1c379f28522d5dd.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 11:22:29.209022+00	2026-05-06 11:22:29.209022+00	2026-05-06 11:22:29.209022+00	[]	[]	{}	\N	normal	t
hnd_d7c79e23fc374a82822f41a3cef63fe9	run_4927bce4bff6431299a248cb3fbb4eb3	capture-router	memory-curator	Capture classified as memory	Draft review-gated action for capture cap_e68e6163c02a478a9a6a553de44cf0fc.	[{"kind": "raw_capture", "id": "cap_e68e6163c02a478a9a6a553de44cf0fc", "uri": "raw/telegram/2026/05/06/te_cap_e68e6163c02a478a9a6a553de44cf0fc.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 11:23:32.746568+00	2026-05-06 11:23:32.746568+00	2026-05-06 11:23:32.746568+00	[]	[]	{}	\N	normal	t
hnd_d24add2b5c644801ae1087a482a38347	run_c3f5d9dfe2a341028ceb17dd598b323c	capture-router	work.generic	Capture classified as work	Draft review-gated action for capture cap_47cac0ac72864934bbc418e19b4d58a8.	[{"kind": "raw_capture", "id": "cap_47cac0ac72864934bbc418e19b4d58a8", "uri": "raw/telegram/2026/05/06/te_cap_47cac0ac72864934bbc418e19b4d58a8.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 11:25:24.376647+00	2026-05-06 11:25:24.376647+00	2026-05-06 11:25:24.376647+00	[]	[]	{}	\N	normal	t
hnd_a181bb1f229c42288620406bdeba970e	run_e4d19a1c2cd84b799d1dde6ce4d56501	capture-router	memory-curator	Capture classified as memory	Draft review-gated action for capture cap_4d62c7dcfedc4907a27f8952f4c5054b.	[{"kind": "raw_capture", "id": "cap_4d62c7dcfedc4907a27f8952f4c5054b", "uri": "raw/web/2026/05/06/we_cap_4d62c7dcfedc4907a27f8952f4c5054b.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 12:02:05.003737+00	2026-05-06 12:02:05.003737+00	2026-05-06 12:02:05.003737+00	[]	[]	{}	\N	normal	t
hnd_cdee5eedc36c4d0bb30d4c264dbcbaa2	run_787fd5a401604cb2b902e17cd28bea33	capture-router	memory-curator	Capture classified as ledger	Classify capture cap_2f464156a4384621921149d4586807d3 and apply policy.	[{"kind": "raw_capture", "id": "cap_2f464156a4384621921149d4586807d3", "uri": "raw/web/2026/05/06/we_cap_2f464156a4384621921149d4586807d3.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 12:03:00.707578+00	2026-05-06 12:03:00.707578+00	2026-05-06 12:03:00.707578+00	[]	[]	{}	\N	normal	t
hnd_a62543df982b405989cc776d24031aa3	run_f9e31bcd6aef4773b98f1ef9895e9539	capture-router	finance	Capture classified as finance	Classify capture cap_ca43ce4689da485a923a16124f148ebc and apply policy.	[{"kind": "raw_capture", "id": "cap_ca43ce4689da485a923a16124f148ebc", "uri": "raw/web/2026/05/06/we_cap_ca43ce4689da485a923a16124f148ebc.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 12:03:01.634849+00	2026-05-06 12:03:01.634849+00	2026-05-06 12:03:01.634849+00	[]	[]	{}	\N	normal	t
hnd_a5646f22bbf34e34ad754a2c4feb2a67	run_ecf75fb7fc0048e29e8d71a65f430268	capture-router	memory-curator	Capture classified as ledger	Classify capture cap_db6e45e9c04943bc85bf9d0ee436aeff and apply policy.	[{"kind": "raw_capture", "id": "cap_db6e45e9c04943bc85bf9d0ee436aeff", "uri": "raw/web/2026/05/06/we_cap_db6e45e9c04943bc85bf9d0ee436aeff.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 12:05:06.676937+00	2026-05-06 12:05:06.676937+00	2026-05-06 12:05:06.676937+00	[]	[]	{}	\N	normal	t
hnd_5a324f1c0ba44250af1760e231d24250	run_4d6dd79f17454ba38768b05f28b68a88	capture-router	finance	Capture classified as finance	Classify capture cap_655320e1513b457181a225065ec8cec3 and apply policy.	[{"kind": "raw_capture", "id": "cap_655320e1513b457181a225065ec8cec3", "uri": "raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 12:05:07.019443+00	2026-05-06 12:05:07.019443+00	2026-05-06 12:05:07.019443+00	[]	[]	{}	\N	normal	t
hnd_44ebc60eb0d24debaf31349d31de91ad	run_92047b1a038942578f8c80933d38bca7	capture-router	memory-curator	Capture classified as ledger	Classify capture cap_03e86c5ff77b4c6bb3bc0e4251886617 and apply policy.	[{"kind": "raw_capture", "id": "cap_03e86c5ff77b4c6bb3bc0e4251886617", "uri": "raw/telegram/2026/05/06/te_cap_03e86c5ff77b4c6bb3bc0e4251886617.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 12:54:03.396517+00	2026-05-06 12:54:03.396517+00	2026-05-06 12:54:03.396517+00	[]	[]	{}	\N	normal	t
hnd_63fb7968b2b845cdaa45a7f5c0081663	run_4485b6600ee641c8b6abd6e4c797ebee	capture-router	work.generic	Capture classified as work	Classify capture cap_a57b14d51ecf4c29af3c014ee2325d24 and apply policy.	[{"kind": "raw_capture", "id": "cap_a57b14d51ecf4c29af3c014ee2325d24", "uri": "raw/web/2026/05/06/we_cap_a57b14d51ecf4c29af3c014ee2325d24.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 14:21:14.05516+00	2026-05-06 14:21:14.05516+00	2026-05-06 14:21:14.05516+00	[]	[]	{}	\N	normal	t
hnd_746ebf3fbcae41cda7c5c96344a667fe	run_484250866f254c26aca0b18dbeedd0d4	capture-router	memory-curator	Capture classified as ledger	Classify capture cap_3f2ae3aa5ff54b5999e88b5a5697b393 and apply policy.	[{"kind": "raw_capture", "id": "cap_3f2ae3aa5ff54b5999e88b5a5697b393", "uri": "raw/web/2026/05/06/we_cap_3f2ae3aa5ff54b5999e88b5a5697b393.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 14:21:57.096676+00	2026-05-06 14:21:57.096676+00	2026-05-06 14:21:57.096676+00	[]	[]	{}	\N	normal	t
hnd_5c1c1920d50a45cd9467a8248785e440	run_85a510d22a384fb08a5059e122375ffc	capture-router	finance	Capture classified as finance	Classify capture cap_ea5c084b450b45d2ab768ab91562d157 and apply policy.	[{"kind": "raw_capture", "id": "cap_ea5c084b450b45d2ab768ab91562d157", "uri": "raw/web/2026/05/06/we_cap_ea5c084b450b45d2ab768ab91562d157.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 14:21:57.111394+00	2026-05-06 14:21:57.111394+00	2026-05-06 14:21:57.111394+00	[]	[]	{}	\N	normal	t
hnd_e3f918e28c9f4dbcbd87631bb4dc6dce	run_4b45891d111542fcb8958d612ce40a57	orchestrator	systems-devops	low-risk reversible session action	Handle session message:\n\nsmoke test note: keep this as a low-risk LifeOS note	[{"kind": "message", "run_id": "run_4b45891d111542fcb8958d612ce40a57"}]	{"type": "agent_run_result"}	completed	discord_compact	f	2026-05-06 14:21:57.170643+00	2026-05-06 14:21:57.170813+00	2026-05-06 14:21:57.170813+00	[{"kind": "session", "id": "sess_cdce27c149bd4a59a301488b11878c34"}]	[{"kind": "policy", "value": "escalate risky or ambiguous actions"}]	{"kind": "autonomous_action", "domain": "system"}	systems-devops produced a autonomous_action plan.	reversible_internal_write	t
hnd_b853ef1fe07c411ba57827dc47556dee	run_012d4612d2b646289a60b301321711a7	orchestrator	daily-planner	low-risk reversible session action	Handle session message:\n\nhey	[{"kind": "message", "run_id": "run_012d4612d2b646289a60b301321711a7"}]	{"type": "agent_run_result"}	completed	discord_compact	f	2026-05-06 14:42:10.04257+00	2026-05-06 14:42:10.042759+00	2026-05-06 14:42:10.042759+00	[{"kind": "session", "id": "sess_0ac4fad62b6f44fba991498be03dcf91"}]	[{"kind": "policy", "value": "escalate risky or ambiguous actions"}]	{"kind": "autonomous_action", "domain": "planning"}	daily-planner produced a autonomous_action plan.	reversible_internal_write	t
hnd_14804ad17c714eb2a0fa5d6cd1f16edf	run_19dbc598042c4f9db05ce6981703698f	capture-router	memory-curator	Capture classified as ledger	Classify capture cap_454daf5c601d4bd3b68798c4e5483279 and apply policy.	[{"kind": "raw_capture", "id": "cap_454daf5c601d4bd3b68798c4e5483279", "uri": "raw/web/2026/05/06/we_cap_454daf5c601d4bd3b68798c4e5483279.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 14:44:29.820195+00	2026-05-06 14:44:29.820195+00	2026-05-06 14:44:29.820195+00	[]	[]	{}	\N	normal	t
hnd_d609a5241d904aa99d6590aa7fa0fc0d	run_f5274948c59a477186830dc802a2f480	capture-router	finance	Capture classified as finance	Classify capture cap_d75ec0874b1a4ac7abcca69658396ac5 and apply policy.	[{"kind": "raw_capture", "id": "cap_d75ec0874b1a4ac7abcca69658396ac5", "uri": "raw/web/2026/05/06/we_cap_d75ec0874b1a4ac7abcca69658396ac5.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 14:44:29.846948+00	2026-05-06 14:44:29.846948+00	2026-05-06 14:44:29.846948+00	[]	[]	{}	\N	normal	t
hnd_6831a95626ef4c54b50961debf6b5573	run_5be33c728b6f445b8270d9c7591dffd4	orchestrator	systems-devops	low-risk reversible session action	Handle session message:\n\nsmoke test note: keep this as a low-risk LifeOS note	[{"kind": "message", "run_id": "run_5be33c728b6f445b8270d9c7591dffd4"}]	{"type": "agent_run_result"}	completed	discord_compact	f	2026-05-06 14:44:29.904186+00	2026-05-06 14:44:29.904332+00	2026-05-06 14:44:29.904332+00	[{"kind": "session", "id": "sess_cdce27c149bd4a59a301488b11878c34"}]	[{"kind": "policy", "value": "escalate risky or ambiguous actions"}]	{"kind": "autonomous_action", "domain": "system"}	systems-devops produced a autonomous_action plan.	reversible_internal_write	t
hnd_7cfe60d3fe4f4f00955d7f3a32d9f757	run_b5304a2705ad4185906215a0ada98218	capture-router	memory-curator	Capture classified as ledger	Classify capture cap_93390c37a92b44d697ed8bbaefbeaf56 and apply policy.	[{"kind": "raw_capture", "id": "cap_93390c37a92b44d697ed8bbaefbeaf56", "uri": "raw/web/2026/05/06/we_cap_93390c37a92b44d697ed8bbaefbeaf56.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 14:46:57.292724+00	2026-05-06 14:46:57.292724+00	2026-05-06 14:46:57.292724+00	[]	[]	{}	\N	normal	t
hnd_54163f0282574e41892a9f0363eb11e0	run_fbb633d89ecd42939345b18887ef347c	capture-router	finance	Capture classified as finance	Classify capture cap_23a9118878c64d9f90f05d8b985d730a and apply policy.	[{"kind": "raw_capture", "id": "cap_23a9118878c64d9f90f05d8b985d730a", "uri": "raw/web/2026/05/06/we_cap_23a9118878c64d9f90f05d8b985d730a.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 14:46:57.318947+00	2026-05-06 14:46:57.318947+00	2026-05-06 14:46:57.318947+00	[]	[]	{}	\N	normal	t
hnd_fb75f1ed6649422082f873725e2a8724	run_0bf80e9c8ca347a3bf750b152ae62104	orchestrator	systems-devops	low-risk reversible session action	Handle session message:\n\nsmoke test note: keep this as a low-risk LifeOS note	[{"kind": "message", "run_id": "run_0bf80e9c8ca347a3bf750b152ae62104"}]	{"type": "agent_run_result"}	completed	discord_compact	f	2026-05-06 14:46:57.376136+00	2026-05-06 14:46:57.376283+00	2026-05-06 14:46:57.376283+00	[{"kind": "session", "id": "sess_cdce27c149bd4a59a301488b11878c34"}]	[{"kind": "policy", "value": "escalate risky or ambiguous actions"}]	{"kind": "autonomous_action", "domain": "system"}	systems-devops produced a autonomous_action plan.	reversible_internal_write	t
hnd_edf4cef9d039472bbba475650c0bd116	run_338e8a46e18447a1b16f10d86c44469d	capture-router	memory-curator	Capture classified as ledger	Classify capture cap_7bd059b3793e459f9af461b29c254e6f and apply policy.	[{"kind": "raw_capture", "id": "cap_7bd059b3793e459f9af461b29c254e6f", "uri": "raw/web/2026/05/06/we_cap_7bd059b3793e459f9af461b29c254e6f.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 16:36:58.882798+00	2026-05-06 16:36:58.882798+00	2026-05-06 16:36:58.882798+00	[]	[]	{}	\N	normal	t
hnd_edcbd3a818914bd093d7f4fa9cb81e2b	run_b4c2536243be496da016b4bb8cb57f6d	capture-router	finance	Capture classified as finance	Classify capture cap_1815c12243574fd185773ba74a944a50 and apply policy.	[{"kind": "raw_capture", "id": "cap_1815c12243574fd185773ba74a944a50", "uri": "raw/web/2026/05/06/we_cap_1815c12243574fd185773ba74a944a50.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 16:36:58.910534+00	2026-05-06 16:36:58.910534+00	2026-05-06 16:36:58.910534+00	[]	[]	{}	\N	normal	t
hnd_97d5c650d3b34e7fbeadc22eaae6ba2a	run_659f6b5faf754c14a5a9b65d85491860	orchestrator	systems-devops	low-risk reversible session action	Handle session message:\n\nsmoke test note: keep this as a low-risk LifeOS note	[{"kind": "message", "run_id": "run_659f6b5faf754c14a5a9b65d85491860"}]	{"type": "agent_run_result"}	completed	discord_compact	f	2026-05-06 16:36:58.999978+00	2026-05-06 16:36:59.000132+00	2026-05-06 16:36:59.000132+00	[{"kind": "session", "id": "sess_cdce27c149bd4a59a301488b11878c34"}]	[{"kind": "policy", "value": "escalate risky or ambiguous actions"}]	{"kind": "autonomous_action", "domain": "system"}	systems-devops produced a autonomous_action plan.	reversible_internal_write	t
hnd_9dc4c267c7e24753ab241eef63e31a13	run_3693a49a498f4617a5ce949dcbf62c37	capture-router	work.generic	Capture classified as work	Classify capture cap_9e381bbd92c04332ac4759c958cfbe0b and apply policy.	[{"kind": "raw_capture", "id": "cap_9e381bbd92c04332ac4759c958cfbe0b", "uri": "raw/telegram/2026/05/06/te_cap_9e381bbd92c04332ac4759c958cfbe0b.md"}]	{"type": "review_item"}	returned	web	f	2026-05-06 16:41:20.355501+00	2026-05-06 16:41:20.355501+00	2026-05-06 16:41:20.355501+00	[]	[]	{}	\N	normal	t
\.


--
-- Data for Name: job_runs; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.job_runs (id, job_id, run_id, status, started_at, finished_at, output_summary_md, error_json, created_at) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.jobs (id, name, description_md, schedule_type, schedule_json, timezone, target_agent_id, command_json, approval_policy, enabled, created_by_user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: life_items; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.life_items (id, domain, item_type, title, description_md, status, priority, due_at, scheduled_at, source_capture_id, approved_state_change_id, metadata_json, created_at, updated_at) FROM stdin;
item_816661bc5c954734a99b8446e3c42c38	system	note	smoke test note: keep this as a low-risk LifeOS note	smoke test note: keep this as a low-risk LifeOS note	open	normal	\N	\N	\N	stchg_f02558b5d2ba4b4a97822671d8dcd585	{"source": "agent_session"}	2026-05-06 14:21:57.177375+00	2026-05-06 14:21:57.177375+00
item_d3c966e59c9148a9a13a8997ea9a5411	planning	note	hey	hey	open	normal	\N	\N	\N	stchg_9a3312324237425895a688c4bd0169ec	{"source": "agent_session"}	2026-05-06 14:42:10.05216+00	2026-05-06 14:42:10.05216+00
item_bbefd78c695c4821902b1ab5e6ba3364	system	note	smoke test note: keep this as a low-risk LifeOS note	smoke test note: keep this as a low-risk LifeOS note	open	normal	\N	\N	\N	stchg_228e886e0ca5499091af8f3a43e969d7	{"source": "agent_session"}	2026-05-06 14:44:29.912927+00	2026-05-06 14:44:29.912927+00
item_17ba033bb47544679227adbb85a0fc6f	system	note	smoke test note: keep this as a low-risk LifeOS note	smoke test note: keep this as a low-risk LifeOS note	open	normal	\N	\N	\N	stchg_206baced4e1c4bb7994738da59812a36	{"source": "agent_session"}	2026-05-06 14:46:57.384093+00	2026-05-06 14:46:57.384093+00
item_a96511a15683433395b49e3be2ea76b9	system	note	smoke test note: keep this as a low-risk LifeOS note	smoke test note: keep this as a low-risk LifeOS note	open	normal	\N	\N	\N	stchg_c74032dd191547628f8f491b643f6f91	{"source": "agent_session"}	2026-05-06 16:36:59.007107+00	2026-05-06 16:36:59.007107+00
\.


--
-- Data for Name: memory_candidates; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.memory_candidates (id, source_capture_id, proposed_by_agent_id, candidate_kind, statement_md, evidence_refs, confidence, sensitivity, status, review_item_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: memory_facts; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.memory_facts (id, fact_kind, statement_md, domain, confidence, sensitivity, status, source_candidate_id, evidence_refs, vault_uri, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.messages (id, session_id, run_id, role, content_md, content_json, source_platform, source_external_message_id, created_at, source_external_channel_id, source_external_thread_id, metadata_json) FROM stdin;
msg_4d47ae467b3a425cb5c626f2c2712d7e	sess_cdce27c149bd4a59a301488b11878c34	run_4b45891d111542fcb8958d612ce40a57	user	smoke test note: keep this as a low-risk LifeOS note	null	web	\N	2026-05-06 14:21:57.162741+00	smoke-test	\N	{"owner_authenticated": true, "smoke_test": true}
msg_5e831e6bdbb545c9a799ee4979cdd254	sess_cdce27c149bd4a59a301488b11878c34	run_4b45891d111542fcb8958d612ce40a57	assistant	Done.\n\nWhat I did:\n- Added this to LifeOS working state.\n- Kept the original session message as evidence.\n- No review card was needed.	{"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_e3f918e28c9f4dbcbd87631bb4dc6dce", "from_agent_id": "orchestrator", "to_agent_id": "systems-devops", "status": "completed", "summary_md": "systems-devops produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_f02558b5d2ba4b4a97822671d8dcd585", "entity_type": "life_item", "entity_id": "item_816661bc5c954734a99b8446e3c42c38", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_2174062b56084ba283aaa046634abf73"], "status_summary": "Auto-applied life_item.create"}	lifeos	\N	2026-05-06 14:21:57.178049+00	\N	\N	{}
msg_2ffae008a73248a8b9c8ee1bcbe54cd9	sess_0ac4fad62b6f44fba991498be03dcf91	run_012d4612d2b646289a60b301321711a7	user	hey	null	discord	test-msg-fk-fix-2	2026-05-06 14:42:10.03092+00	1501484172026314834	1500000000000000000	{"owner_authenticated": true, "probe": "discord-fk-fix"}
msg_0ec8e755b6114bd592f480644ec99699	sess_0ac4fad62b6f44fba991498be03dcf91	run_012d4612d2b646289a60b301321711a7	assistant	Done.\n\nWhat I did:\n- Added this to LifeOS working state.\n- Kept the original session message as evidence.\n- No review card was needed.	{"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_b853ef1fe07c411ba57827dc47556dee", "from_agent_id": "orchestrator", "to_agent_id": "daily-planner", "status": "completed", "summary_md": "daily-planner produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_9a3312324237425895a688c4bd0169ec", "entity_type": "life_item", "entity_id": "item_d3c966e59c9148a9a13a8997ea9a5411", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_86f2e207e8ee488887655678a92c1c78"], "status_summary": "Auto-applied life_item.create"}	lifeos	\N	2026-05-06 14:42:10.052892+00	\N	\N	{}
msg_e2e0ea3f0ada4e52b38b6d88b131a30f	sess_0ac4fad62b6f44fba991498be03dcf91	run_c34644edcdf04a2794276d98d2bc0cb6	user	hey	null	discord	test-msg-smalltalk-fix	2026-05-06 14:44:15.207134+00	1501484172026314834	1500000000000000000	{"owner_authenticated": true, "probe": "smalltalk-fix"}
msg_d54fa416ac04410ab852115659e44899	sess_0ac4fad62b6f44fba991498be03dcf91	run_c34644edcdf04a2794276d98d2bc0cb6	assistant	Hey. I am here.\n\nSend a task, note, question, or correction and I will route it through LifeOS.	{"status": "final", "final_message_md": "Hey. I am here.\\n\\nSend a task, note, question, or correction and I will route it through LifeOS.", "what_i_did_md": "- Answered directly from session context.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [], "autonomous_actions": [], "memory_candidates": [], "preference_candidates": [], "audit_refs": [], "status_summary": "Answered directly"}	lifeos	\N	2026-05-06 14:44:15.216057+00	\N	\N	{}
msg_f67e45fc88654beeb3a743fb112b0fe1	sess_cdce27c149bd4a59a301488b11878c34	run_5be33c728b6f445b8270d9c7591dffd4	user	smoke test note: keep this as a low-risk LifeOS note	null	web	\N	2026-05-06 14:44:29.895792+00	smoke-test	\N	{"owner_authenticated": true, "smoke_test": true}
msg_846f25ef4f744185a644360dee034a97	sess_cdce27c149bd4a59a301488b11878c34	run_5be33c728b6f445b8270d9c7591dffd4	assistant	Done.\n\nWhat I did:\n- Added this to LifeOS working state.\n- Kept the original session message as evidence.\n- No review card was needed.	{"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_6831a95626ef4c54b50961debf6b5573", "from_agent_id": "orchestrator", "to_agent_id": "systems-devops", "status": "completed", "summary_md": "systems-devops produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_228e886e0ca5499091af8f3a43e969d7", "entity_type": "life_item", "entity_id": "item_bbefd78c695c4821902b1ab5e6ba3364", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_1be0401f90bf484eaa3c393ff1ba598f"], "status_summary": "Auto-applied life_item.create"}	lifeos	\N	2026-05-06 14:44:29.914161+00	\N	\N	{}
msg_14a36731880a4b1abdc7ce2ed79d4bd8	sess_0ac4fad62b6f44fba991498be03dcf91	run_302229626b4a49a3abd02392c31173e3	user	hey	null	discord	test-msg-final-smalltalk	2026-05-06 14:46:45.042217+00	1501484172026314834	1500000000000000000	{"owner_authenticated": true, "probe": "final-smalltalk"}
msg_f3cc671222e64a9a98a42cac744c6906	sess_0ac4fad62b6f44fba991498be03dcf91	run_302229626b4a49a3abd02392c31173e3	assistant	Hey. I am here.\n\nSend a task, note, question, or correction and I will route it through LifeOS.	{"status": "final", "final_message_md": "Hey. I am here.\\n\\nSend a task, note, question, or correction and I will route it through LifeOS.", "what_i_did_md": "- Answered directly from session context.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [], "autonomous_actions": [], "memory_candidates": [], "preference_candidates": [], "audit_refs": [], "status_summary": "Answered directly"}	lifeos	\N	2026-05-06 14:46:45.052186+00	\N	\N	{}
msg_84e60bf05573456c9a41f2f8585beef0	sess_cdce27c149bd4a59a301488b11878c34	run_0bf80e9c8ca347a3bf750b152ae62104	user	smoke test note: keep this as a low-risk LifeOS note	null	web	\N	2026-05-06 14:46:57.369192+00	smoke-test	\N	{"owner_authenticated": true, "smoke_test": true}
msg_3d206d7bd3814cfd84317497a6ab038d	sess_cdce27c149bd4a59a301488b11878c34	run_0bf80e9c8ca347a3bf750b152ae62104	assistant	Done.\n\nWhat I did:\n- Added this to LifeOS working state.\n- Kept the original session message as evidence.\n- No review card was needed.	{"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_fb75f1ed6649422082f873725e2a8724", "from_agent_id": "orchestrator", "to_agent_id": "systems-devops", "status": "completed", "summary_md": "systems-devops produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_206baced4e1c4bb7994738da59812a36", "entity_type": "life_item", "entity_id": "item_17ba033bb47544679227adbb85a0fc6f", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_125555355a824ce6ba967252544f3572"], "status_summary": "Auto-applied life_item.create"}	lifeos	\N	2026-05-06 14:46:57.384875+00	\N	\N	{}
msg_73a6a92ea7ac432799b5b421cccd3a71	sess_cdce27c149bd4a59a301488b11878c34	run_659f6b5faf754c14a5a9b65d85491860	user	smoke test note: keep this as a low-risk LifeOS note	null	web	\N	2026-05-06 16:36:58.989572+00	smoke-test	\N	{"owner_authenticated": true, "smoke_test": true}
msg_adc96960f75744c590684f586e45d2c6	sess_cdce27c149bd4a59a301488b11878c34	run_659f6b5faf754c14a5a9b65d85491860	assistant	Done.\n\nWhat I did:\n- Added this to LifeOS working state.\n- Kept the original session message as evidence.\n- No review card was needed.	{"status": "final", "final_message_md": "Done.\\n\\nWhat I did:\\n- Added this to LifeOS working state.\\n- Kept the original session message as evidence.\\n- No review card was needed.", "what_i_did_md": "- Added this to LifeOS working state.\\n- Preserved the session message.\\n- Audited the state change.", "review_item_id": null, "clarifying_questions": [], "tool_calls": [], "handoffs": [{"handoff_id": "hnd_97d5c650d3b34e7fbeadc22eaae6ba2a", "from_agent_id": "orchestrator", "to_agent_id": "systems-devops", "status": "completed", "summary_md": "systems-devops produced a autonomous_action plan."}], "autonomous_actions": [{"command_type": "life_item.create", "state_change_id": "stchg_c74032dd191547628f8f491b643f6f91", "entity_type": "life_item", "entity_id": "item_a96511a15683433395b49e3be2ea76b9", "status": "applied"}], "memory_candidates": [], "preference_candidates": [], "audit_refs": ["audit_52c41d69e0fb4ccfb1a469ea563764cf"], "status_summary": "Auto-applied life_item.create"}	lifeos	\N	2026-05-06 16:36:59.008145+00	\N	\N	{}
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.notifications (id, target_platform, target_channel_id, notification_type, title, body_md, status, related_run_id, related_review_item_id, external_message_id, error_json, created_at, sent_at) FROM stdin;
notif_4e37fd48ecce4c54a897e7d40f68808d	discord	\N	review.created	Memory candidate	Possible durable memory candidate:\n\n> /start	queued	run_e74bd4a2fa7446dfb8681f1ff1c95902	rev_6e4c341e3b2f4028aa1e93ee4964b523	\N	null	2026-05-06 11:22:29.209022+00	\N
notif_d3e075fbb4774b3f8dde707628374e4d	discord	\N	review.created	Memory candidate	Possible durable memory candidate:\n\n> Hello	queued	run_4927bce4bff6431299a248cb3fbb4eb3	rev_03a930b12fc04d35be6b04808654c1b9	\N	null	2026-05-06 11:23:32.746568+00	\N
notif_aa6870d935a142ed9742b63cf2d03b11	discord	\N	review.created	Work task candidate	AI draft from capture:\n\n> I need to finish working on that subject proposal and talk to the teacher about it\n\nProposed work task: **I need to finish working on that subject proposal and talk to the teacher about**	queued	run_c3f5d9dfe2a341028ceb17dd598b323c	rev_594064f782564be099ad83986664a389	\N	null	2026-05-06 11:25:24.376647+00	\N
notif_5bf24493a7ad4a0888043a14b8c7587e	discord	\N	review.created	Memory candidate	Possible durable memory candidate:\n\n> random thought: smoke test raw note	queued	run_e4d19a1c2cd84b799d1dde6ce4d56501	rev_557dfe60ff294f5d84b7328dd6f24892	\N	null	2026-05-06 12:02:05.003737+00	\N
notif_49e75706f23942b9bbf3c1e0d80749ee	discord	\N	review.created	Finance entry candidate	Parsed finance capture:\n\n> I spent 40 MAD on lunch\n\nAmount: **40.0 MAD**	queued	run_f9e31bcd6aef4773b98f1ef9895e9539	rev_aeeef449e2f44a3896a93b29270dc4e1	\N	null	2026-05-06 12:03:01.634849+00	\N
notif_91868d82afd14e1b9bd2bfccbfda8a86	discord	\N	review.created	Finance entry candidate	Parsed finance capture:\n\n> I spent 40 MAD on lunch\n\nAmount: **40.0 MAD**	queued	run_4d6dd79f17454ba38768b05f28b68a88	rev_1da6d0d84419441ebc38a0b63b5b4161	\N	null	2026-05-06 12:05:07.019443+00	\N
notif_fa0d87c6b83f429d9232933084f3a6a4	discord	\N	review.created	Finance entry candidate	Parsed finance capture:\n\n> I spent 40 MAD on lunch\n\nAmount: **40.0 MAD**	queued	run_85a510d22a384fb08a5059e122375ffc	rev_d34c75e9b21b45cabfded6a683413cb8	\N	null	2026-05-06 14:21:57.111394+00	\N
notif_985ec6b154fc4a70a228f19f9c19f5a2	discord	\N	review.created	Finance entry candidate	Parsed finance capture:\n\n> I spent 40 MAD on lunch\n\nAmount: **40.0 MAD**	queued	run_f5274948c59a477186830dc802a2f480	rev_323749ef15024188a89808aab7660c3e	\N	null	2026-05-06 14:44:29.846948+00	\N
notif_5686ab77c7024f4eb53b161b43c44cb9	discord	\N	review.created	Finance entry candidate	Parsed finance capture:\n\n> I spent 40 MAD on lunch\n\nAmount: **40.0 MAD**	queued	run_fbb633d89ecd42939345b18887ef347c	rev_80875aa15ccc4fbd93bf7ddd67bc0d5e	\N	null	2026-05-06 14:46:57.318947+00	\N
notif_b9ddf7c491cb4e1e8eb521d5a1037ff9	discord	\N	review.created	Finance entry candidate	Parsed finance capture:\n\n> I spent 40 MAD on lunch\n\nAmount: **40.0 MAD**	queued	run_b4c2536243be496da016b4bb8cb57f6d	rev_c4bedd5084d044c29220cced23e64dbb	\N	null	2026-05-06 16:36:58.910534+00	\N
\.


--
-- Data for Name: prayer_logs; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.prayer_logs (id, user_id, local_date, prayer, status, source_platform, source_external_message_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: provider_call_logs; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.provider_call_logs (id, run_id, agent_id, provider_id, model, key_label, status, latency_ms, input_tokens, output_tokens, cost_usd, error_json, created_at) FROM stdin;
pcall_a4447a952c7a4ca7b72b49bbf3026876	run_787fd5a401604cb2b902e17cd28bea33	capture-router	unavailable	capture-router	\N	failed	0	0	0	0	{"type": "RuntimeError", "message": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}"}	2026-05-06 12:03:01.612591+00
pcall_c15949a50dc04246a3bc2b5c2928afc7	run_f9e31bcd6aef4773b98f1ef9895e9539	capture-router	unavailable	capture-router	\N	failed	0	0	0	0	{"type": "RuntimeError", "message": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}"}	2026-05-06 12:03:01.778157+00
pcall_b8fc3942fc874c478b2ce52133f546fd	run_ecf75fb7fc0048e29e8d71a65f430268	capture-router	unavailable	capture-router	\N	failed	0	0	0	0	{"type": "RuntimeError", "message": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}"}	2026-05-06 12:05:06.998087+00
pcall_8b946aba46654057a3c56d8a2dd22af5	run_4d6dd79f17454ba38768b05f28b68a88	capture-router	unavailable	capture-router	\N	failed	0	0	0	0	{"type": "RuntimeError", "message": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}"}	2026-05-06 12:05:07.159827+00
pcall_5e2af3b336d04258b106c2e26c8b0698	\N	\N	codex_oauth	health-check	\N	configured	0	0	0	0	null	2026-05-06 12:06:37.173523+00
pcall_a041ce2e6d2e46d0ba57c277aa6f5de6	run_92047b1a038942578f8c80933d38bca7	capture-router	unavailable	capture-router	\N	failed	0	0	0	0	{"type": "RuntimeError", "message": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}"}	2026-05-06 12:54:03.734598+00
pcall_b251089fb0dd447fb364eb655496ccd2	run_4485b6600ee641c8b6abd6e4c797ebee	work.generic	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	primary	succeeded	29747	287	480	0	null	2026-05-06 14:21:44.694854+00
pcall_a72a1bba61c04038a0ead33e06c20959	run_3693a49a498f4617a5ce949dcbf62c37	work.generic	nvidia_nim	nvidia/nemotron-3-super-120b-a12b	primary	succeeded	9687	282	462	0	null	2026-05-06 16:41:30.532896+00
\.


--
-- Data for Name: provider_runtime_configs; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.provider_runtime_configs (id, provider_id, display_name, provider_type, base_url, enabled, key_refs_json, settings_json, created_at, updated_at) FROM stdin;
prov_954209aed1c04fea84c8996061582940	openrouter	OpenRouter	openai_compatible	https://openrouter.ai/api/v1	t	[{"env": "OPENROUTER_API_KEY_1", "label": "primary", "priority": 10}, {"env": "OPENROUTER_API_KEY_2", "label": "backup", "priority": 20}]	{"request_defaults": {"timeout_seconds": 90, "retries": 1, "headers": {"HTTP-Referer": "https://lifeos.local", "X-Title": "LifeOS vNext"}}, "provider_fallback": {"enabled": true}, "model_fallback": {"enabled": true, "use_openrouter_models_array": true}}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
prov_dd10cdb6fbc9469196d8cd66713dbfa2	nvidia_nim	NVIDIA NIM	openai_compatible	https://integrate.api.nvidia.com/v1	t	[{"env": "NVIDIA_NIM_API_KEY_1", "label": "primary", "priority": 10}, {"env": "NVIDIA_NIM_API_KEY_2", "label": "backup", "priority": 20}]	{"health": {"enabled": true, "ready_endpoint": "/v1/health/ready", "models_endpoint": "/v1/models"}, "request_defaults": {"timeout_seconds": 90, "retries": 1}}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
prov_d3841aa987c94d8880a18e535075b1da	codex_oauth	OpenAI Codex OAuth	codex_cli	\N	t	[]	{"use_for": ["coding", "repo_edits", "tests", "systems_devops"], "execution": {"mode": "sandboxed_cli", "command": "codex exec", "require_workspace_scope": true, "require_approval_for": ["file_write", "terminal_command", "git_commit", "deploy"]}}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
\.


--
-- Data for Name: raw_captures; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.raw_captures (id, source_platform, source_external_message_id, source_thread_id, capture_kind, raw_text, raw_uri, content_hash, status, sensitivity, received_at, created_at, updated_at, source_channel_id, source_user_id) FROM stdin;
cap_8015f24b491c47abb1c379f28522d5dd	telegram	1	\N	text	/start	raw/telegram/2026/05/06/te_cap_8015f24b491c47abb1c379f28522d5dd.md	addd004f31947e62d9fe891b9b69ab2078ae3f41de0bf73749152f15b4920401	routed	normal	2026-05-06 11:22:29.208995+00	2026-05-06 11:22:29.209022+00	2026-05-06 11:22:29.209022+00	\N	\N
cap_e68e6163c02a478a9a6a553de44cf0fc	telegram	3	\N	text	Hello	raw/telegram/2026/05/06/te_cap_e68e6163c02a478a9a6a553de44cf0fc.md	521f3d71d714491fea94d2f7d9770343c30f8385cd27c006fd48a644fa0b6125	routed	normal	2026-05-06 11:23:32.746541+00	2026-05-06 11:23:32.746568+00	2026-05-06 11:23:32.746568+00	\N	\N
cap_47cac0ac72864934bbc418e19b4d58a8	telegram	5	\N	text	I need to finish working on that subject proposal and talk to the teacher about it	raw/telegram/2026/05/06/te_cap_47cac0ac72864934bbc418e19b4d58a8.md	711e8ec38e676f1514dbc1b27eec0f9065183f35b8db0bcec1c2ac956fcd7d8d	routed	normal	2026-05-06 11:25:24.376625+00	2026-05-06 11:25:24.376647+00	2026-05-06 11:25:24.376647+00	\N	\N
cap_4d62c7dcfedc4907a27f8952f4c5054b	web	\N	\N	text	random thought: smoke test raw note	raw/web/2026/05/06/we_cap_4d62c7dcfedc4907a27f8952f4c5054b.md	338fb67bfe5001cbc8ebaf193d86220ef9a68ccc0f5dbb488b4abe2f9ab75ea8	routed	normal	2026-05-06 12:02:05.003698+00	2026-05-06 12:02:05.003737+00	2026-05-06 12:02:05.003737+00	\N	\N
cap_2f464156a4384621921149d4586807d3	web	\N	\N	text	random thought: smoke test raw note	raw/web/2026/05/06/we_cap_2f464156a4384621921149d4586807d3.md	aee9a76c5923ab9ec6ca9bdd5e82a8e0cff8a5bc13c6325aa1f44a51425b3a10	raw_only	normal	2026-05-06 12:03:00.707554+00	2026-05-06 12:03:00.707578+00	2026-05-06 12:03:00.707578+00	\N	\N
cap_ca43ce4689da485a923a16124f148ebc	web	\N	\N	text	I spent 40 MAD on lunch	raw/web/2026/05/06/we_cap_ca43ce4689da485a923a16124f148ebc.md	59d139d4f9836e732bffdad11db746c711b21dd2770bee1f2320d8d27124c6e8	waiting_approval	finance	2026-05-06 12:03:01.634827+00	2026-05-06 12:03:01.634849+00	2026-05-06 12:03:01.634849+00	\N	\N
cap_db6e45e9c04943bc85bf9d0ee436aeff	web	\N	\N	text	random thought: smoke test raw note	raw/web/2026/05/06/we_cap_db6e45e9c04943bc85bf9d0ee436aeff.md	d7f4c8140f5594a295072120ee6f632668cf4ffefbacaee6e759eeda350ff26c	raw_only	normal	2026-05-06 12:05:06.676914+00	2026-05-06 12:05:06.676937+00	2026-05-06 12:05:06.676937+00	\N	\N
cap_d75ec0874b1a4ac7abcca69658396ac5	web	\N	\N	text	I spent 40 MAD on lunch	raw/web/2026/05/06/we_cap_d75ec0874b1a4ac7abcca69658396ac5.md	04a4c5122c70233d54d9389a0995334b689026554dc9b5a8eb70781045efc2e0	waiting_approval	finance	2026-05-06 14:44:29.846925+00	2026-05-06 14:44:29.846948+00	2026-05-06 14:44:29.846948+00	\N	\N
cap_655320e1513b457181a225065ec8cec3	web	\N	\N	text	I spent 40 MAD on lunch	raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md	b9d3999151f03a61eb50629284a678efb00fc013e659f9209ddfb2eed63a074c	waiting_approval	finance	2026-05-06 12:05:07.019422+00	2026-05-06 12:05:07.019443+00	2026-05-06 12:05:07.019443+00	\N	\N
cap_03e86c5ff77b4c6bb3bc0e4251886617	telegram	7	\N	text	Hello	raw/telegram/2026/05/06/te_cap_03e86c5ff77b4c6bb3bc0e4251886617.md	13ad51b070249f74c2f8657e5f55e587b41259f2ed8aa3123d49a9b0917cdd0c	raw_only	normal	2026-05-06 12:54:03.396491+00	2026-05-06 12:54:03.396517+00	2026-05-06 12:54:03.396517+00	\N	\N
cap_a57b14d51ecf4c29af3c014ee2325d24	web	\N	\N	text	random thought: smoke test raw note	raw/web/2026/05/06/we_cap_a57b14d51ecf4c29af3c014ee2325d24.md	167a323b131ab1453ab1459ab2ca779f00b0cda35971a35ebb6b10ea1113146f	raw_only	normal	2026-05-06 14:21:14.05513+00	2026-05-06 14:21:14.05516+00	2026-05-06 14:21:14.05516+00	\N	\N
cap_3f2ae3aa5ff54b5999e88b5a5697b393	web	\N	\N	text	random thought: smoke test raw note	raw/web/2026/05/06/we_cap_3f2ae3aa5ff54b5999e88b5a5697b393.md	656ae0006a4e81b7cf1241641a6942a41ab203c731ea4ced6d1a8fbebd3d58c8	raw_only	normal	2026-05-06 14:21:57.096656+00	2026-05-06 14:21:57.096676+00	2026-05-06 14:21:57.096676+00	\N	\N
cap_ea5c084b450b45d2ab768ab91562d157	web	\N	\N	text	I spent 40 MAD on lunch	raw/web/2026/05/06/we_cap_ea5c084b450b45d2ab768ab91562d157.md	4feaaf244b4990781969735abe3028eb18ea551e0963a4ae16821e2cc042263d	waiting_approval	finance	2026-05-06 14:21:57.111376+00	2026-05-06 14:21:57.111394+00	2026-05-06 14:21:57.111394+00	\N	\N
cap_454daf5c601d4bd3b68798c4e5483279	web	\N	\N	text	random thought: smoke test raw note	raw/web/2026/05/06/we_cap_454daf5c601d4bd3b68798c4e5483279.md	2f12f0f85aac2d426988dc383de58ecc299524376b00dadc367febbcb03bbe72	raw_only	normal	2026-05-06 14:44:29.820172+00	2026-05-06 14:44:29.820195+00	2026-05-06 14:44:29.820195+00	\N	\N
cap_93390c37a92b44d697ed8bbaefbeaf56	web	\N	\N	text	random thought: smoke test raw note	raw/web/2026/05/06/we_cap_93390c37a92b44d697ed8bbaefbeaf56.md	1de1f8c9e1be417a8535aa42685b6efd0a5acbf116a0e95c4bcbbb73fc2ccb2e	raw_only	normal	2026-05-06 14:46:57.292689+00	2026-05-06 14:46:57.292724+00	2026-05-06 14:46:57.292724+00	\N	\N
cap_9e381bbd92c04332ac4759c958cfbe0b	telegram	9	\N	text	Hello	raw/telegram/2026/05/06/te_cap_9e381bbd92c04332ac4759c958cfbe0b.md	30c4a5da69c5b13d22df3e5d7a7ce1a0e21bf3da1b8ba004bc032b73843456e3	raw_only	normal	2026-05-06 16:41:20.355479+00	2026-05-06 16:41:20.355501+00	2026-05-06 16:41:20.355501+00	\N	\N
cap_23a9118878c64d9f90f05d8b985d730a	web	\N	\N	text	I spent 40 MAD on lunch	raw/web/2026/05/06/we_cap_23a9118878c64d9f90f05d8b985d730a.md	ae89d65ad76d0fded1424aa6c656a0a62092812e2521001393af7aa5f110c7d6	waiting_approval	finance	2026-05-06 14:46:57.318925+00	2026-05-06 14:46:57.318947+00	2026-05-06 14:46:57.318947+00	\N	\N
cap_7bd059b3793e459f9af461b29c254e6f	web	\N	\N	text	random thought: smoke test raw note	raw/web/2026/05/06/we_cap_7bd059b3793e459f9af461b29c254e6f.md	80b7f01a1a57b6b7973ca3176c088856dbe87f26f0508632d85d7b4e9ef25098	raw_only	normal	2026-05-06 16:36:58.882776+00	2026-05-06 16:36:58.882798+00	2026-05-06 16:36:58.882798+00	\N	\N
cap_1815c12243574fd185773ba74a944a50	web	\N	\N	text	I spent 40 MAD on lunch	raw/web/2026/05/06/we_cap_1815c12243574fd185773ba74a944a50.md	925183217d91907151942298102ff3ef59130f910feb398a161e99865480cdca	waiting_approval	finance	2026-05-06 16:36:58.910514+00	2026-05-06 16:36:58.910534+00	2026-05-06 16:36:58.910534+00	\N	\N
\.


--
-- Data for Name: review_bindings; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.review_bindings (id, review_item_id, platform, channel_id, external_message_id, external_thread_id, card_version, created_at) FROM stdin;
\.


--
-- Data for Name: review_decisions; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.review_decisions (id, review_item_id, user_id, decision, decision_text, decision_payload, source_platform, source_external_message_id, created_at) FROM stdin;
dec_1ffd8ab2a0c848408d4ee615d5e03361	rev_aeeef449e2f44a3896a93b29270dc4e1	\N	reject	\N	{}	api	\N	2026-05-06 12:03:01.800886+00
dec_3bce280e6890401688d134e5a10739e7	rev_1da6d0d84419441ebc38a0b63b5b4161	\N	reject	\N	{}	api	\N	2026-05-06 12:05:07.18718+00
dec_1662bd77950446d88f3e27671f1eaf3e	rev_6e4c341e3b2f4028aa1e93ee4964b523	\N	reject	\N	{}	web	\N	2026-05-06 12:07:05.069161+00
dec_3e0bbf00ce0e4f36b966aff8ba95f5fd	rev_03a930b12fc04d35be6b04808654c1b9	\N	reject	\N	{}	web	\N	2026-05-06 12:07:07.829504+00
dec_8a90a256e7784ac7a8c08d6c77c10fd9	rev_594064f782564be099ad83986664a389	\N	reject	\N	{}	web	\N	2026-05-06 12:07:13.583001+00
dec_e63441ac09eb42b5a820748d70e7277f	rev_557dfe60ff294f5d84b7328dd6f24892	\N	reject	\N	{}	web	\N	2026-05-06 12:07:16.997925+00
dec_fc2ecc0ad2194b999839ed744fa59602	rev_aeeef449e2f44a3896a93b29270dc4e1	\N	reject	\N	{}	web	\N	2026-05-06 12:07:18.452418+00
dec_dca39c1211744e2fadfbce2d5980a650	rev_1da6d0d84419441ebc38a0b63b5b4161	\N	reject	\N	{}	web	\N	2026-05-06 12:07:19.47004+00
dec_ce60c4d3da71411ea6372ad88e6aefd6	rev_1da6d0d84419441ebc38a0b63b5b4161	\N	reject	\N	{}	web	\N	2026-05-06 12:53:32.266048+00
dec_7e5ec60e030d4e1982723b06b5128ebb	rev_1da6d0d84419441ebc38a0b63b5b4161	\N	done	\N	{}	web	\N	2026-05-06 12:53:34.16124+00
dec_4757496e086345b882083df4eb55747a	rev_1da6d0d84419441ebc38a0b63b5b4161	\N	done	\N	{}	web	\N	2026-05-06 12:53:34.977573+00
dec_f90e29eef9c8485182a40878df9b3d4a	rev_1da6d0d84419441ebc38a0b63b5b4161	\N	done	\N	{}	web	\N	2026-05-06 12:53:35.593235+00
dec_8c9664bf7a034c8ea195dccf3b015149	rev_1da6d0d84419441ebc38a0b63b5b4161	\N	reject	\N	{}	web	\N	2026-05-06 12:53:36.760155+00
dec_ab4535dec66d4fb4acb87ccbce108342	rev_d34c75e9b21b45cabfded6a683413cb8	\N	reject	\N	{}	api	\N	2026-05-06 14:21:57.141441+00
dec_1aaaeab42d48472a963467cf1610a3ce	rev_d34c75e9b21b45cabfded6a683413cb8	\N	reject	\N	{}	web	\N	2026-05-06 14:32:16.799766+00
dec_0c327c733ae14cc299f831a09c7a799e	rev_d34c75e9b21b45cabfded6a683413cb8	\N	reject	\N	{}	web	\N	2026-05-06 14:32:18.281086+00
dec_f5fc508d5e014f5b94d99993ffaa30e6	rev_323749ef15024188a89808aab7660c3e	\N	reject	\N	{}	api	\N	2026-05-06 14:44:29.8779+00
dec_1650f1b4a1ef473c8058a4bd4171cb94	rev_80875aa15ccc4fbd93bf7ddd67bc0d5e	\N	reject	\N	{}	api	\N	2026-05-06 14:46:57.351309+00
dec_aa9982c4bc0d4783a5b2421f9d33ddba	rev_c4bedd5084d044c29220cced23e64dbb	\N	reject	\N	{}	api	\N	2026-05-06 16:36:58.93664+00
\.


--
-- Data for Name: review_items; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.review_items (id, kind, title, body_md, source_capture_id, proposed_by_agent_id, assigned_agent_id, priority, confidence, risk_level, sensitivity, proposed_action_json, validation_json, status, expires_at, snoozed_until, created_at, updated_at, source_uri) FROM stdin;
rev_6e4c341e3b2f4028aa1e93ee4964b523	memory	Memory candidate	Possible durable memory candidate:\n\n> /start	cap_8015f24b491c47abb1c379f28522d5dd	memory-curator	approval-manager	normal	0.61999999999999999555910790149937383830547332763671875	durable_memory_write	normal	{"command_type": "memory_fact.create", "risk_level": "durable_memory_write", "payload": {"fact_kind": "note", "domain": "planning", "statement_md": "/start", "confidence": 0.62, "sensitivity": "normal", "evidence_refs": [{"kind": "raw_capture", "id": "cap_8015f24b491c47abb1c379f28522d5dd"}]}}	{"missing_context": []}	rejected	\N	\N	2026-05-06 11:22:29.209022+00	2026-05-06 12:07:05.069161+00	raw/telegram/2026/05/06/te_cap_8015f24b491c47abb1c379f28522d5dd.md
rev_03a930b12fc04d35be6b04808654c1b9	memory	Memory candidate	Possible durable memory candidate:\n\n> Hello	cap_e68e6163c02a478a9a6a553de44cf0fc	memory-curator	approval-manager	normal	0.61999999999999999555910790149937383830547332763671875	durable_memory_write	normal	{"command_type": "memory_fact.create", "risk_level": "durable_memory_write", "payload": {"fact_kind": "note", "domain": "planning", "statement_md": "Hello", "confidence": 0.62, "sensitivity": "normal", "evidence_refs": [{"kind": "raw_capture", "id": "cap_e68e6163c02a478a9a6a553de44cf0fc"}]}}	{"missing_context": []}	rejected	\N	\N	2026-05-06 11:23:32.746568+00	2026-05-06 12:07:07.829504+00	raw/telegram/2026/05/06/te_cap_e68e6163c02a478a9a6a553de44cf0fc.md
rev_594064f782564be099ad83986664a389	work	Work task candidate	AI draft from capture:\n\n> I need to finish working on that subject proposal and talk to the teacher about it\n\nProposed work task: **I need to finish working on that subject proposal and talk to the teacher about**	cap_47cac0ac72864934bbc418e19b4d58a8	work.generic	approval-manager	normal	0.7600000000000000088817841970012523233890533447265625	durable_state_mutation	normal	{"command_type": "life_item.create", "risk_level": "durable_state_mutation", "payload": {"domain": "work", "item_type": "task", "title": "I need to finish working on that subject proposal and talk to the teacher about", "description_md": "I need to finish working on that subject proposal and talk to the teacher about it", "priority": "normal", "status": "open", "source_capture_id": "cap_47cac0ac72864934bbc418e19b4d58a8"}}	{"missing_context": []}	rejected	\N	\N	2026-05-06 11:25:24.376647+00	2026-05-06 12:07:13.583001+00	raw/telegram/2026/05/06/te_cap_47cac0ac72864934bbc418e19b4d58a8.md
rev_557dfe60ff294f5d84b7328dd6f24892	memory	Memory candidate	Possible durable memory candidate:\n\n> random thought: smoke test raw note	cap_4d62c7dcfedc4907a27f8952f4c5054b	memory-curator	approval-manager	normal	0.61999999999999999555910790149937383830547332763671875	durable_memory_write	normal	{"command_type": "memory_fact.create", "risk_level": "durable_memory_write", "payload": {"fact_kind": "note", "domain": "planning", "statement_md": "random thought: smoke test raw note", "confidence": 0.62, "sensitivity": "normal", "evidence_refs": [{"kind": "raw_capture", "id": "cap_4d62c7dcfedc4907a27f8952f4c5054b"}]}}	{"missing_context": []}	rejected	\N	\N	2026-05-06 12:02:05.003737+00	2026-05-06 12:07:16.997925+00	raw/web/2026/05/06/we_cap_4d62c7dcfedc4907a27f8952f4c5054b.md
rev_aeeef449e2f44a3896a93b29270dc4e1	finance	Finance entry candidate	Parsed finance capture:\n\n> I spent 40 MAD on lunch\n\nAmount: **40.0 MAD**	cap_ca43ce4689da485a923a16124f148ebc	finance	approval-manager	normal	0.7399999999999999911182158029987476766109466552734375	finance_mutation	finance	{"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ca43ce4689da485a923a16124f148ebc"}}	{"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}	rejected	\N	\N	2026-05-06 12:03:01.634849+00	2026-05-06 12:07:18.452418+00	raw/web/2026/05/06/we_cap_ca43ce4689da485a923a16124f148ebc.md
rev_1da6d0d84419441ebc38a0b63b5b4161	finance	Finance entry candidate	Parsed finance capture:\n\n> I spent 40 MAD on lunch\n\nAmount: **40.0 MAD**	cap_655320e1513b457181a225065ec8cec3	finance	approval-manager	normal	0.7399999999999999911182158029987476766109466552734375	finance_mutation	finance	{"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_655320e1513b457181a225065ec8cec3"}}	{"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}	rejected	\N	\N	2026-05-06 12:05:07.019443+00	2026-05-06 12:53:36.760155+00	raw/web/2026/05/06/we_cap_655320e1513b457181a225065ec8cec3.md
rev_323749ef15024188a89808aab7660c3e	finance	Finance entry candidate	Parsed finance capture:\n\n> I spent 40 MAD on lunch\n\nAmount: **40.0 MAD**	cap_d75ec0874b1a4ac7abcca69658396ac5	finance	approval-manager	normal	0.7399999999999999911182158029987476766109466552734375	finance_mutation	finance	{"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_d75ec0874b1a4ac7abcca69658396ac5"}}	{"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}	rejected	\N	\N	2026-05-06 14:44:29.846948+00	2026-05-06 14:44:29.8779+00	raw/web/2026/05/06/we_cap_d75ec0874b1a4ac7abcca69658396ac5.md
rev_d34c75e9b21b45cabfded6a683413cb8	finance	Finance entry candidate	Parsed finance capture:\n\n> I spent 40 MAD on lunch\n\nAmount: **40.0 MAD**	cap_ea5c084b450b45d2ab768ab91562d157	finance	approval-manager	normal	0.7399999999999999911182158029987476766109466552734375	finance_mutation	finance	{"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_ea5c084b450b45d2ab768ab91562d157"}}	{"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}	rejected	\N	\N	2026-05-06 14:21:57.111394+00	2026-05-06 14:32:18.281086+00	raw/web/2026/05/06/we_cap_ea5c084b450b45d2ab768ab91562d157.md
rev_80875aa15ccc4fbd93bf7ddd67bc0d5e	finance	Finance entry candidate	Parsed finance capture:\n\n> I spent 40 MAD on lunch\n\nAmount: **40.0 MAD**	cap_23a9118878c64d9f90f05d8b985d730a	finance	approval-manager	normal	0.7399999999999999911182158029987476766109466552734375	finance_mutation	finance	{"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_23a9118878c64d9f90f05d8b985d730a"}}	{"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}	rejected	\N	\N	2026-05-06 14:46:57.318947+00	2026-05-06 14:46:57.351309+00	raw/web/2026/05/06/we_cap_23a9118878c64d9f90f05d8b985d730a.md
rev_c4bedd5084d044c29220cced23e64dbb	finance	Finance entry candidate	Parsed finance capture:\n\n> I spent 40 MAD on lunch\n\nAmount: **40.0 MAD**	cap_1815c12243574fd185773ba74a944a50	finance	approval-manager	normal	0.7399999999999999911182158029987476766109466552734375	finance_mutation	finance	{"command_type": "finance_entry.create", "risk_level": "finance_mutation", "payload": {"entry_type": "expense", "amount": 40.0, "currency": "MAD", "category": "uncategorized", "note_md": "I spent 40 MAD on lunch", "source_capture_id": "cap_1815c12243574fd185773ba74a944a50"}}	{"missing_context": [], "policy": {"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}}	rejected	\N	\N	2026-05-06 16:36:58.910534+00	2026-05-06 16:36:58.93664+00	raw/web/2026/05/06/we_cap_1815c12243574fd185773ba74a944a50.md
\.


--
-- Data for Name: state_changes; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.state_changes (id, review_item_id, command_type, command_payload, status, applied_by, before_snapshot_uri, after_snapshot_uri, error_json, created_at, applied_at) FROM stdin;
stchg_f02558b5d2ba4b4a97822671d8dcd585	\N	life_item.create	{"domain": "system", "item_type": "note", "title": "smoke test note: keep this as a low-risk LifeOS note", "description_md": "smoke test note: keep this as a low-risk LifeOS note", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}	applied	systems-devops	\N	state/tasks.md	null	2026-05-06 14:21:57.174821+00	2026-05-06 14:21:57.177837+00
stchg_9a3312324237425895a688c4bd0169ec	\N	life_item.create	{"domain": "planning", "item_type": "note", "title": "hey", "description_md": "hey", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}	applied	daily-planner	\N	state/tasks.md	null	2026-05-06 14:42:10.048956+00	2026-05-06 14:42:10.052632+00
stchg_228e886e0ca5499091af8f3a43e969d7	\N	life_item.create	{"domain": "system", "item_type": "note", "title": "smoke test note: keep this as a low-risk LifeOS note", "description_md": "smoke test note: keep this as a low-risk LifeOS note", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}	applied	systems-devops	\N	state/tasks.md	null	2026-05-06 14:44:29.910056+00	2026-05-06 14:44:29.913733+00
stchg_206baced4e1c4bb7994738da59812a36	\N	life_item.create	{"domain": "system", "item_type": "note", "title": "smoke test note: keep this as a low-risk LifeOS note", "description_md": "smoke test note: keep this as a low-risk LifeOS note", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}	applied	systems-devops	\N	state/tasks.md	null	2026-05-06 14:46:57.381205+00	2026-05-06 14:46:57.384571+00
stchg_c74032dd191547628f8f491b643f6f91	\N	life_item.create	{"domain": "system", "item_type": "note", "title": "smoke test note: keep this as a low-risk LifeOS note", "description_md": "smoke test note: keep this as a low-risk LifeOS note", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}	applied	systems-devops	\N	state/tasks.md	null	2026-05-06 16:36:59.004479+00	2026-05-06 16:36:59.007922+00
\.


--
-- Data for Name: status_events; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.status_events (id, run_id, event_type, visibility, title, detail_json, created_at) FROM stdin;
evt_20b99da45b634efdb0854ce6fbc04107	run_e74bd4a2fa7446dfb8681f1ff1c95902	capture.received	discord_compact	Received capture	{"capture_id": "cap_8015f24b491c47abb1c379f28522d5dd"}	2026-05-06 11:22:29.223861+00
evt_57762f8bd26d41888daa5207333bd704	run_e74bd4a2fa7446dfb8681f1ff1c95902	agent.handoff_created	discord_compact	Capture Router -> memory-curator	{"handoff_id": "hnd_00967586139542c394a6839b97709dd8"}	2026-05-06 11:22:29.223918+00
evt_4676118a092d460db4c9b89ebae2ecb3	run_e74bd4a2fa7446dfb8681f1ff1c95902	review.created	discord_compact	Review created: Memory candidate	{"review_item_id": "rev_6e4c341e3b2f4028aa1e93ee4964b523"}	2026-05-06 11:22:29.223949+00
evt_b8d44a6ad7c04e25a362ddef612e4c1c	run_4927bce4bff6431299a248cb3fbb4eb3	capture.received	discord_compact	Received capture	{"capture_id": "cap_e68e6163c02a478a9a6a553de44cf0fc"}	2026-05-06 11:23:32.754247+00
evt_2b4f8290316e410c9d6b69c95d6f7252	run_4927bce4bff6431299a248cb3fbb4eb3	agent.handoff_created	discord_compact	Capture Router -> memory-curator	{"handoff_id": "hnd_d7c79e23fc374a82822f41a3cef63fe9"}	2026-05-06 11:23:32.754291+00
evt_288a8dcee2914f5186b9edd39a7cdfd1	run_4927bce4bff6431299a248cb3fbb4eb3	review.created	discord_compact	Review created: Memory candidate	{"review_item_id": "rev_03a930b12fc04d35be6b04808654c1b9"}	2026-05-06 11:23:32.75432+00
evt_b8acdf3c8b3b4df2aa1082446910b3ab	run_c3f5d9dfe2a341028ceb17dd598b323c	capture.received	discord_compact	Received capture	{"capture_id": "cap_47cac0ac72864934bbc418e19b4d58a8"}	2026-05-06 11:25:24.384373+00
evt_5c23d7b69a594e5db4c74f9abbd45d9a	run_c3f5d9dfe2a341028ceb17dd598b323c	agent.handoff_created	discord_compact	Capture Router -> work.generic	{"handoff_id": "hnd_d24add2b5c644801ae1087a482a38347"}	2026-05-06 11:25:24.384421+00
evt_6ad64e7293514f76aa7fc5204662e869	run_c3f5d9dfe2a341028ceb17dd598b323c	review.created	discord_compact	Review created: Work task candidate	{"review_item_id": "rev_594064f782564be099ad83986664a389"}	2026-05-06 11:25:24.38445+00
evt_0c098113f23e4ca9be648128026b355e	run_e4d19a1c2cd84b799d1dde6ce4d56501	capture.received	discord_compact	Received capture	{"capture_id": "cap_4d62c7dcfedc4907a27f8952f4c5054b"}	2026-05-06 12:02:05.00966+00
evt_64fd8dd931a649deb36f14bf044f86fc	run_e4d19a1c2cd84b799d1dde6ce4d56501	agent.handoff_created	discord_compact	Capture Router -> memory-curator	{"handoff_id": "hnd_a181bb1f229c42288620406bdeba970e"}	2026-05-06 12:02:05.009728+00
evt_177e739203c64a8dbee4bf34b5f08124	run_e4d19a1c2cd84b799d1dde6ce4d56501	review.created	discord_compact	Review created: Memory candidate	{"review_item_id": "rev_557dfe60ff294f5d84b7328dd6f24892"}	2026-05-06 12:02:05.00976+00
evt_59d0b0f5063a475a81fe6ca80ac796b0	run_787fd5a401604cb2b902e17cd28bea33	capture.received	discord_compact	Received capture	{"capture_id": "cap_2f464156a4384621921149d4586807d3", "source_platform": "web"}	2026-05-06 12:03:00.715304+00
evt_d421bb1816ab46eab374941c31a4ea36	run_787fd5a401604cb2b902e17cd28bea33	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_2f464156a4384621921149d4586807d3"}	2026-05-06 12:03:00.715392+00
evt_97a4b2bee9cf490eb5d4d542e4a5c682	run_787fd5a401604cb2b902e17cd28bea33	provider.call_started	web_only	Provider routing started	{"agent_id": "capture-router", "mode": "hybrid"}	2026-05-06 12:03:00.71869+00
evt_bb09af7b98d440c1b94ea848c0407789	run_787fd5a401604cb2b902e17cd28bea33	agentic_router.fallback_deterministic	discord_compact	Provider unavailable; deterministic fallback used	{"error": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}", "agent_id": "memory-curator"}	2026-05-06 12:03:01.612877+00
evt_842552f991c64f40ae33a35f7efe4489	run_787fd5a401604cb2b902e17cd28bea33	policy.decision	discord_compact	Policy: raw_only	{"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}	2026-05-06 12:03:01.622209+00
evt_c6ff55d8e8c84f9581694760cc7836a0	run_787fd5a401604cb2b902e17cd28bea33	agent.handoff_created	discord_compact	Capture Router -> memory-curator	{"handoff_id": "hnd_cdee5eedc36c4d0bb30d4c264dbcbaa2"}	2026-05-06 12:03:01.622392+00
evt_f4a6c76be8304575a540b8871409714a	run_f9e31bcd6aef4773b98f1ef9895e9539	capture.received	discord_compact	Received capture	{"capture_id": "cap_ca43ce4689da485a923a16124f148ebc", "source_platform": "web"}	2026-05-06 12:03:01.637812+00
evt_5392f9117ecc4ccd8fe5615826f33ca6	run_f9e31bcd6aef4773b98f1ef9895e9539	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_ca43ce4689da485a923a16124f148ebc"}	2026-05-06 12:03:01.637878+00
evt_81836423468640729c5d24fb3cb0d5c8	run_f9e31bcd6aef4773b98f1ef9895e9539	provider.call_started	web_only	Provider routing started	{"agent_id": "capture-router", "mode": "hybrid"}	2026-05-06 12:03:01.639579+00
evt_0870943919b8428a9f882741a3e2b4af	run_f9e31bcd6aef4773b98f1ef9895e9539	agentic_router.fallback_deterministic	discord_compact	Provider unavailable; deterministic fallback used	{"error": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}", "agent_id": "finance"}	2026-05-06 12:03:01.778412+00
evt_21bc2772009b44b6aa08da82529f6888	run_f9e31bcd6aef4773b98f1ef9895e9539	policy.decision	discord_compact	Policy: review_required	{"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}	2026-05-06 12:03:01.783615+00
evt_13754bd2c4134c978e6506f8bb9f3fbf	run_f9e31bcd6aef4773b98f1ef9895e9539	agent.handoff_created	discord_compact	Capture Router -> finance	{"handoff_id": "hnd_a62543df982b405989cc776d24031aa3"}	2026-05-06 12:03:01.783794+00
evt_3d799ac4d59e44068a75c5e42d1539f3	run_f9e31bcd6aef4773b98f1ef9895e9539	review.created	discord_compact	Review created: Finance entry candidate	{"review_item_id": "rev_aeeef449e2f44a3896a93b29270dc4e1"}	2026-05-06 12:03:01.787413+00
evt_b76a0e4d75a54b149d9adb70dc44c8ca	\N	review.decision_received	discord_compact	Review reject: Finance entry candidate	{"review_item_id": "rev_aeeef449e2f44a3896a93b29270dc4e1", "decision_id": "dec_1ffd8ab2a0c848408d4ee615d5e03361"}	2026-05-06 12:03:01.801199+00
evt_034b9608bdd94a718106e60b6d86e683	run_ecf75fb7fc0048e29e8d71a65f430268	capture.received	discord_compact	Received capture	{"capture_id": "cap_db6e45e9c04943bc85bf9d0ee436aeff", "source_platform": "web"}	2026-05-06 12:05:06.684291+00
evt_f4033689daa14da1944fd0dac1eef15b	run_ecf75fb7fc0048e29e8d71a65f430268	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_db6e45e9c04943bc85bf9d0ee436aeff"}	2026-05-06 12:05:06.684377+00
evt_918437f4fc5d427fba8b1a8da88a2701	run_ecf75fb7fc0048e29e8d71a65f430268	provider.call_started	web_only	Provider routing started	{"agent_id": "capture-router", "mode": "hybrid"}	2026-05-06 12:05:06.688243+00
evt_70c80ffaa1ae48ebb48e131fe69b57be	run_ecf75fb7fc0048e29e8d71a65f430268	agentic_router.fallback_deterministic	discord_compact	Provider unavailable; deterministic fallback used	{"error": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}", "agent_id": "memory-curator"}	2026-05-06 12:05:06.998343+00
evt_11f7e368da274f34a7fa693c75ea8afc	run_ecf75fb7fc0048e29e8d71a65f430268	policy.decision	discord_compact	Policy: raw_only	{"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}	2026-05-06 12:05:07.007604+00
evt_f390566754274f9db89a3b3b99bb6d02	run_ecf75fb7fc0048e29e8d71a65f430268	agent.handoff_created	discord_compact	Capture Router -> memory-curator	{"handoff_id": "hnd_a5646f22bbf34e34ad754a2c4feb2a67"}	2026-05-06 12:05:07.007805+00
evt_9c24721974054e9a9bc7d1a9b3deee6d	run_4d6dd79f17454ba38768b05f28b68a88	capture.received	discord_compact	Received capture	{"capture_id": "cap_655320e1513b457181a225065ec8cec3", "source_platform": "web"}	2026-05-06 12:05:07.023598+00
evt_fd620de539ff4f2c8380fc817696b9a4	run_4d6dd79f17454ba38768b05f28b68a88	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_655320e1513b457181a225065ec8cec3"}	2026-05-06 12:05:07.023663+00
evt_17de11bad4664b7eb998024aa5bdc48a	run_4d6dd79f17454ba38768b05f28b68a88	provider.call_started	web_only	Provider routing started	{"agent_id": "capture-router", "mode": "hybrid"}	2026-05-06 12:05:07.026275+00
evt_60980efbcbf841e982b2f555c583f83a	run_4d6dd79f17454ba38768b05f28b68a88	agentic_router.fallback_deterministic	discord_compact	Provider unavailable; deterministic fallback used	{"error": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}", "agent_id": "finance"}	2026-05-06 12:05:07.160049+00
evt_b95f8321e24e438b93447e31b82192cb	run_4d6dd79f17454ba38768b05f28b68a88	policy.decision	discord_compact	Policy: review_required	{"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}	2026-05-06 12:05:07.167444+00
evt_379423f13c6a47ecb8f98d13f7d2c948	run_4d6dd79f17454ba38768b05f28b68a88	agent.handoff_created	discord_compact	Capture Router -> finance	{"handoff_id": "hnd_5a324f1c0ba44250af1760e231d24250"}	2026-05-06 12:05:07.167594+00
evt_78cdba2f2d294abdbe6bb31b30874e5b	run_4d6dd79f17454ba38768b05f28b68a88	review.created	discord_compact	Review created: Finance entry candidate	{"review_item_id": "rev_1da6d0d84419441ebc38a0b63b5b4161"}	2026-05-06 12:05:07.173095+00
evt_3441f60a965141ba98f483e81c54ac6a	\N	review.decision_received	discord_compact	Review reject: Finance entry candidate	{"review_item_id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "decision_id": "dec_3bce280e6890401688d134e5a10739e7"}	2026-05-06 12:05:07.187493+00
evt_cbb4996b235b41f6b95d8614fbd6d3b6	\N	review.decision_received	discord_compact	Review reject: Memory candidate	{"review_item_id": "rev_6e4c341e3b2f4028aa1e93ee4964b523", "decision_id": "dec_1662bd77950446d88f3e27671f1eaf3e"}	2026-05-06 12:07:05.069483+00
evt_2073fdb8bfbf40718a796d7ae2ac5168	\N	review.decision_received	discord_compact	Review reject: Memory candidate	{"review_item_id": "rev_03a930b12fc04d35be6b04808654c1b9", "decision_id": "dec_3e0bbf00ce0e4f36b966aff8ba95f5fd"}	2026-05-06 12:07:07.829849+00
evt_1623bc89f3a64a9280e4946a6135450f	\N	review.decision_received	discord_compact	Review reject: Work task candidate	{"review_item_id": "rev_594064f782564be099ad83986664a389", "decision_id": "dec_8a90a256e7784ac7a8c08d6c77c10fd9"}	2026-05-06 12:07:13.583307+00
evt_5153bc520d23459fa3cf3588c5acf88d	\N	review.decision_received	discord_compact	Review reject: Memory candidate	{"review_item_id": "rev_557dfe60ff294f5d84b7328dd6f24892", "decision_id": "dec_e63441ac09eb42b5a820748d70e7277f"}	2026-05-06 12:07:16.998278+00
evt_bb17d3ab20a74c209351e1fca139c597	\N	review.decision_received	discord_compact	Review reject: Finance entry candidate	{"review_item_id": "rev_aeeef449e2f44a3896a93b29270dc4e1", "decision_id": "dec_fc2ecc0ad2194b999839ed744fa59602"}	2026-05-06 12:07:18.452769+00
evt_1081aa5eece54cb7a2e1919a84095976	\N	review.decision_received	discord_compact	Review reject: Finance entry candidate	{"review_item_id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "decision_id": "dec_dca39c1211744e2fadfbce2d5980a650"}	2026-05-06 12:07:19.470397+00
evt_cdde4f09d114431499a9fdb1966b3bf7	run_f603f2b6bde046d4b8d32f2c5357a083	ask.received	discord_compact	Ask LifeOS received	{"source_platform": "web"}	2026-05-06 12:07:53.687394+00
evt_8086576652154515b98a99ab9b7aa37f	run_b7db534588fe46fcb6d5618b46a527f2	ask.received	discord_compact	Ask LifeOS received	{"source_platform": "web"}	2026-05-06 12:08:25.59165+00
evt_18eae7f0db2542dc89370767c6a31550	run_96a2d71b3bc44ad69fe48e8400268030	ask.received	discord_compact	Ask LifeOS received	{"source_platform": "web"}	2026-05-06 12:08:28.604926+00
evt_b4eff2307edf4da6ac115321824b09f4	run_7292281407f94c0b96216160fb805604	ask.received	discord_compact	Ask LifeOS received	{"source_platform": "web"}	2026-05-06 12:53:17.603239+00
evt_adbfa6203785438aaad58b155873c79b	\N	review.decision_received	discord_compact	Review reject: Finance entry candidate	{"review_item_id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "decision_id": "dec_ce60c4d3da71411ea6372ad88e6aefd6"}	2026-05-06 12:53:32.266392+00
evt_f4cdefe9a52d4efa92122bf626fe02d3	\N	review.decision_received	discord_compact	Review done: Finance entry candidate	{"review_item_id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "decision_id": "dec_7e5ec60e030d4e1982723b06b5128ebb"}	2026-05-06 12:53:34.161568+00
evt_206ab39ec97b4c8fa6d14091b2310993	\N	review.decision_received	discord_compact	Review done: Finance entry candidate	{"review_item_id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "decision_id": "dec_4757496e086345b882083df4eb55747a"}	2026-05-06 12:53:34.977973+00
evt_f8ad405d1e944879aa17cd4ac7ba0143	\N	review.decision_received	discord_compact	Review done: Finance entry candidate	{"review_item_id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "decision_id": "dec_f90e29eef9c8485182a40878df9b3d4a"}	2026-05-06 12:53:35.593544+00
evt_a57afa806f0e4af48ed27d2951b899fb	\N	review.decision_received	discord_compact	Review reject: Finance entry candidate	{"review_item_id": "rev_1da6d0d84419441ebc38a0b63b5b4161", "decision_id": "dec_8c9664bf7a034c8ea195dccf3b015149"}	2026-05-06 12:53:36.760456+00
evt_1c680cafc0564a118e26c1aa86adc082	run_92047b1a038942578f8c80933d38bca7	capture.received	discord_compact	Received capture	{"capture_id": "cap_03e86c5ff77b4c6bb3bc0e4251886617", "source_platform": "telegram"}	2026-05-06 12:54:03.402601+00
evt_e17726da48114ac78b1ee18403d8af81	run_92047b1a038942578f8c80933d38bca7	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_03e86c5ff77b4c6bb3bc0e4251886617"}	2026-05-06 12:54:03.402669+00
evt_516ad9bc62a04087af867c0a31644710	run_92047b1a038942578f8c80933d38bca7	provider.call_started	web_only	Provider routing started	{"agent_id": "capture-router", "mode": "hybrid"}	2026-05-06 12:54:03.40558+00
evt_45a3a7abc65245f4897c4ad44bcae69a	run_92047b1a038942578f8c80933d38bca7	agentic_router.fallback_deterministic	discord_compact	Provider unavailable; deterministic fallback used	{"error": "Provider openrouter HTTP 401: {\\"error\\":{\\"message\\":\\"User not found.\\",\\"code\\":401}}", "agent_id": "memory-curator"}	2026-05-06 12:54:03.734845+00
evt_6d09be9bc686494d912832f86e3a71b1	run_92047b1a038942578f8c80933d38bca7	policy.decision	discord_compact	Policy: raw_only	{"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}	2026-05-06 12:54:03.74281+00
evt_7d8ff817b86a421cb466f5f41e10edb0	run_92047b1a038942578f8c80933d38bca7	agent.handoff_created	discord_compact	Capture Router -> memory-curator	{"handoff_id": "hnd_44ebc60eb0d24debaf31349d31de91ad"}	2026-05-06 12:54:03.742972+00
evt_e457ca9bbfc04e8f99ffb7f278c177ad	run_4485b6600ee641c8b6abd6e4c797ebee	capture.received	discord_compact	Received capture	{"capture_id": "cap_a57b14d51ecf4c29af3c014ee2325d24", "source_platform": "web"}	2026-05-06 14:21:14.063516+00
evt_45a03161cc2742768aa051f085c62259	run_4485b6600ee641c8b6abd6e4c797ebee	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_a57b14d51ecf4c29af3c014ee2325d24"}	2026-05-06 14:21:14.063602+00
evt_6b600c26bf2545c989dfecc27f2d4add	run_4485b6600ee641c8b6abd6e4c797ebee	provider.call_started	web_only	Provider routing started	{"agent_id": "capture-router", "mode": "hybrid"}	2026-05-06 14:21:14.067046+00
evt_f23e40b95f0945dd9b69c2341ff50994	run_4485b6600ee641c8b6abd6e4c797ebee	agentic_router.completed	discord_compact	Agentic router selected work.generic	{"provider_call_log_id": "pcall_b251089fb0dd447fb364eb655496ccd2", "agent_id": "work.generic"}	2026-05-06 14:21:44.695052+00
evt_6f751901545b418b925e3b074d074f59	run_4485b6600ee641c8b6abd6e4c797ebee	policy.decision	discord_compact	Policy: raw_only	{"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.0, "requires_user_visible_status": false}	2026-05-06 14:21:44.735342+00
evt_d04f87d0e3f9440fa394e537ee92430a	run_4485b6600ee641c8b6abd6e4c797ebee	agent.handoff_created	discord_compact	Capture Router -> work.generic	{"handoff_id": "hnd_63fb7968b2b845cdaa45a7f5c0081663"}	2026-05-06 14:21:44.735517+00
evt_fe6065083e74479794b0d9932310af3b	run_484250866f254c26aca0b18dbeedd0d4	capture.received	discord_compact	Received capture	{"capture_id": "cap_3f2ae3aa5ff54b5999e88b5a5697b393", "source_platform": "web"}	2026-05-06 14:21:57.099894+00
evt_7d05d708812e43e4a77ec747178d6a68	run_484250866f254c26aca0b18dbeedd0d4	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_3f2ae3aa5ff54b5999e88b5a5697b393"}	2026-05-06 14:21:57.09996+00
evt_84c43d7c043c4619b1ce27d60492e772	run_484250866f254c26aca0b18dbeedd0d4	policy.decision	discord_compact	Policy: raw_only	{"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}	2026-05-06 14:21:57.104217+00
evt_a943be1bbfb54907a66b37808967e866	run_484250866f254c26aca0b18dbeedd0d4	agent.handoff_created	discord_compact	Capture Router -> memory-curator	{"handoff_id": "hnd_746ebf3fbcae41cda7c5c96344a667fe"}	2026-05-06 14:21:57.104347+00
evt_06b4425974bc482491378a905a6aca9f	run_85a510d22a384fb08a5059e122375ffc	capture.received	discord_compact	Received capture	{"capture_id": "cap_ea5c084b450b45d2ab768ab91562d157", "source_platform": "web"}	2026-05-06 14:21:57.115795+00
evt_86e0f8bb7b4b46eebfa5b4b3a7778fc8	run_85a510d22a384fb08a5059e122375ffc	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_ea5c084b450b45d2ab768ab91562d157"}	2026-05-06 14:21:57.115859+00
evt_3c4fe71970c44eaea2ca13872931d336	run_85a510d22a384fb08a5059e122375ffc	policy.decision	discord_compact	Policy: review_required	{"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}	2026-05-06 14:21:57.12294+00
evt_c9f0f7d52b7344878382a3b487cfe62e	run_85a510d22a384fb08a5059e122375ffc	agent.handoff_created	discord_compact	Capture Router -> finance	{"handoff_id": "hnd_5c1c1920d50a45cd9467a8248785e440"}	2026-05-06 14:21:57.123071+00
evt_6c5ec5b128144fe68d2525eb919c272a	run_85a510d22a384fb08a5059e122375ffc	review.created	discord_compact	Review created: Finance entry candidate	{"review_item_id": "rev_d34c75e9b21b45cabfded6a683413cb8"}	2026-05-06 14:21:57.127365+00
evt_c1648afbdc7a40939aa86b2684323f1d	\N	review.decision_received	discord_compact	Review reject: Finance entry candidate	{"review_item_id": "rev_d34c75e9b21b45cabfded6a683413cb8", "decision_id": "dec_ab4535dec66d4fb4acb87ccbce108342"}	2026-05-06 14:21:57.141789+00
evt_e34863df319e495b8f62d328ab832a96	run_4b45891d111542fcb8958d612ce40a57	run.created	web_only	Run created	{"session_id": "sess_cdce27c149bd4a59a301488b11878c34", "iteration_cap": 3}	2026-05-06 14:21:57.166547+00
evt_1d05c927926f41ae8ec668bad981c0f0	run_4b45891d111542fcb8958d612ce40a57	message.received	discord_compact	Received message	{"message_id": "msg_4d47ae467b3a425cb5c626f2c2712d7e", "source_platform": "web"}	2026-05-06 14:21:57.166612+00
evt_bd9b3a4f45754d788fdb5977cc084c29	run_4b45891d111542fcb8958d612ce40a57	agent.iteration_started	discord_compact	Understand request	{"iteration": 1, "iteration_cap": 3}	2026-05-06 14:21:57.16665+00
evt_27dfe37590b841fb8207d1ed7c855da3	run_4b45891d111542fcb8958d612ce40a57	intent.classified	discord_compact	Intent: autonomous_action	{"agent_id": "systems-devops", "domain": "system", "confidence": 0.82, "risk_level": "reversible_internal_write", "reason": "low-risk reversible session action"}	2026-05-06 14:21:57.170495+00
evt_e52ace7903d0483e947fbc3cb1579b15	run_4b45891d111542fcb8958d612ce40a57	agent.selected	discord_compact	Agent selected: systems-devops	{"agent_id": "systems-devops"}	2026-05-06 14:21:57.170555+00
evt_05e7a87281cd4b90a6761c86836d5f5c	run_4b45891d111542fcb8958d612ce40a57	plan.created	web_only	smoke test note: keep this as a low-risk LifeOS note	{"kind": "autonomous_action", "proposed_action": {"command_type": "life_item.create", "risk_level": "reversible_internal_write", "payload": {"domain": "system", "item_type": "note", "title": "smoke test note: keep this as a low-risk LifeOS note", "description_md": "smoke test note: keep this as a low-risk LifeOS note", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}}}	2026-05-06 14:21:57.170587+00
evt_b41cf423ea044323a49b241aaad71773	run_4b45891d111542fcb8958d612ce40a57	agent.iteration_started	discord_compact	Act or escalate	{"iteration": 2, "iteration_cap": 3}	2026-05-06 14:21:57.170621+00
evt_e4b815264a50456f83ae318d16d9af1e	run_4b45891d111542fcb8958d612ce40a57	handoff.created	discord_compact	Orchestrator -> systems-devops	{"handoff_id": "hnd_e3f918e28c9f4dbcbd87631bb4dc6dce", "reason": "low-risk reversible session action"}	2026-05-06 14:21:57.170759+00
evt_8f0f8ff1770a42a5a5b9dd7aad5bdec3	run_4b45891d111542fcb8958d612ce40a57	handoff.accepted	web_only	systems-devops accepted task	{"handoff_id": "hnd_e3f918e28c9f4dbcbd87631bb4dc6dce"}	2026-05-06 14:21:57.170788+00
evt_f963a3ab26cc486dbb790be082e50180	run_4b45891d111542fcb8958d612ce40a57	handoff.completed	discord_compact	systems-devops completed task	{"handoff_id": "hnd_e3f918e28c9f4dbcbd87631bb4dc6dce"}	2026-05-06 14:21:57.17082+00
evt_7b32dcd7e75146b887ac8f319fbfbeb5	run_4b45891d111542fcb8958d612ce40a57	policy.decision	discord_compact	Policy: auto_apply	{"decision": "auto_apply", "reason": "life_item.create is allowlisted for safe mode.", "risk_level": "reversible_internal_write", "confidence": 0.82, "requires_user_visible_status": true}	2026-05-06 14:21:57.174689+00
evt_f099e09dd3b54d05bbe2d2dafed84f3d	\N	state_change.applied	discord_compact	Applied life_item.create	{"entity_type": "life_item", "entity_id": "item_816661bc5c954734a99b8446e3c42c38"}	2026-05-06 14:21:57.177947+00
evt_9f9f3d816ada48408fd96940e3de3412	run_4b45891d111542fcb8958d612ce40a57	autonomous.action.completed	discord_compact	Completed life_item.create	{"command_type": "life_item.create", "state_change_id": "stchg_f02558b5d2ba4b4a97822671d8dcd585", "entity_type": "life_item", "entity_id": "item_816661bc5c954734a99b8446e3c42c38", "status": "applied"}	2026-05-06 14:21:57.178014+00
evt_6ad049c854f24d2399865172586be96e	run_4b45891d111542fcb8958d612ce40a57	run.completed	discord_compact	Auto-applied life_item.create	{"status": "completed", "assistant_message_id": "msg_5e831e6bdbb545c9a799ee4979cdd254"}	2026-05-06 14:21:57.178131+00
evt_58eafcce5c444a468afcbe2289322d37	\N	review.decision_received	discord_compact	Review reject: Finance entry candidate	{"review_item_id": "rev_d34c75e9b21b45cabfded6a683413cb8", "decision_id": "dec_1aaaeab42d48472a963467cf1610a3ce"}	2026-05-06 14:32:16.800102+00
evt_f0e9d082117247b0a25bf68dc367f6ff	\N	review.decision_received	discord_compact	Review reject: Finance entry candidate	{"review_item_id": "rev_d34c75e9b21b45cabfded6a683413cb8", "decision_id": "dec_0c327c733ae14cc299f831a09c7a799e"}	2026-05-06 14:32:18.281406+00
evt_37f28141035b40c28c0d7b937b410c29	run_012d4612d2b646289a60b301321711a7	run.created	web_only	Run created	{"session_id": "sess_0ac4fad62b6f44fba991498be03dcf91", "iteration_cap": 5}	2026-05-06 14:42:10.036176+00
evt_08479534f9b3490696ccfd0e3dcaffdd	run_012d4612d2b646289a60b301321711a7	message.received	discord_compact	Received message	{"message_id": "msg_2ffae008a73248a8b9c8ee1bcbe54cd9", "source_platform": "discord"}	2026-05-06 14:42:10.036258+00
evt_e6074faede2f48a8bfba1e28f10c92d0	run_012d4612d2b646289a60b301321711a7	agent.iteration_started	discord_compact	Understand request	{"iteration": 1, "iteration_cap": 5}	2026-05-06 14:42:10.036298+00
evt_ff8d3ede0809423f98a36be665b1c890	run_012d4612d2b646289a60b301321711a7	intent.classified	discord_compact	Intent: autonomous_action	{"agent_id": "daily-planner", "domain": "planning", "confidence": 0.82, "risk_level": "reversible_internal_write", "reason": "low-risk reversible session action"}	2026-05-06 14:42:10.042373+00
evt_86df0e59e2e64ea78625d2e5448a99d0	run_012d4612d2b646289a60b301321711a7	agent.selected	discord_compact	Agent selected: daily-planner	{"agent_id": "daily-planner"}	2026-05-06 14:42:10.042474+00
evt_2e52cfef2e0e483c91c4e149ed639350	run_012d4612d2b646289a60b301321711a7	plan.created	web_only	hey	{"kind": "autonomous_action", "proposed_action": {"command_type": "life_item.create", "risk_level": "reversible_internal_write", "payload": {"domain": "planning", "item_type": "note", "title": "hey", "description_md": "hey", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}}}	2026-05-06 14:42:10.042508+00
evt_624056abe7d741638efb1591a0b8e9e9	run_012d4612d2b646289a60b301321711a7	agent.iteration_started	discord_compact	Act or escalate	{"iteration": 2, "iteration_cap": 5}	2026-05-06 14:42:10.042544+00
evt_f09ead37c9bb45caa09adbdb48642d65	run_012d4612d2b646289a60b301321711a7	handoff.created	discord_compact	Orchestrator -> daily-planner	{"handoff_id": "hnd_b853ef1fe07c411ba57827dc47556dee", "reason": "low-risk reversible session action"}	2026-05-06 14:42:10.042677+00
evt_f8fa9abe66454b50ac19a1f12f586890	run_012d4612d2b646289a60b301321711a7	handoff.accepted	web_only	daily-planner accepted task	{"handoff_id": "hnd_b853ef1fe07c411ba57827dc47556dee"}	2026-05-06 14:42:10.042731+00
evt_4f182b1e748a4fe0b1c62ac19a5df6f7	run_012d4612d2b646289a60b301321711a7	handoff.completed	discord_compact	daily-planner completed task	{"handoff_id": "hnd_b853ef1fe07c411ba57827dc47556dee"}	2026-05-06 14:42:10.042769+00
evt_4aa26c5e5d0a409c938098ce0701274c	run_012d4612d2b646289a60b301321711a7	policy.decision	discord_compact	Policy: auto_apply	{"decision": "auto_apply", "reason": "life_item.create is allowlisted for safe mode.", "risk_level": "reversible_internal_write", "confidence": 0.82, "requires_user_visible_status": true}	2026-05-06 14:42:10.048845+00
evt_94cc9556ca154063989ce0f2503f1e30	\N	state_change.applied	discord_compact	Applied life_item.create	{"entity_type": "life_item", "entity_id": "item_d3c966e59c9148a9a13a8997ea9a5411"}	2026-05-06 14:42:10.052788+00
evt_7c315dc8940740fb89a5774c63fd828d	run_012d4612d2b646289a60b301321711a7	autonomous.action.completed	discord_compact	Completed life_item.create	{"command_type": "life_item.create", "state_change_id": "stchg_9a3312324237425895a688c4bd0169ec", "entity_type": "life_item", "entity_id": "item_d3c966e59c9148a9a13a8997ea9a5411", "status": "applied"}	2026-05-06 14:42:10.052857+00
evt_754948614a9141d3811853f4f0c231b9	run_012d4612d2b646289a60b301321711a7	run.completed	discord_compact	Auto-applied life_item.create	{"status": "completed", "assistant_message_id": "msg_0ec8e755b6114bd592f480644ec99699"}	2026-05-06 14:42:10.05298+00
evt_f26af4dfc809417e929561aee5a041a5	run_c34644edcdf04a2794276d98d2bc0cb6	run.created	web_only	Run created	{"session_id": "sess_0ac4fad62b6f44fba991498be03dcf91", "iteration_cap": 5}	2026-05-06 14:44:15.21548+00
evt_6b3f54030f4945af96f05102de6c6e30	run_c34644edcdf04a2794276d98d2bc0cb6	message.received	discord_compact	Received message	{"message_id": "msg_e2e0ea3f0ada4e52b38b6d88b131a30f", "source_platform": "discord"}	2026-05-06 14:44:15.215576+00
evt_5568c77ddc834aa888499804a848c2fa	run_c34644edcdf04a2794276d98d2bc0cb6	agent.iteration_started	discord_compact	Understand request	{"iteration": 1, "iteration_cap": 5}	2026-05-06 14:44:15.215617+00
evt_f048f2fbd27543e4a8443b438abc71af	run_c34644edcdf04a2794276d98d2bc0cb6	intent.classified	discord_compact	Intent: direct	{"agent_id": "orchestrator", "domain": "planning", "confidence": 0.8, "risk_level": "safe_internal_read", "reason": "smalltalk/no-op message"}	2026-05-06 14:44:15.215957+00
evt_8d8a246163854078ad30b744d56feff7	run_c34644edcdf04a2794276d98d2bc0cb6	agent.selected	discord_compact	Agent selected: orchestrator	{"agent_id": "orchestrator"}	2026-05-06 14:44:15.216+00
evt_4f4703cd306548f8bb91f0a3090d8ed4	run_c34644edcdf04a2794276d98d2bc0cb6	plan.created	web_only	Greeting	{"kind": "direct", "proposed_action": {}}	2026-05-06 14:44:15.21603+00
evt_0764de37a4684d38878f9a1843b5aa05	run_c34644edcdf04a2794276d98d2bc0cb6	run.completed	discord_compact	Answered directly	{"status": "completed", "assistant_message_id": "msg_d54fa416ac04410ab852115659e44899"}	2026-05-06 14:44:15.21614+00
evt_ac724ffe9c3d45328e842a7215bdb507	run_19dbc598042c4f9db05ce6981703698f	capture.received	discord_compact	Received capture	{"capture_id": "cap_454daf5c601d4bd3b68798c4e5483279", "source_platform": "web"}	2026-05-06 14:44:29.826584+00
evt_2f1e1ab0c24243db871af3d39e2091b9	run_19dbc598042c4f9db05ce6981703698f	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_454daf5c601d4bd3b68798c4e5483279"}	2026-05-06 14:44:29.826655+00
evt_22aa82e0a17840d685aa048fe0f92c5d	run_19dbc598042c4f9db05ce6981703698f	policy.decision	discord_compact	Policy: raw_only	{"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}	2026-05-06 14:44:29.835134+00
evt_4e7eaad34a7845ce91e624dad709f25f	run_19dbc598042c4f9db05ce6981703698f	agent.handoff_created	discord_compact	Capture Router -> memory-curator	{"handoff_id": "hnd_14804ad17c714eb2a0fa5d6cd1f16edf"}	2026-05-06 14:44:29.835298+00
evt_22dc800988ac4bbcb6bf8d803b5eb233	run_f5274948c59a477186830dc802a2f480	capture.received	discord_compact	Received capture	{"capture_id": "cap_d75ec0874b1a4ac7abcca69658396ac5", "source_platform": "web"}	2026-05-06 14:44:29.850973+00
evt_e4b9e817f5c34f2899e9efc5e29bfd36	run_f5274948c59a477186830dc802a2f480	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_d75ec0874b1a4ac7abcca69658396ac5"}	2026-05-06 14:44:29.85104+00
evt_5a37c797181d4db99ad849c80d161599	run_f5274948c59a477186830dc802a2f480	policy.decision	discord_compact	Policy: review_required	{"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}	2026-05-06 14:44:29.857664+00
evt_c27de1d74a7143b0a020b9ce65f94f99	run_f5274948c59a477186830dc802a2f480	agent.handoff_created	discord_compact	Capture Router -> finance	{"handoff_id": "hnd_d609a5241d904aa99d6590aa7fa0fc0d"}	2026-05-06 14:44:29.857829+00
evt_6217b7a5fa004440a534fde9f9f3f637	run_f5274948c59a477186830dc802a2f480	review.created	discord_compact	Review created: Finance entry candidate	{"review_item_id": "rev_323749ef15024188a89808aab7660c3e"}	2026-05-06 14:44:29.862383+00
evt_2742cb14037e4b7ca4484322c9a116d6	\N	review.decision_received	discord_compact	Review reject: Finance entry candidate	{"review_item_id": "rev_323749ef15024188a89808aab7660c3e", "decision_id": "dec_f5fc508d5e014f5b94d99993ffaa30e6"}	2026-05-06 14:44:29.878237+00
evt_6bf71b24a08f4536ad38c6e08a4ca814	run_5be33c728b6f445b8270d9c7591dffd4	run.created	web_only	Run created	{"session_id": "sess_cdce27c149bd4a59a301488b11878c34", "iteration_cap": 3}	2026-05-06 14:44:29.899087+00
evt_6c938299d2d44b45843765a2d6ba6af9	run_5be33c728b6f445b8270d9c7591dffd4	message.received	discord_compact	Received message	{"message_id": "msg_f67e45fc88654beeb3a743fb112b0fe1", "source_platform": "web"}	2026-05-06 14:44:29.899156+00
evt_16a2c2ff66f444b8b44abcc7c9c02ab7	run_5be33c728b6f445b8270d9c7591dffd4	agent.iteration_started	discord_compact	Understand request	{"iteration": 1, "iteration_cap": 3}	2026-05-06 14:44:29.899195+00
evt_b6f12b2938a24624adf5b82dbf15912e	run_5be33c728b6f445b8270d9c7591dffd4	intent.classified	discord_compact	Intent: autonomous_action	{"agent_id": "systems-devops", "domain": "system", "confidence": 0.82, "risk_level": "reversible_internal_write", "reason": "low-risk reversible session action"}	2026-05-06 14:44:29.904027+00
evt_34f14f33acd04607b2c1a3bea0a6b898	run_5be33c728b6f445b8270d9c7591dffd4	agent.selected	discord_compact	Agent selected: systems-devops	{"agent_id": "systems-devops"}	2026-05-06 14:44:29.904093+00
evt_7b1ea3c8a70e436998f779e75bc0d54e	run_5be33c728b6f445b8270d9c7591dffd4	plan.created	web_only	smoke test note: keep this as a low-risk LifeOS note	{"kind": "autonomous_action", "proposed_action": {"command_type": "life_item.create", "risk_level": "reversible_internal_write", "payload": {"domain": "system", "item_type": "note", "title": "smoke test note: keep this as a low-risk LifeOS note", "description_md": "smoke test note: keep this as a low-risk LifeOS note", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}}}	2026-05-06 14:44:29.904127+00
evt_3e52847e4c2945138210181b844893a4	run_5be33c728b6f445b8270d9c7591dffd4	agent.iteration_started	discord_compact	Act or escalate	{"iteration": 2, "iteration_cap": 3}	2026-05-06 14:44:29.904162+00
evt_13f7ee8f773446a38db6c2224c73bf63	run_5be33c728b6f445b8270d9c7591dffd4	handoff.created	discord_compact	Orchestrator -> systems-devops	{"handoff_id": "hnd_6831a95626ef4c54b50961debf6b5573", "reason": "low-risk reversible session action"}	2026-05-06 14:44:29.904278+00
evt_2987aef800e94d34a0072645e9a41da0	run_5be33c728b6f445b8270d9c7591dffd4	handoff.accepted	web_only	systems-devops accepted task	{"handoff_id": "hnd_6831a95626ef4c54b50961debf6b5573"}	2026-05-06 14:44:29.904306+00
evt_dc03b01c3744456bab2c4541c2f09a20	run_5be33c728b6f445b8270d9c7591dffd4	handoff.completed	discord_compact	systems-devops completed task	{"handoff_id": "hnd_6831a95626ef4c54b50961debf6b5573"}	2026-05-06 14:44:29.904341+00
evt_34b5845190d346238279ac8c1f3be4a1	run_5be33c728b6f445b8270d9c7591dffd4	policy.decision	discord_compact	Policy: auto_apply	{"decision": "auto_apply", "reason": "life_item.create is allowlisted for safe mode.", "risk_level": "reversible_internal_write", "confidence": 0.82, "requires_user_visible_status": true}	2026-05-06 14:44:29.909949+00
evt_3428d26166614fb9bc02106b4abf5b81	\N	state_change.applied	discord_compact	Applied life_item.create	{"entity_type": "life_item", "entity_id": "item_bbefd78c695c4821902b1ab5e6ba3364"}	2026-05-06 14:44:29.913861+00
evt_12b46db22d334c519f80646f7227cf0f	run_5be33c728b6f445b8270d9c7591dffd4	autonomous.action.completed	discord_compact	Completed life_item.create	{"command_type": "life_item.create", "state_change_id": "stchg_228e886e0ca5499091af8f3a43e969d7", "entity_type": "life_item", "entity_id": "item_bbefd78c695c4821902b1ab5e6ba3364", "status": "applied"}	2026-05-06 14:44:29.91393+00
evt_21338feb5c5a408390318dce36f0e560	run_5be33c728b6f445b8270d9c7591dffd4	run.completed	discord_compact	Auto-applied life_item.create	{"status": "completed", "assistant_message_id": "msg_846f25ef4f744185a644360dee034a97"}	2026-05-06 14:44:29.914285+00
evt_b2d431558bb747db8f2a97d8d434fbb0	run_302229626b4a49a3abd02392c31173e3	run.created	web_only	Run created	{"session_id": "sess_0ac4fad62b6f44fba991498be03dcf91", "iteration_cap": 5}	2026-05-06 14:46:45.05162+00
evt_8cf3493935ab455da100aded60fa7f53	run_302229626b4a49a3abd02392c31173e3	message.received	discord_compact	Received message	{"message_id": "msg_14a36731880a4b1abdc7ce2ed79d4bd8", "source_platform": "discord"}	2026-05-06 14:46:45.051739+00
evt_08d9ddc54d79402c9e745a42984d654e	run_302229626b4a49a3abd02392c31173e3	agent.iteration_started	discord_compact	Understand request	{"iteration": 1, "iteration_cap": 5}	2026-05-06 14:46:45.051793+00
evt_3d39cffe659243e49255adf6322a3e6f	run_302229626b4a49a3abd02392c31173e3	intent.classified	discord_compact	Intent: direct	{"agent_id": "orchestrator", "domain": "planning", "confidence": 0.8, "risk_level": "safe_internal_read", "reason": "smalltalk/no-op message"}	2026-05-06 14:46:45.052092+00
evt_b17d8e4d2a464e68b22abb22b1f7b1fe	run_302229626b4a49a3abd02392c31173e3	agent.selected	discord_compact	Agent selected: orchestrator	{"agent_id": "orchestrator"}	2026-05-06 14:46:45.052131+00
evt_94b6bfb828f34dafa0ec6123d60853db	run_302229626b4a49a3abd02392c31173e3	plan.created	web_only	Greeting	{"kind": "direct", "proposed_action": {}}	2026-05-06 14:46:45.052159+00
evt_a62da2ef51904e91bb09a32f45a04b3a	run_302229626b4a49a3abd02392c31173e3	run.completed	discord_compact	Answered directly	{"status": "completed", "assistant_message_id": "msg_f3cc671222e64a9a98a42cac744c6906"}	2026-05-06 14:46:45.052267+00
evt_8f17f3aba61940ac83cf19bfda560d0e	run_b5304a2705ad4185906215a0ada98218	capture.received	discord_compact	Received capture	{"capture_id": "cap_93390c37a92b44d697ed8bbaefbeaf56", "source_platform": "web"}	2026-05-06 14:46:57.29945+00
evt_0a0d2d04ea8844959f5be342867dd7ff	run_b5304a2705ad4185906215a0ada98218	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_93390c37a92b44d697ed8bbaefbeaf56"}	2026-05-06 14:46:57.299519+00
evt_adae6e43cddc4140ab65f14bdcb94829	run_b5304a2705ad4185906215a0ada98218	policy.decision	discord_compact	Policy: raw_only	{"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}	2026-05-06 14:46:57.307371+00
evt_0907b79ef4684f5aaafe85020c98f04c	run_b5304a2705ad4185906215a0ada98218	agent.handoff_created	discord_compact	Capture Router -> memory-curator	{"handoff_id": "hnd_7cfe60d3fe4f4f00955d7f3a32d9f757"}	2026-05-06 14:46:57.307532+00
evt_997a2e5418fd41bfb02659c2077f1e04	run_fbb633d89ecd42939345b18887ef347c	capture.received	discord_compact	Received capture	{"capture_id": "cap_23a9118878c64d9f90f05d8b985d730a", "source_platform": "web"}	2026-05-06 14:46:57.323588+00
evt_4ba6106568e648e79fcb39b0470ce36d	run_fbb633d89ecd42939345b18887ef347c	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_23a9118878c64d9f90f05d8b985d730a"}	2026-05-06 14:46:57.323652+00
evt_38e28aab14e44acba77ede396f9633fb	run_fbb633d89ecd42939345b18887ef347c	policy.decision	discord_compact	Policy: review_required	{"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}	2026-05-06 14:46:57.33122+00
evt_576cd435fabf4de6a6bc4d88c2272f8c	run_fbb633d89ecd42939345b18887ef347c	agent.handoff_created	discord_compact	Capture Router -> finance	{"handoff_id": "hnd_54163f0282574e41892a9f0363eb11e0"}	2026-05-06 14:46:57.331361+00
evt_1de140951c2641f19523f60ea9d7cdae	run_fbb633d89ecd42939345b18887ef347c	review.created	discord_compact	Review created: Finance entry candidate	{"review_item_id": "rev_80875aa15ccc4fbd93bf7ddd67bc0d5e"}	2026-05-06 14:46:57.335872+00
evt_e9745dc3b3984dd3afb3638ad941a701	\N	review.decision_received	discord_compact	Review reject: Finance entry candidate	{"review_item_id": "rev_80875aa15ccc4fbd93bf7ddd67bc0d5e", "decision_id": "dec_1650f1b4a1ef473c8058a4bd4171cb94"}	2026-05-06 14:46:57.351627+00
evt_a4b6e245207446c582a887ef8f4edfed	run_0bf80e9c8ca347a3bf750b152ae62104	run.created	web_only	Run created	{"session_id": "sess_cdce27c149bd4a59a301488b11878c34", "iteration_cap": 3}	2026-05-06 14:46:57.371697+00
evt_8d98ff6df93643fba9a5f8211aad9391	run_0bf80e9c8ca347a3bf750b152ae62104	message.received	discord_compact	Received message	{"message_id": "msg_84e60bf05573456c9a41f2f8585beef0", "source_platform": "web"}	2026-05-06 14:46:57.371783+00
evt_6830117b4d3f40eeaf98009ac0ef5fba	run_0bf80e9c8ca347a3bf750b152ae62104	agent.iteration_started	discord_compact	Understand request	{"iteration": 1, "iteration_cap": 3}	2026-05-06 14:46:57.371821+00
evt_035bb18ee284437193e05be3a958db58	run_0bf80e9c8ca347a3bf750b152ae62104	intent.classified	discord_compact	Intent: autonomous_action	{"agent_id": "systems-devops", "domain": "system", "confidence": 0.82, "risk_level": "reversible_internal_write", "reason": "low-risk reversible session action"}	2026-05-06 14:46:57.375977+00
evt_5e6d594fe7d34cda9ec6871bea436d7c	run_0bf80e9c8ca347a3bf750b152ae62104	agent.selected	discord_compact	Agent selected: systems-devops	{"agent_id": "systems-devops"}	2026-05-06 14:46:57.376048+00
evt_c0d2842ddf8b4daaa12da296e7d67410	run_0bf80e9c8ca347a3bf750b152ae62104	plan.created	web_only	smoke test note: keep this as a low-risk LifeOS note	{"kind": "autonomous_action", "proposed_action": {"command_type": "life_item.create", "risk_level": "reversible_internal_write", "payload": {"domain": "system", "item_type": "note", "title": "smoke test note: keep this as a low-risk LifeOS note", "description_md": "smoke test note: keep this as a low-risk LifeOS note", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}}}	2026-05-06 14:46:57.37608+00
evt_4ef376b3d39946cca7bd3b6bcc8d9820	run_0bf80e9c8ca347a3bf750b152ae62104	agent.iteration_started	discord_compact	Act or escalate	{"iteration": 2, "iteration_cap": 3}	2026-05-06 14:46:57.376113+00
evt_8db7d26907cc46eaa189a35d3e040c3a	run_0bf80e9c8ca347a3bf750b152ae62104	handoff.created	discord_compact	Orchestrator -> systems-devops	{"handoff_id": "hnd_fb75f1ed6649422082f873725e2a8724", "reason": "low-risk reversible session action"}	2026-05-06 14:46:57.376231+00
evt_a70a85f5584b4f95b56e23ec4d5cef67	run_0bf80e9c8ca347a3bf750b152ae62104	handoff.accepted	web_only	systems-devops accepted task	{"handoff_id": "hnd_fb75f1ed6649422082f873725e2a8724"}	2026-05-06 14:46:57.376259+00
evt_2a0b3b1c4bab4ff4b67327a97db11a6d	run_0bf80e9c8ca347a3bf750b152ae62104	handoff.completed	discord_compact	systems-devops completed task	{"handoff_id": "hnd_fb75f1ed6649422082f873725e2a8724"}	2026-05-06 14:46:57.376291+00
evt_19748c27cfc44833b00c9da43907d518	run_0bf80e9c8ca347a3bf750b152ae62104	policy.decision	discord_compact	Policy: auto_apply	{"decision": "auto_apply", "reason": "life_item.create is allowlisted for safe mode.", "risk_level": "reversible_internal_write", "confidence": 0.82, "requires_user_visible_status": true}	2026-05-06 14:46:57.381093+00
evt_90ac7b1d57ac43ff9c45071e6e14bda4	\N	state_change.applied	discord_compact	Applied life_item.create	{"entity_type": "life_item", "entity_id": "item_17ba033bb47544679227adbb85a0fc6f"}	2026-05-06 14:46:57.384688+00
evt_00d0f61dfa1c491ba08584f5d77153d0	run_0bf80e9c8ca347a3bf750b152ae62104	autonomous.action.completed	discord_compact	Completed life_item.create	{"command_type": "life_item.create", "state_change_id": "stchg_206baced4e1c4bb7994738da59812a36", "entity_type": "life_item", "entity_id": "item_17ba033bb47544679227adbb85a0fc6f", "status": "applied"}	2026-05-06 14:46:57.384835+00
evt_2f7cb00fd8d241949550ba4446ccfa51	run_0bf80e9c8ca347a3bf750b152ae62104	run.completed	discord_compact	Auto-applied life_item.create	{"status": "completed", "assistant_message_id": "msg_3d206d7bd3814cfd84317497a6ab038d"}	2026-05-06 14:46:57.384964+00
evt_d066ed9daedb42fc97b7728df1a72a53	run_338e8a46e18447a1b16f10d86c44469d	capture.received	discord_compact	Received capture	{"capture_id": "cap_7bd059b3793e459f9af461b29c254e6f", "source_platform": "web"}	2026-05-06 16:36:58.891573+00
evt_ed46715b5a6f4fa7866525fd50448357	run_338e8a46e18447a1b16f10d86c44469d	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_7bd059b3793e459f9af461b29c254e6f"}	2026-05-06 16:36:58.891664+00
evt_5d33508877ee436cb2801e21ca070e5a	run_338e8a46e18447a1b16f10d86c44469d	policy.decision	discord_compact	Policy: raw_only	{"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.88, "requires_user_visible_status": false}	2026-05-06 16:36:58.899373+00
evt_912187386984438bb90d83332849ca27	run_338e8a46e18447a1b16f10d86c44469d	agent.handoff_created	discord_compact	Capture Router -> memory-curator	{"handoff_id": "hnd_edf4cef9d039472bbba475650c0bd116"}	2026-05-06 16:36:58.899529+00
evt_81abdaf41f2a47c992543cea9fcedbf4	run_b4c2536243be496da016b4bb8cb57f6d	capture.received	discord_compact	Received capture	{"capture_id": "cap_1815c12243574fd185773ba74a944a50", "source_platform": "web"}	2026-05-06 16:36:58.913573+00
evt_cc575394e1ef42848acbd2c3259a9137	run_b4c2536243be496da016b4bb8cb57f6d	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_1815c12243574fd185773ba74a944a50"}	2026-05-06 16:36:58.913636+00
evt_a5a8680e1a004d42b27d8c5e026545eb	run_b4c2536243be496da016b4bb8cb57f6d	policy.decision	discord_compact	Policy: review_required	{"decision": "review_required", "reason": "finance_mutation always requires review.", "risk_level": "finance_mutation", "confidence": 0.74, "requires_user_visible_status": true}	2026-05-06 16:36:58.918841+00
evt_b460241d85534a3ea4877e906cb7261b	run_b4c2536243be496da016b4bb8cb57f6d	agent.handoff_created	discord_compact	Capture Router -> finance	{"handoff_id": "hnd_edcbd3a818914bd093d7f4fa9cb81e2b"}	2026-05-06 16:36:58.918968+00
evt_51a63e20440b4cb59fd09aae826c58b4	run_b4c2536243be496da016b4bb8cb57f6d	review.created	discord_compact	Review created: Finance entry candidate	{"review_item_id": "rev_c4bedd5084d044c29220cced23e64dbb"}	2026-05-06 16:36:58.922933+00
evt_f6ea157289d2457ba7bf7a10b74f1f0e	\N	review.decision_received	discord_compact	Review reject: Finance entry candidate	{"review_item_id": "rev_c4bedd5084d044c29220cced23e64dbb", "decision_id": "dec_aa9982c4bc0d4783a5b2421f9d33ddba"}	2026-05-06 16:36:58.937032+00
evt_0347effad0fd49b3bcb74598dcd558b4	run_659f6b5faf754c14a5a9b65d85491860	run.created	web_only	Run created	{"session_id": "sess_cdce27c149bd4a59a301488b11878c34", "iteration_cap": 3}	2026-05-06 16:36:58.995199+00
evt_67f085393f634b49b707c3c535a377fa	run_659f6b5faf754c14a5a9b65d85491860	message.received	discord_compact	Received message	{"message_id": "msg_73a6a92ea7ac432799b5b421cccd3a71", "source_platform": "web"}	2026-05-06 16:36:58.995274+00
evt_8a2f58a1b1c148f7a223cf9530dd4bef	run_659f6b5faf754c14a5a9b65d85491860	agent.iteration_started	discord_compact	Understand request	{"iteration": 1, "iteration_cap": 3}	2026-05-06 16:36:58.995312+00
evt_cb42ac4b656d4a9d95190e18ef0a008b	run_659f6b5faf754c14a5a9b65d85491860	intent.classified	discord_compact	Intent: autonomous_action	{"agent_id": "systems-devops", "domain": "system", "confidence": 0.82, "risk_level": "reversible_internal_write", "reason": "low-risk reversible session action"}	2026-05-06 16:36:58.999827+00
evt_6dff0893607c4e8ba5af04365204dab6	run_659f6b5faf754c14a5a9b65d85491860	agent.selected	discord_compact	Agent selected: systems-devops	{"agent_id": "systems-devops"}	2026-05-06 16:36:58.99989+00
evt_1f1a0a482525472bb7408f291c50a99c	run_659f6b5faf754c14a5a9b65d85491860	plan.created	web_only	smoke test note: keep this as a low-risk LifeOS note	{"kind": "autonomous_action", "proposed_action": {"command_type": "life_item.create", "risk_level": "reversible_internal_write", "payload": {"domain": "system", "item_type": "note", "title": "smoke test note: keep this as a low-risk LifeOS note", "description_md": "smoke test note: keep this as a low-risk LifeOS note", "priority": "normal", "status": "open", "metadata": {"source": "agent_session"}}}}	2026-05-06 16:36:58.999921+00
evt_0f356f1fdf384d41bc28bf19587a111e	run_659f6b5faf754c14a5a9b65d85491860	agent.iteration_started	discord_compact	Act or escalate	{"iteration": 2, "iteration_cap": 3}	2026-05-06 16:36:58.999955+00
evt_22d61636c8f54ae5abd6b9c7ac072fcc	run_659f6b5faf754c14a5a9b65d85491860	handoff.created	discord_compact	Orchestrator -> systems-devops	{"handoff_id": "hnd_97d5c650d3b34e7fbeadc22eaae6ba2a", "reason": "low-risk reversible session action"}	2026-05-06 16:36:59.00007+00
evt_c53514fd2618452798beb3a9b581d138	run_659f6b5faf754c14a5a9b65d85491860	handoff.accepted	web_only	systems-devops accepted task	{"handoff_id": "hnd_97d5c650d3b34e7fbeadc22eaae6ba2a"}	2026-05-06 16:36:59.000098+00
evt_da67077129d94c68982e48e420094eec	run_659f6b5faf754c14a5a9b65d85491860	handoff.completed	discord_compact	systems-devops completed task	{"handoff_id": "hnd_97d5c650d3b34e7fbeadc22eaae6ba2a"}	2026-05-06 16:36:59.000142+00
evt_922e500fbd854e6d97453389e87ba512	run_659f6b5faf754c14a5a9b65d85491860	policy.decision	discord_compact	Policy: auto_apply	{"decision": "auto_apply", "reason": "life_item.create is allowlisted for safe mode.", "risk_level": "reversible_internal_write", "confidence": 0.82, "requires_user_visible_status": true}	2026-05-06 16:36:59.00438+00
evt_fe8e5c310f5d4560aa96188c73a612eb	\N	state_change.applied	discord_compact	Applied life_item.create	{"entity_type": "life_item", "entity_id": "item_a96511a15683433395b49e3be2ea76b9"}	2026-05-06 16:36:59.008044+00
evt_51c7967886dc43279b8bacf282e7e069	run_659f6b5faf754c14a5a9b65d85491860	autonomous.action.completed	discord_compact	Completed life_item.create	{"command_type": "life_item.create", "state_change_id": "stchg_c74032dd191547628f8f491b643f6f91", "entity_type": "life_item", "entity_id": "item_a96511a15683433395b49e3be2ea76b9", "status": "applied"}	2026-05-06 16:36:59.00811+00
evt_01c439b3a70144ec9609bff2feae694c	run_659f6b5faf754c14a5a9b65d85491860	run.completed	discord_compact	Auto-applied life_item.create	{"status": "completed", "assistant_message_id": "msg_adc96960f75744c590684f586e45d2c6"}	2026-05-06 16:36:59.008488+00
evt_aea9f9ea30af467bb52402868bbbb988	run_3693a49a498f4617a5ce949dcbf62c37	capture.received	discord_compact	Received capture	{"capture_id": "cap_9e381bbd92c04332ac4759c958cfbe0b", "source_platform": "telegram"}	2026-05-06 16:41:20.358937+00
evt_df70f64c966d4a649c57bfa771f2c0c6	run_3693a49a498f4617a5ce949dcbf62c37	capture.routing	discord_compact	Routing/classifying capture	{"capture_id": "cap_9e381bbd92c04332ac4759c958cfbe0b"}	2026-05-06 16:41:20.359004+00
evt_979fd7aa7f4a4aa3ad0e0294f70b10a9	run_3693a49a498f4617a5ce949dcbf62c37	provider.call_started	web_only	Provider routing started	{"agent_id": "capture-router", "mode": "hybrid"}	2026-05-06 16:41:20.360579+00
evt_c52d6f242af84e5c97040df747f67da3	run_3693a49a498f4617a5ce949dcbf62c37	agentic_router.completed	discord_compact	Agentic router selected work.generic	{"provider_call_log_id": "pcall_a72a1bba61c04038a0ead33e06c20959", "agent_id": "work.generic"}	2026-05-06 16:41:30.533081+00
evt_967e669b1cad4802b3a758586b877bb5	run_3693a49a498f4617a5ce949dcbf62c37	policy.decision	discord_compact	Policy: raw_only	{"decision": "raw_only", "reason": "No clear action intent; raw evidence archived without memory promotion.", "risk_level": "safe_internal_read", "confidence": 0.1, "requires_user_visible_status": false}	2026-05-06 16:41:30.554942+00
evt_53345e292f72400c8145e140f4ae13ef	run_3693a49a498f4617a5ce949dcbf62c37	agent.handoff_created	discord_compact	Capture Router -> work.generic	{"handoff_id": "hnd_9dc4c267c7e24753ab241eef63e31a13"}	2026-05-06 16:41:30.555121+00
\.


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.system_settings (key, value_json, description, created_at, updated_at) FROM stdin;
agent.default_iteration_cap	{"value": 5}	Default max iterations for Discord/WebUI agent sessions.	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
router.mode	{"value": "hybrid"}	agentic, hybrid, or deterministic capture routing	2026-05-06 12:02:44.599139+00	2026-05-06 16:36:59.025083+00
\.


--
-- Data for Name: tool_calls; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.tool_calls (id, run_id, agent_id, tool_id, status, input_json, output_json, redacted_input_json, redacted_output_json, approval_review_item_id, error_json, created_at, started_at, finished_at) FROM stdin;
\.


--
-- Data for Name: tool_permissions; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.tool_permissions (id, agent_id, tool_id, effect, mode, scopes, requires_approval_when, created_at, updated_at) FROM stdin;
perm_002b988f0df64b58a80dadfaf01ec1af	orchestrator	lifeos.read_state	allow	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_c7ec27dd126246f6a0f93669de02238a	orchestrator	lifeos.search_memory	allow	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_ab3032585f2d469d884921a0d2cb22a5	orchestrator	handoff.create	allow	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_e944d7d5e32f46d08047896197b23abc	orchestrator	lifeos.create_review_item	allow	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_a197e12862d04b7daaf9389967dd9d5a	orchestrator	file.read	deny	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_71abfb16bce74548a9fd272d0844c3a0	orchestrator	file.write	deny	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_b077e49901424f33a4125a716b38b142	orchestrator	terminal.run	deny	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_a76043fd63c24fb5ad65273c6b78da75	work.generic	lifeos.read_state	allow	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_4d1c08485a8f45308beeaaa379a314fe	work.generic	lifeos.search_memory	allow	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_8f10560c2a204f23933adafa8197583e	work.generic	lifeos.create_review_item	allow	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_04111a1ba0474ce8b4ed8ba7f85c2187	work.generic	handoff.create	allow	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_a6813e1a3fbd418aa5a85d2601c5ec99	work.generic	file.read	ask	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_2d81f24b39ae4fe9b331c7f921e12255	work.generic	file.write	ask	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_dbd60b5cf6bf4323b76c7834e341d42e	work.generic	terminal.run	deny	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_545da805ec694408a99e546e7e7038b5	finance	lifeos.read_state	allow	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_0216ac4336de428587fd3e2debf12dce	finance	lifeos.create_review_item	allow	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_eb8f54c71bf9441bb312f8f6703489ca	finance	lifeos.apply_state_change	ask	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_7a391a57551c4565abd65eb9f52e5d7d	finance	lifeos.search_memory	allow	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_18c9c4a97bf74abc97c63de2ac774787	finance	web.search	deny	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_9a8539ac310240d6a6d79e9d1587c18a	finance	file.read	deny	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_41275141731d4335971ec4771249792d	finance	terminal.run	deny	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_21680a7884134c1c9851fc1278c6ca3e	systems-devops	file.read	allow	read_only	{"paths": ["/workspace/lifeos-vnext"]}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_566babe1664643d0bf97b78cb412fd99	systems-devops	file.write	ask	read_only	{"paths": ["/workspace/lifeos-vnext"]}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_ce95c3464c674b61a8ce501e51f8d764	systems-devops	terminal.run	ask	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_8f1a8034e2eb4cda89967d97c3486038	systems-devops	provider_keys.modify	deny	read_only	{}	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
perm_5dd12700d91a47f8a2699b28dff32e2c	orchestrator	lifeos.write_preference_candidate	allow	read_only	{}	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
perm_a5b01b8d008842138d10ca7e3a1db36e	orchestrator	lifeos.apply_correction	allow	read_only	{}	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
perm_55b25ba20d0942dc927cba3d0a7ef8e0	work.generic	lifeos.write_preference_candidate	allow	read_only	{}	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
perm_ad1eb357802f4e308d84f2d63c04f1c0	finance	lifeos.write_preference_candidate	ask	read_only	{}	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
perm_3dc8ce03bd0c4a709ec05e1e41eb243d	systems-devops	file.search	allow	read_only	{"paths": ["/workspace/lifeos-vnext"]}	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
perm_64a942a01f064091b8e2a5e1ba7ed772	systems-devops	file.move	ask	read_only	{"paths": ["/workspace/lifeos-vnext"]}	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
perm_f9c9892565894e88b22e6bf1e645d54e	systems-devops	script.run	ask	read_only	{}	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
perm_ad8eacdabd034be1b464fb1c277dfa1f	systems-devops	api.call	ask	read_only	{}	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
\.


--
-- Data for Name: tools; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.tools (id, display_name, category, description, risk_level, enabled, schema_json, created_at, updated_at) FROM stdin;
file.read	Read file	filesystem	\N	sensitive_internal_read	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
file.write	Write file	filesystem	\N	file_write_or_move	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
handoff.create	Create agent handoff	orchestration	\N	reversible_internal_write	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
lifeos.apply_state_change	Apply approved state change	lifeos	\N	durable_state_mutation	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
lifeos.create_review_item	Create review item	lifeos	\N	reversible_internal_write	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
lifeos.read_state	Read LifeOS state	lifeos	\N	safe_internal_read	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
lifeos.search_memory	Search approved memory	memory	\N	sensitive_internal_read	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
lifeos.write_curated_memory	Write curated memory	memory	\N	durable_state_mutation	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
lifeos.write_memory_candidate	Write memory candidate	memory	\N	reversible_internal_write	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
terminal.run	Run terminal command	system	\N	destructive_or_sensitive_action	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
web.fetch	Web fetch	external	\N	external_read	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
web.search	Web search	external	\N	external_read	t	{}	2026-05-06 12:02:44.599139+00	2026-05-06 12:02:44.599139+00
api.call	Call external API	external	\N	external_side_effect	t	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
file.move	Move file	filesystem	\N	file_write_or_move	t	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
file.search	Search files	filesystem	\N	sensitive_internal_read	t	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
lifeos.apply_correction	Apply safe correction	lifeos	\N	reversible_internal_write	t	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
lifeos.write_preference_candidate	Write preference candidate	memory	\N	reversible_internal_write	t	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
script.run	Run approved script	system	\N	destructive_or_sensitive_action	t	{}	2026-05-06 14:21:03.122828+00	2026-05-06 14:21:03.122828+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.users (id, display_name, timezone, locale, role, created_at, updated_at) FROM stdin;
1246911184435675141	Discord owner	Africa/Casablanca	\N	owner	2026-05-06 14:42:10.025385+00	2026-05-06 14:42:10.025385+00
\.


--
-- Data for Name: vault_index_entries; Type: TABLE DATA; Schema: public; Owner: lifeos
--

COPY public.vault_index_entries (id, vault_uri, content_hash, index_kind, domain, sensitivity, indexed_text, metadata_json, created_at, updated_at) FROM stdin;
\.


--
-- Name: agent_model_configs agent_model_configs_agent_id_key; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.agent_model_configs
    ADD CONSTRAINT agent_model_configs_agent_id_key UNIQUE (agent_id);


--
-- Name: agent_model_configs agent_model_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.agent_model_configs
    ADD CONSTRAINT agent_model_configs_pkey PRIMARY KEY (id);


--
-- Name: agent_runs agent_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_pkey PRIMARY KEY (id);


--
-- Name: agent_sessions agent_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.agent_sessions
    ADD CONSTRAINT agent_sessions_pkey PRIMARY KEY (id);


--
-- Name: agents agents_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: audit_events audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);


--
-- Name: capture_attachments capture_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.capture_attachments
    ADD CONSTRAINT capture_attachments_pkey PRIMARY KEY (id);


--
-- Name: capture_interpretations capture_interpretations_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.capture_interpretations
    ADD CONSTRAINT capture_interpretations_pkey PRIMARY KEY (id);


--
-- Name: channels channels_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (id);


--
-- Name: daily_logs daily_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.daily_logs
    ADD CONSTRAINT daily_logs_pkey PRIMARY KEY (id);


--
-- Name: dead_letter_items dead_letter_items_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.dead_letter_items
    ADD CONSTRAINT dead_letter_items_pkey PRIMARY KEY (id);


--
-- Name: finance_entries finance_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.finance_entries
    ADD CONSTRAINT finance_entries_pkey PRIMARY KEY (id);


--
-- Name: handoffs handoffs_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.handoffs
    ADD CONSTRAINT handoffs_pkey PRIMARY KEY (id);


--
-- Name: job_runs job_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.job_runs
    ADD CONSTRAINT job_runs_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: life_items life_items_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.life_items
    ADD CONSTRAINT life_items_pkey PRIMARY KEY (id);


--
-- Name: memory_candidates memory_candidates_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.memory_candidates
    ADD CONSTRAINT memory_candidates_pkey PRIMARY KEY (id);


--
-- Name: memory_facts memory_facts_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.memory_facts
    ADD CONSTRAINT memory_facts_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: prayer_logs prayer_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.prayer_logs
    ADD CONSTRAINT prayer_logs_pkey PRIMARY KEY (id);


--
-- Name: provider_call_logs provider_call_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.provider_call_logs
    ADD CONSTRAINT provider_call_logs_pkey PRIMARY KEY (id);


--
-- Name: provider_runtime_configs provider_runtime_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.provider_runtime_configs
    ADD CONSTRAINT provider_runtime_configs_pkey PRIMARY KEY (id);


--
-- Name: provider_runtime_configs provider_runtime_configs_provider_id_key; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.provider_runtime_configs
    ADD CONSTRAINT provider_runtime_configs_provider_id_key UNIQUE (provider_id);


--
-- Name: raw_captures raw_captures_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.raw_captures
    ADD CONSTRAINT raw_captures_pkey PRIMARY KEY (id);


--
-- Name: review_bindings review_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.review_bindings
    ADD CONSTRAINT review_bindings_pkey PRIMARY KEY (id);


--
-- Name: review_decisions review_decisions_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.review_decisions
    ADD CONSTRAINT review_decisions_pkey PRIMARY KEY (id);


--
-- Name: review_items review_items_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.review_items
    ADD CONSTRAINT review_items_pkey PRIMARY KEY (id);


--
-- Name: state_changes state_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.state_changes
    ADD CONSTRAINT state_changes_pkey PRIMARY KEY (id);


--
-- Name: status_events status_events_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.status_events
    ADD CONSTRAINT status_events_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (key);


--
-- Name: tool_calls tool_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.tool_calls
    ADD CONSTRAINT tool_calls_pkey PRIMARY KEY (id);


--
-- Name: tool_permissions tool_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.tool_permissions
    ADD CONSTRAINT tool_permissions_pkey PRIMARY KEY (id);


--
-- Name: tools tools_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.tools
    ADD CONSTRAINT tools_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vault_index_entries vault_index_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.vault_index_entries
    ADD CONSTRAINT vault_index_entries_pkey PRIMARY KEY (id);


--
-- Name: vault_index_entries vault_index_entries_vault_uri_key; Type: CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.vault_index_entries
    ADD CONSTRAINT vault_index_entries_vault_uri_key UNIQUE (vault_uri);


--
-- Name: idx_agent_runs_status_created; Type: INDEX; Schema: public; Owner: lifeos
--

CREATE INDEX idx_agent_runs_status_created ON public.agent_runs USING btree (status, created_at);


--
-- Name: idx_agent_sessions_discord_binding; Type: INDEX; Schema: public; Owner: lifeos
--

CREATE INDEX idx_agent_sessions_discord_binding ON public.agent_sessions USING btree (source_platform, external_channel_id, external_thread_id);


--
-- Name: idx_audit_entity; Type: INDEX; Schema: public; Owner: lifeos
--

CREATE INDEX idx_audit_entity ON public.audit_events USING btree (entity_type, entity_id, created_at);


--
-- Name: idx_life_items_domain_status_due; Type: INDEX; Schema: public; Owner: lifeos
--

CREATE INDEX idx_life_items_domain_status_due ON public.life_items USING btree (domain, status, due_at);


--
-- Name: idx_raw_captures_status_created; Type: INDEX; Schema: public; Owner: lifeos
--

CREATE INDEX idx_raw_captures_status_created ON public.raw_captures USING btree (status, created_at);


--
-- Name: idx_review_items_status_priority; Type: INDEX; Schema: public; Owner: lifeos
--

CREATE INDEX idx_review_items_status_priority ON public.review_items USING btree (status, priority, created_at);


--
-- Name: idx_tool_calls_run; Type: INDEX; Schema: public; Owner: lifeos
--

CREATE INDEX idx_tool_calls_run ON public.tool_calls USING btree (run_id, created_at);


--
-- Name: idx_vault_index_domain; Type: INDEX; Schema: public; Owner: lifeos
--

CREATE INDEX idx_vault_index_domain ON public.vault_index_entries USING btree (domain, index_kind);


--
-- Name: agent_runs agent_runs_root_capture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_root_capture_id_fkey FOREIGN KEY (root_capture_id) REFERENCES public.raw_captures(id);


--
-- Name: agent_sessions agent_sessions_channel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.agent_sessions
    ADD CONSTRAINT agent_sessions_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.channels(id);


--
-- Name: agent_sessions agent_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.agent_sessions
    ADD CONSTRAINT agent_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: capture_attachments capture_attachments_capture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.capture_attachments
    ADD CONSTRAINT capture_attachments_capture_id_fkey FOREIGN KEY (capture_id) REFERENCES public.raw_captures(id);


--
-- Name: capture_interpretations capture_interpretations_capture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.capture_interpretations
    ADD CONSTRAINT capture_interpretations_capture_id_fkey FOREIGN KEY (capture_id) REFERENCES public.raw_captures(id);


--
-- Name: daily_logs daily_logs_review_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.daily_logs
    ADD CONSTRAINT daily_logs_review_item_id_fkey FOREIGN KEY (review_item_id) REFERENCES public.review_items(id);


--
-- Name: daily_logs daily_logs_source_capture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.daily_logs
    ADD CONSTRAINT daily_logs_source_capture_id_fkey FOREIGN KEY (source_capture_id) REFERENCES public.raw_captures(id);


--
-- Name: daily_logs daily_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.daily_logs
    ADD CONSTRAINT daily_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: finance_entries finance_entries_review_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.finance_entries
    ADD CONSTRAINT finance_entries_review_item_id_fkey FOREIGN KEY (review_item_id) REFERENCES public.review_items(id);


--
-- Name: finance_entries finance_entries_source_capture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.finance_entries
    ADD CONSTRAINT finance_entries_source_capture_id_fkey FOREIGN KEY (source_capture_id) REFERENCES public.raw_captures(id);


--
-- Name: agent_runs fk_agent_runs_session; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT fk_agent_runs_session FOREIGN KEY (session_id) REFERENCES public.agent_sessions(id);


--
-- Name: raw_captures fk_raw_captures_channel; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.raw_captures
    ADD CONSTRAINT fk_raw_captures_channel FOREIGN KEY (source_channel_id) REFERENCES public.channels(id);


--
-- Name: raw_captures fk_raw_captures_user; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.raw_captures
    ADD CONSTRAINT fk_raw_captures_user FOREIGN KEY (source_user_id) REFERENCES public.users(id);


--
-- Name: handoffs handoffs_parent_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.handoffs
    ADD CONSTRAINT handoffs_parent_run_id_fkey FOREIGN KEY (parent_run_id) REFERENCES public.agent_runs(id);


--
-- Name: job_runs job_runs_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.job_runs
    ADD CONSTRAINT job_runs_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id);


--
-- Name: job_runs job_runs_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.job_runs
    ADD CONSTRAINT job_runs_run_id_fkey FOREIGN KEY (run_id) REFERENCES public.agent_runs(id);


--
-- Name: jobs jobs_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- Name: life_items life_items_approved_state_change_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.life_items
    ADD CONSTRAINT life_items_approved_state_change_id_fkey FOREIGN KEY (approved_state_change_id) REFERENCES public.state_changes(id);


--
-- Name: life_items life_items_source_capture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.life_items
    ADD CONSTRAINT life_items_source_capture_id_fkey FOREIGN KEY (source_capture_id) REFERENCES public.raw_captures(id);


--
-- Name: memory_candidates memory_candidates_review_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.memory_candidates
    ADD CONSTRAINT memory_candidates_review_item_id_fkey FOREIGN KEY (review_item_id) REFERENCES public.review_items(id);


--
-- Name: memory_candidates memory_candidates_source_capture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.memory_candidates
    ADD CONSTRAINT memory_candidates_source_capture_id_fkey FOREIGN KEY (source_capture_id) REFERENCES public.raw_captures(id);


--
-- Name: memory_facts memory_facts_source_candidate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.memory_facts
    ADD CONSTRAINT memory_facts_source_candidate_id_fkey FOREIGN KEY (source_candidate_id) REFERENCES public.memory_candidates(id);


--
-- Name: messages messages_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.agent_sessions(id);


--
-- Name: notifications notifications_related_review_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_related_review_item_id_fkey FOREIGN KEY (related_review_item_id) REFERENCES public.review_items(id);


--
-- Name: notifications notifications_related_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_related_run_id_fkey FOREIGN KEY (related_run_id) REFERENCES public.agent_runs(id);


--
-- Name: notifications notifications_target_channel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_target_channel_id_fkey FOREIGN KEY (target_channel_id) REFERENCES public.channels(id);


--
-- Name: prayer_logs prayer_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.prayer_logs
    ADD CONSTRAINT prayer_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: provider_call_logs provider_call_logs_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.provider_call_logs
    ADD CONSTRAINT provider_call_logs_run_id_fkey FOREIGN KEY (run_id) REFERENCES public.agent_runs(id);


--
-- Name: review_bindings review_bindings_channel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.review_bindings
    ADD CONSTRAINT review_bindings_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.channels(id);


--
-- Name: review_bindings review_bindings_review_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.review_bindings
    ADD CONSTRAINT review_bindings_review_item_id_fkey FOREIGN KEY (review_item_id) REFERENCES public.review_items(id);


--
-- Name: review_decisions review_decisions_review_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.review_decisions
    ADD CONSTRAINT review_decisions_review_item_id_fkey FOREIGN KEY (review_item_id) REFERENCES public.review_items(id);


--
-- Name: review_items review_items_source_capture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.review_items
    ADD CONSTRAINT review_items_source_capture_id_fkey FOREIGN KEY (source_capture_id) REFERENCES public.raw_captures(id);


--
-- Name: state_changes state_changes_review_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.state_changes
    ADD CONSTRAINT state_changes_review_item_id_fkey FOREIGN KEY (review_item_id) REFERENCES public.review_items(id);


--
-- Name: status_events status_events_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.status_events
    ADD CONSTRAINT status_events_run_id_fkey FOREIGN KEY (run_id) REFERENCES public.agent_runs(id);


--
-- Name: tool_calls tool_calls_approval_review_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.tool_calls
    ADD CONSTRAINT tool_calls_approval_review_item_id_fkey FOREIGN KEY (approval_review_item_id) REFERENCES public.review_items(id);


--
-- Name: tool_calls tool_calls_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lifeos
--

ALTER TABLE ONLY public.tool_calls
    ADD CONSTRAINT tool_calls_run_id_fkey FOREIGN KEY (run_id) REFERENCES public.agent_runs(id);


--
-- PostgreSQL database dump complete
--

\unrestrict uNeES93Dzw3ntqvaAc3OJ2GWTvgEoGDB23STWQKeutcvXASGqb4470iUScAqf2j

