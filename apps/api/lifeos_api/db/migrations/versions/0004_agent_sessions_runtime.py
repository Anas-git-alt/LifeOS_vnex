"""agent sessions runtime

Revision ID: 0004_agent_sessions_runtime
Revises: 0003_runtime_config_tables
Create Date: 2026-05-06
"""

from alembic import op
import sqlalchemy as sa

revision = "0004_agent_sessions_runtime"
down_revision = "0003_runtime_config_tables"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("agent_sessions", sa.Column("iteration_cap", sa.Integer(), nullable=False, server_default="5"))
    op.add_column("agent_sessions", sa.Column("visibility", sa.String(length=32), nullable=False, server_default="private"))
    op.add_column("agent_sessions", sa.Column("source_platform", sa.String(length=32)))
    op.add_column("agent_sessions", sa.Column("external_channel_id", sa.Text()))
    op.add_column("agent_sessions", sa.Column("external_thread_id", sa.Text()))
    op.add_column("agent_sessions", sa.Column("external_message_id", sa.Text()))
    op.add_column("agent_sessions", sa.Column("last_run_id", sa.String(length=64)))
    op.add_column("agent_sessions", sa.Column("last_user_correction_id", sa.String(length=64)))
    op.add_column("agent_sessions", sa.Column("paused_run_id", sa.String(length=64)))
    op.add_column("agent_sessions", sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"))
    op.create_index("idx_agent_sessions_discord_binding", "agent_sessions", ["source_platform", "external_channel_id", "external_thread_id"])

    op.add_column("messages", sa.Column("source_external_channel_id", sa.Text()))
    op.add_column("messages", sa.Column("source_external_thread_id", sa.Text()))
    op.add_column("messages", sa.Column("metadata_json", sa.JSON(), nullable=False, server_default="{}"))

    op.add_column("agent_runs", sa.Column("iteration_cap", sa.Integer(), nullable=False, server_default="5"))
    op.add_column("agent_runs", sa.Column("current_iteration", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("agent_runs", sa.Column("cancel_requested", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column("agent_runs", sa.Column("cancelled_at", sa.DateTime(timezone=True)))
    op.add_column("agent_runs", sa.Column("result_json", sa.JSON(), nullable=False, server_default="{}"))

    op.add_column("handoffs", sa.Column("known_context", sa.JSON(), nullable=False, server_default="[]"))
    op.add_column("handoffs", sa.Column("constraints", sa.JSON(), nullable=False, server_default="[]"))
    op.add_column("handoffs", sa.Column("result_json", sa.JSON(), nullable=False, server_default="{}"))
    op.add_column("handoffs", sa.Column("summary_md", sa.Text()))
    op.add_column("handoffs", sa.Column("risk_level", sa.String(length=32), nullable=False, server_default="normal"))
    op.add_column("handoffs", sa.Column("requires_user_visibility", sa.Boolean(), nullable=False, server_default=sa.true()))


def downgrade() -> None:
    op.drop_column("handoffs", "requires_user_visibility")
    op.drop_column("handoffs", "risk_level")
    op.drop_column("handoffs", "summary_md")
    op.drop_column("handoffs", "result_json")
    op.drop_column("handoffs", "constraints")
    op.drop_column("handoffs", "known_context")

    op.drop_column("agent_runs", "result_json")
    op.drop_column("agent_runs", "cancelled_at")
    op.drop_column("agent_runs", "cancel_requested")
    op.drop_column("agent_runs", "current_iteration")
    op.drop_column("agent_runs", "iteration_cap")

    op.drop_column("messages", "metadata_json")
    op.drop_column("messages", "source_external_thread_id")
    op.drop_column("messages", "source_external_channel_id")

    op.drop_index("idx_agent_sessions_discord_binding", table_name="agent_sessions")
    op.drop_column("agent_sessions", "metadata_json")
    op.drop_column("agent_sessions", "paused_run_id")
    op.drop_column("agent_sessions", "last_user_correction_id")
    op.drop_column("agent_sessions", "last_run_id")
    op.drop_column("agent_sessions", "external_message_id")
    op.drop_column("agent_sessions", "external_thread_id")
    op.drop_column("agent_sessions", "external_channel_id")
    op.drop_column("agent_sessions", "source_platform")
    op.drop_column("agent_sessions", "visibility")
    op.drop_column("agent_sessions", "iteration_cap")
