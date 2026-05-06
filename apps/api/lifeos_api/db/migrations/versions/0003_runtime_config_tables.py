"""runtime config tables

Revision ID: 0003_runtime_config_tables
Revises: 0002_phase_runtime_tables
Create Date: 2026-05-06
"""

from alembic import op
import sqlalchemy as sa

revision = "0003_runtime_config_tables"
down_revision = "0002_phase_runtime_tables"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "agent_model_configs",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("agent_id", sa.String(length=128), nullable=False, unique=True),
        sa.Column("primary_provider_id", sa.String(length=64)),
        sa.Column("primary_model", sa.Text()),
        sa.Column("secondary_provider_id", sa.String(length=64)),
        sa.Column("secondary_model", sa.Text()),
        sa.Column("fallback_allowed", sa.Boolean(), nullable=False),
        sa.Column("settings_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "provider_runtime_configs",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("provider_id", sa.String(length=64), nullable=False, unique=True),
        sa.Column("display_name", sa.Text(), nullable=False),
        sa.Column("provider_type", sa.String(length=64), nullable=False),
        sa.Column("base_url", sa.Text()),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("key_refs_json", sa.JSON(), nullable=False),
        sa.Column("settings_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "system_settings",
        sa.Column("key", sa.String(length=128), primary_key=True),
        sa.Column("value_json", sa.JSON(), nullable=False),
        sa.Column("description", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )


def downgrade() -> None:
    op.drop_table("system_settings")
    op.drop_table("provider_runtime_configs")
    op.drop_table("agent_model_configs")
