"""phase runtime tables

Revision ID: 0002_phase_runtime_tables
Revises: 0001_initial_spine
Create Date: 2026-05-06
"""

from alembic import op
import sqlalchemy as sa

revision = "0002_phase_runtime_tables"
down_revision = "0001_initial_spine"
branch_labels = None
depends_on = None


def json_col(name: str, nullable: bool = False) -> sa.Column:
    return sa.Column(name, sa.JSON(), nullable=nullable)


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("display_name", sa.Text(), nullable=False),
        sa.Column("timezone", sa.Text(), nullable=False),
        sa.Column("locale", sa.Text()),
        sa.Column("role", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "channels",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("platform", sa.String(length=32), nullable=False),
        sa.Column("external_channel_id", sa.Text()),
        sa.Column("guild_id", sa.Text()),
        sa.Column("name", sa.Text()),
        sa.Column("purpose", sa.String(length=64), nullable=False),
        sa.Column("default_agent_id", sa.String(length=128)),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )

    op.add_column("raw_captures", sa.Column("source_channel_id", sa.String(length=64)))
    op.add_column("raw_captures", sa.Column("source_user_id", sa.String(length=64)))
    op.create_foreign_key("fk_raw_captures_channel", "raw_captures", "channels", ["source_channel_id"], ["id"])
    op.create_foreign_key("fk_raw_captures_user", "raw_captures", "users", ["source_user_id"], ["id"])

    op.add_column("review_items", sa.Column("source_uri", sa.Text()))
    op.add_column("agent_runs", sa.Column("session_id", sa.String(length=64)))

    op.create_table(
        "capture_attachments",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("capture_id", sa.String(length=64), sa.ForeignKey("raw_captures.id"), nullable=False),
        sa.Column("kind", sa.String(length=32), nullable=False),
        sa.Column("original_filename", sa.Text()),
        sa.Column("mime_type", sa.Text()),
        sa.Column("storage_uri", sa.Text(), nullable=False),
        sa.Column("content_hash", sa.String(length=128)),
        sa.Column("extracted_text_uri", sa.Text()),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "capture_interpretations",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("capture_id", sa.String(length=64), sa.ForeignKey("raw_captures.id"), nullable=False),
        sa.Column("agent_id", sa.String(length=128), nullable=False),
        sa.Column("intent_labels", sa.JSON(), nullable=False),
        sa.Column("draft_json", sa.JSON(), nullable=False),
        sa.Column("confidence", sa.Numeric(), nullable=False),
        sa.Column("missing_context", sa.JSON(), nullable=False),
        sa.Column("risk_level", sa.String(length=64), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "review_bindings",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("review_item_id", sa.String(length=64), sa.ForeignKey("review_items.id"), nullable=False),
        sa.Column("platform", sa.String(length=32), nullable=False),
        sa.Column("channel_id", sa.String(length=64), sa.ForeignKey("channels.id")),
        sa.Column("external_message_id", sa.Text()),
        sa.Column("external_thread_id", sa.Text()),
        sa.Column("card_version", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "agents",
        sa.Column("id", sa.String(length=128), primary_key=True),
        sa.Column("display_name", sa.Text(), nullable=False),
        sa.Column("domain", sa.String(length=64), nullable=False),
        sa.Column("registry_uri", sa.Text(), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("autonomy_level", sa.String(length=64), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "agent_sessions",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("agent_id", sa.String(length=128), nullable=False),
        sa.Column("user_id", sa.String(length=64), sa.ForeignKey("users.id")),
        sa.Column("channel_id", sa.String(length=64), sa.ForeignKey("channels.id")),
        sa.Column("title", sa.Text()),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("memory_scope", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_foreign_key("fk_agent_runs_session", "agent_runs", "agent_sessions", ["session_id"], ["id"])
    op.create_table(
        "messages",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("session_id", sa.String(length=64), sa.ForeignKey("agent_sessions.id")),
        sa.Column("run_id", sa.String(length=64)),
        sa.Column("role", sa.String(length=32), nullable=False),
        sa.Column("content_md", sa.Text()),
        sa.Column("content_json", sa.JSON()),
        sa.Column("source_platform", sa.String(length=32)),
        sa.Column("source_external_message_id", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "handoffs",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("parent_run_id", sa.String(length=64), sa.ForeignKey("agent_runs.id")),
        sa.Column("from_agent_id", sa.String(length=128), nullable=False),
        sa.Column("to_agent_id", sa.String(length=128), nullable=False),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column("task_md", sa.Text(), nullable=False),
        sa.Column("context_refs", sa.JSON(), nullable=False),
        sa.Column("expected_output_schema", sa.JSON()),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("visibility", sa.String(length=32), nullable=False),
        sa.Column("discord_summary_posted", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
        sa.Column("completed_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "tools",
        sa.Column("id", sa.String(length=128), primary_key=True),
        sa.Column("display_name", sa.Text(), nullable=False),
        sa.Column("category", sa.String(length=64), nullable=False),
        sa.Column("description", sa.Text()),
        sa.Column("risk_level", sa.String(length=64), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("schema_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "tool_permissions",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("agent_id", sa.String(length=128), nullable=False),
        sa.Column("tool_id", sa.String(length=128), nullable=False),
        sa.Column("effect", sa.String(length=32), nullable=False),
        sa.Column("mode", sa.String(length=32), nullable=False),
        sa.Column("scopes", sa.JSON(), nullable=False),
        sa.Column("requires_approval_when", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "tool_calls",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("run_id", sa.String(length=64), sa.ForeignKey("agent_runs.id")),
        sa.Column("agent_id", sa.String(length=128), nullable=False),
        sa.Column("tool_id", sa.String(length=128), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("input_json", sa.JSON(), nullable=False),
        sa.Column("output_json", sa.JSON()),
        sa.Column("redacted_input_json", sa.JSON()),
        sa.Column("redacted_output_json", sa.JSON()),
        sa.Column("approval_review_item_id", sa.String(length=64), sa.ForeignKey("review_items.id")),
        sa.Column("error_json", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True)),
        sa.Column("finished_at", sa.DateTime(timezone=True)),
    )
    op.create_index("idx_tool_calls_run", "tool_calls", ["run_id", "created_at"])
    op.create_table(
        "provider_call_logs",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("run_id", sa.String(length=64), sa.ForeignKey("agent_runs.id")),
        sa.Column("agent_id", sa.String(length=128)),
        sa.Column("provider_id", sa.String(length=64), nullable=False),
        sa.Column("model", sa.Text(), nullable=False),
        sa.Column("key_label", sa.Text()),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("latency_ms", sa.Integer()),
        sa.Column("input_tokens", sa.Integer()),
        sa.Column("output_tokens", sa.Integer()),
        sa.Column("cost_usd", sa.Numeric()),
        sa.Column("error_json", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "memory_candidates",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("source_capture_id", sa.String(length=64), sa.ForeignKey("raw_captures.id")),
        sa.Column("proposed_by_agent_id", sa.String(length=128), nullable=False),
        sa.Column("candidate_kind", sa.String(length=64), nullable=False),
        sa.Column("statement_md", sa.Text(), nullable=False),
        sa.Column("evidence_refs", sa.JSON(), nullable=False),
        sa.Column("confidence", sa.Numeric(), nullable=False),
        sa.Column("sensitivity", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("review_item_id", sa.String(length=64), sa.ForeignKey("review_items.id")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "memory_facts",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("fact_kind", sa.String(length=64), nullable=False),
        sa.Column("statement_md", sa.Text(), nullable=False),
        sa.Column("domain", sa.String(length=64), nullable=False),
        sa.Column("confidence", sa.Numeric(), nullable=False),
        sa.Column("sensitivity", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("source_candidate_id", sa.String(length=64), sa.ForeignKey("memory_candidates.id")),
        sa.Column("evidence_refs", sa.JSON(), nullable=False),
        sa.Column("vault_uri", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "vault_index_entries",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("vault_uri", sa.Text(), nullable=False, unique=True),
        sa.Column("content_hash", sa.String(length=128), nullable=False),
        sa.Column("index_kind", sa.String(length=64), nullable=False),
        sa.Column("domain", sa.String(length=64)),
        sa.Column("sensitivity", sa.String(length=32), nullable=False),
        sa.Column("indexed_text", sa.Text()),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_index("idx_vault_index_domain", "vault_index_entries", ["domain", "index_kind"])
    op.create_table(
        "life_items",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("domain", sa.String(length=64), nullable=False),
        sa.Column("item_type", sa.String(length=64), nullable=False),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("description_md", sa.Text()),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("priority", sa.String(length=32), nullable=False),
        sa.Column("due_at", sa.DateTime(timezone=True)),
        sa.Column("scheduled_at", sa.DateTime(timezone=True)),
        sa.Column("source_capture_id", sa.String(length=64), sa.ForeignKey("raw_captures.id")),
        sa.Column("approved_state_change_id", sa.String(length=64), sa.ForeignKey("state_changes.id")),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_index("idx_life_items_domain_status_due", "life_items", ["domain", "status", "due_at"])
    op.create_table(
        "daily_logs",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("user_id", sa.String(length=64), sa.ForeignKey("users.id")),
        sa.Column("local_date", sa.String(length=10), nullable=False),
        sa.Column("domain", sa.String(length=64), nullable=False),
        sa.Column("log_type", sa.String(length=64), nullable=False),
        sa.Column("value_json", sa.JSON(), nullable=False),
        sa.Column("source_capture_id", sa.String(length=64), sa.ForeignKey("raw_captures.id")),
        sa.Column("review_item_id", sa.String(length=64), sa.ForeignKey("review_items.id")),
        sa.Column("confidence", sa.Numeric()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "finance_entries",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("local_date", sa.String(length=10), nullable=False),
        sa.Column("entry_type", sa.String(length=32), nullable=False),
        sa.Column("amount", sa.Numeric(), nullable=False),
        sa.Column("currency", sa.String(length=8), nullable=False),
        sa.Column("category", sa.String(length=64), nullable=False),
        sa.Column("note_md", sa.Text()),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("source_capture_id", sa.String(length=64), sa.ForeignKey("raw_captures.id")),
        sa.Column("review_item_id", sa.String(length=64), sa.ForeignKey("review_items.id")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "prayer_logs",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("user_id", sa.String(length=64), sa.ForeignKey("users.id")),
        sa.Column("local_date", sa.String(length=10), nullable=False),
        sa.Column("prayer", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("source_platform", sa.String(length=32)),
        sa.Column("source_external_message_id", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "jobs",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("description_md", sa.Text()),
        sa.Column("schedule_type", sa.String(length=32), nullable=False),
        sa.Column("schedule_json", sa.JSON(), nullable=False),
        sa.Column("timezone", sa.Text(), nullable=False),
        sa.Column("target_agent_id", sa.String(length=128)),
        sa.Column("command_json", sa.JSON(), nullable=False),
        sa.Column("approval_policy", sa.String(length=64), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("created_by_user_id", sa.String(length=64), sa.ForeignKey("users.id")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "job_runs",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("job_id", sa.String(length=64), sa.ForeignKey("jobs.id"), nullable=False),
        sa.Column("run_id", sa.String(length=64), sa.ForeignKey("agent_runs.id")),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True)),
        sa.Column("finished_at", sa.DateTime(timezone=True)),
        sa.Column("output_summary_md", sa.Text()),
        sa.Column("error_json", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "notifications",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("target_platform", sa.String(length=32), nullable=False),
        sa.Column("target_channel_id", sa.String(length=64), sa.ForeignKey("channels.id")),
        sa.Column("notification_type", sa.String(length=64), nullable=False),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("body_md", sa.Text(), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("related_run_id", sa.String(length=64), sa.ForeignKey("agent_runs.id")),
        sa.Column("related_review_item_id", sa.String(length=64), sa.ForeignKey("review_items.id")),
        sa.Column("external_message_id", sa.Text()),
        sa.Column("error_json", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("sent_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "dead_letter_items",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("source_kind", sa.String(length=64), nullable=False),
        sa.Column("source_id", sa.String(length=64)),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column("payload_json", sa.JSON(), nullable=False),
        sa.Column("vault_uri", sa.Text()),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("dead_letter_items")
    op.drop_table("notifications")
    op.drop_table("job_runs")
    op.drop_table("jobs")
    op.drop_table("prayer_logs")
    op.drop_table("finance_entries")
    op.drop_table("daily_logs")
    op.drop_index("idx_life_items_domain_status_due", table_name="life_items")
    op.drop_table("life_items")
    op.drop_index("idx_vault_index_domain", table_name="vault_index_entries")
    op.drop_table("vault_index_entries")
    op.drop_table("memory_facts")
    op.drop_table("memory_candidates")
    op.drop_table("provider_call_logs")
    op.drop_index("idx_tool_calls_run", table_name="tool_calls")
    op.drop_table("tool_calls")
    op.drop_table("tool_permissions")
    op.drop_table("tools")
    op.drop_table("handoffs")
    op.drop_table("messages")
    op.drop_constraint("fk_agent_runs_session", "agent_runs", type_="foreignkey")
    op.drop_table("agent_sessions")
    op.drop_table("agents")
    op.drop_table("review_bindings")
    op.drop_table("capture_interpretations")
    op.drop_table("capture_attachments")
    op.drop_column("agent_runs", "session_id")
    op.drop_column("review_items", "source_uri")
    op.drop_constraint("fk_raw_captures_user", "raw_captures", type_="foreignkey")
    op.drop_constraint("fk_raw_captures_channel", "raw_captures", type_="foreignkey")
    op.drop_column("raw_captures", "source_user_id")
    op.drop_column("raw_captures", "source_channel_id")
    op.drop_table("channels")
    op.drop_table("users")
