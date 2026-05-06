"""initial spine tables

Revision ID: 0001_initial_spine
Revises:
Create Date: 2026-05-06
"""

from alembic import op
import sqlalchemy as sa

revision = "0001_initial_spine"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "raw_captures",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("source_platform", sa.String(length=32), nullable=False),
        sa.Column("source_external_message_id", sa.String(length=255)),
        sa.Column("source_thread_id", sa.String(length=255)),
        sa.Column("capture_kind", sa.String(length=32), nullable=False),
        sa.Column("raw_text", sa.Text()),
        sa.Column("raw_uri", sa.Text(), nullable=False),
        sa.Column("content_hash", sa.String(length=128), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("sensitivity", sa.String(length=32), nullable=False),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_index("idx_raw_captures_status_created", "raw_captures", ["status", "created_at"])

    op.create_table(
        "review_items",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("kind", sa.String(length=64), nullable=False),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("body_md", sa.Text(), nullable=False),
        sa.Column("source_capture_id", sa.String(length=64), sa.ForeignKey("raw_captures.id")),
        sa.Column("proposed_by_agent_id", sa.String(length=128)),
        sa.Column("assigned_agent_id", sa.String(length=128)),
        sa.Column("priority", sa.String(length=32), nullable=False),
        sa.Column("confidence", sa.Numeric()),
        sa.Column("risk_level", sa.String(length=64), nullable=False),
        sa.Column("sensitivity", sa.String(length=32), nullable=False),
        sa.Column("proposed_action_json", sa.JSON(), nullable=False),
        sa.Column("validation_json", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True)),
        sa.Column("snoozed_until", sa.DateTime(timezone=True)),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_index("idx_review_items_status_priority", "review_items", ["status", "priority", "created_at"])

    op.create_table(
        "review_decisions",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("review_item_id", sa.String(length=64), sa.ForeignKey("review_items.id"), nullable=False),
        sa.Column("user_id", sa.String(length=64)),
        sa.Column("decision", sa.String(length=32), nullable=False),
        sa.Column("decision_text", sa.Text()),
        sa.Column("decision_payload", sa.JSON(), nullable=False),
        sa.Column("source_platform", sa.String(length=32), nullable=False),
        sa.Column("source_external_message_id", sa.String(length=255)),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "state_changes",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("review_item_id", sa.String(length=64), sa.ForeignKey("review_items.id")),
        sa.Column("command_type", sa.String(length=128), nullable=False),
        sa.Column("command_payload", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("applied_by", sa.String(length=64), nullable=False),
        sa.Column("before_snapshot_uri", sa.Text()),
        sa.Column("after_snapshot_uri", sa.Text()),
        sa.Column("error_json", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("applied_at", sa.DateTime(timezone=True)),
    )

    op.create_table(
        "agent_runs",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("root_capture_id", sa.String(length=64), sa.ForeignKey("raw_captures.id")),
        sa.Column("initiating_user_id", sa.String(length=64)),
        sa.Column("orchestrator_agent_id", sa.String(length=128), nullable=False),
        sa.Column("active_agent_id", sa.String(length=128)),
        sa.Column("status", sa.String(length=64), nullable=False),
        sa.Column("status_summary", sa.Text()),
        sa.Column("provider_used", sa.String(length=64)),
        sa.Column("model_used", sa.String(length=128)),
        sa.Column("cost_usd", sa.Numeric()),
        sa.Column("token_usage_json", sa.JSON()),
        sa.Column("trace_id", sa.String(length=128)),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
        sa.Column("finished_at", sa.DateTime(timezone=True)),
    )
    op.create_index("idx_agent_runs_status_created", "agent_runs", ["status", "created_at"])

    op.create_table(
        "status_events",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("run_id", sa.String(length=64), sa.ForeignKey("agent_runs.id")),
        sa.Column("event_type", sa.String(length=128), nullable=False),
        sa.Column("visibility", sa.String(length=32), nullable=False),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("detail_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "audit_events",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("actor_type", sa.String(length=32), nullable=False),
        sa.Column("actor_id", sa.String(length=128), nullable=False),
        sa.Column("event_type", sa.String(length=128), nullable=False),
        sa.Column("entity_type", sa.String(length=128), nullable=False),
        sa.Column("entity_id", sa.String(length=128), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("before_json", sa.JSON()),
        sa.Column("after_json", sa.JSON()),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("trace_id", sa.String(length=128)),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("idx_audit_entity", "audit_events", ["entity_type", "entity_id", "created_at"])


def downgrade() -> None:
    op.drop_index("idx_audit_entity", table_name="audit_events")
    op.drop_table("audit_events")
    op.drop_table("status_events")
    op.drop_index("idx_agent_runs_status_created", table_name="agent_runs")
    op.drop_table("agent_runs")
    op.drop_table("state_changes")
    op.drop_table("review_decisions")
    op.drop_index("idx_review_items_status_priority", table_name="review_items")
    op.drop_table("review_items")
    op.drop_index("idx_raw_captures_status_created", table_name="raw_captures")
    op.drop_table("raw_captures")
