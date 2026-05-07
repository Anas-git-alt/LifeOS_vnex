"""pending conversational action proposals

Revision ID: 0005_pending_action_proposals
Revises: 0004_agent_sessions_runtime
Create Date: 2026-05-06
"""

from alembic import op
import sqlalchemy as sa

revision = "0005_pending_action_proposals"
down_revision = "0004_agent_sessions_runtime"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "pending_action_proposals",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("session_id", sa.String(length=64), sa.ForeignKey("agent_sessions.id")),
        sa.Column("source_message_id", sa.String(length=64), sa.ForeignKey("messages.id")),
        sa.Column("source", sa.String(length=32), nullable=False),
        sa.Column("agent_name", sa.String(length=128), nullable=False),
        sa.Column("proposal_type", sa.String(length=128), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("draft_json", sa.JSON(), nullable=False),
        sa.Column("risk_level", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True)),
        sa.Column("last_revised_at", sa.DateTime(timezone=True)),
        sa.Column("executed_command_id", sa.String(length=64), sa.ForeignKey("state_changes.id")),
        sa.Column("review_item_id", sa.String(length=64), sa.ForeignKey("review_items.id")),
    )
    op.create_index(
        "idx_pending_action_proposals_session_status_created",
        "pending_action_proposals",
        ["session_id", "status", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("idx_pending_action_proposals_session_status_created", table_name="pending_action_proposals")
    op.drop_table("pending_action_proposals")
