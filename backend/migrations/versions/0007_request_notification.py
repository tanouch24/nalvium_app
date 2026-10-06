"""suivi de la notification interne des demandes

Revision ID: 0007
Revises: 0006
"""
import sqlalchemy as sa
from alembic import op

revision = '0007'
down_revision = '0006'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('service_requests', sa.Column('notification_status', sa.String(length=16), nullable=True))
    op.add_column('service_requests', sa.Column('notification_error', sa.String(length=48), nullable=True))
    op.add_column('service_requests', sa.Column('notification_attempted_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('service_requests', sa.Column('notification_sent_at', sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column('service_requests', 'notification_sent_at')
    op.drop_column('service_requests', 'notification_attempted_at')
    op.drop_column('service_requests', 'notification_error')
    op.drop_column('service_requests', 'notification_status')
