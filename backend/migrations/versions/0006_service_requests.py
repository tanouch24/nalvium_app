"""service requests (demandes d'intervention) + médias sélectionnés

Revision ID: 0006
Revises: 0005
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = '0006'
down_revision = '0005'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table('service_requests',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('user_id', sa.UUID(), nullable=False),
    sa.Column('diagnostic_session_id', sa.UUID(), nullable=True),
    sa.Column('equipment_id', sa.UUID(), nullable=True),
    sa.Column('status', sa.String(length=20), nullable=False),
    sa.Column('problem_category', sa.String(length=32), nullable=True),
    sa.Column('problem_summary', sa.Text(), nullable=True),
    sa.Column('structured_context', postgresql.JSONB(), nullable=True),
    sa.Column('first_name', sa.String(length=60), nullable=True),
    sa.Column('phone', sa.String(length=20), nullable=True),
    sa.Column('email', sa.String(length=120), nullable=True),
    sa.Column('city', sa.String(length=80), nullable=True),
    sa.Column('postal_code', sa.String(length=5), nullable=True),
    sa.Column('availability_type', sa.String(length=16), nullable=True),
    sa.Column('preferred_date', sa.DateTime(timezone=True), nullable=True),
    sa.Column('preferred_time_window', sa.String(length=16), nullable=True),
    sa.Column('consent_version', sa.String(length=16), nullable=True),
    sa.Column('consented_at', sa.DateTime(timezone=True), nullable=True),
    sa.Column('consented_categories', postgresql.ARRAY(sa.String(length=24)), nullable=True),
    sa.Column('submitted_at', sa.DateTime(timezone=True), nullable=True),
    sa.Column('provider_id', sa.UUID(), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['diagnostic_session_id'], ['diagnostic_sessions.id'], ondelete='SET NULL'),
    sa.ForeignKeyConstraint(['equipment_id'], ['equipment.id'], ondelete='SET NULL'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_service_requests_user_id'), 'service_requests', ['user_id'], unique=False)
    op.create_index(op.f('ix_service_requests_diagnostic_session_id'), 'service_requests', ['diagnostic_session_id'], unique=False)
    op.create_table('service_request_media',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('service_request_id', sa.UUID(), nullable=False),
    sa.Column('media_asset_id', sa.UUID(), nullable=False),
    sa.Column('consented_at', sa.DateTime(timezone=True), nullable=True),
    sa.ForeignKeyConstraint(['service_request_id'], ['service_requests.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['media_asset_id'], ['media_assets.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_service_request_media_service_request_id'), 'service_request_media', ['service_request_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_service_request_media_service_request_id'), table_name='service_request_media')
    op.drop_table('service_request_media')
    op.drop_index(op.f('ix_service_requests_diagnostic_session_id'), table_name='service_requests')
    op.drop_index(op.f('ix_service_requests_user_id'), table_name='service_requests')
    op.drop_table('service_requests')
