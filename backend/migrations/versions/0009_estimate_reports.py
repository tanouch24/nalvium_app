"""estimation indicative sur la session + signalement des résultats

Revision ID: 0009
Revises: 0008
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = '0009'
down_revision = '0008'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('diagnostic_sessions', sa.Column('estimate', postgresql.JSONB(astext_type=sa.Text()), nullable=True))
    op.create_table('result_reports',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('user_id', sa.UUID(), nullable=False),
    sa.Column('session_id', sa.UUID(), nullable=False),
    sa.Column('reason', sa.String(length=24), nullable=False),
    sa.Column('details', sa.String(length=500), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['session_id'], ['diagnostic_sessions.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id'))
    op.create_index('ix_result_reports_user_id', 'result_reports', ['user_id'])
    op.create_index('ix_result_reports_session_id', 'result_reports', ['session_id'])


def downgrade() -> None:
    op.drop_index('ix_result_reports_session_id', table_name='result_reports')
    op.drop_index('ix_result_reports_user_id', table_name='result_reports')
    op.drop_table('result_reports')
    op.drop_column('diagnostic_sessions', 'estimate')
