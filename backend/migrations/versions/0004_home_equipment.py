"""home, rooms, equipment

Revision ID: 0004
Revises: 0003
"""
import sqlalchemy as sa
from alembic import op

revision = '0004'
down_revision = '0003'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table('homes',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('user_id', sa.UUID(), nullable=False),
    sa.Column('is_default', sa.Boolean(), server_default=sa.text('true'), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_homes_user_id'), 'homes', ['user_id'], unique=False)
    # Une seule Maison PAR DÉFAUT par utilisateur (plusieurs logements restent possibles plus tard).
    op.create_index('uq_homes_one_default_per_user', 'homes', ['user_id'], unique=True,
                    postgresql_where=sa.text('is_default'))

    op.create_table('rooms',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('home_id', sa.UUID(), nullable=False),
    sa.Column('name', sa.String(length=60), nullable=False),
    sa.Column('normalized_type', sa.String(length=24), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['home_id'], ['homes.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_rooms_home_id'), 'rooms', ['home_id'], unique=False)

    op.add_column('media_assets', sa.Column('thumb_key', sa.String(length=512), nullable=True))

    op.create_table('equipment',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('home_id', sa.UUID(), nullable=False),
    sa.Column('room_id', sa.UUID(), nullable=True),
    sa.Column('equipment_type', sa.String(length=32), nullable=False),
    sa.Column('display_name', sa.String(length=80), nullable=False),
    sa.Column('brand', sa.String(length=60), nullable=True),
    sa.Column('model', sa.String(length=80), nullable=True),
    sa.Column('primary_media_id', sa.UUID(), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['home_id'], ['homes.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['room_id'], ['rooms.id'], ondelete='SET NULL'),
    sa.ForeignKeyConstraint(['primary_media_id'], ['media_assets.id'], ondelete='SET NULL'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_equipment_home_id'), 'equipment', ['home_id'], unique=False)

    op.add_column('diagnostic_sessions', sa.Column('equipment_id', sa.UUID(), nullable=True))
    op.create_index(op.f('ix_diagnostic_sessions_equipment_id'), 'diagnostic_sessions', ['equipment_id'], unique=False)
    op.create_foreign_key('fk_diagnostic_sessions_equipment', 'diagnostic_sessions', 'equipment',
                          ['equipment_id'], ['id'], ondelete='SET NULL')


def downgrade() -> None:
    op.drop_constraint('fk_diagnostic_sessions_equipment', 'diagnostic_sessions', type_='foreignkey')
    op.drop_index(op.f('ix_diagnostic_sessions_equipment_id'), table_name='diagnostic_sessions')
    op.drop_column('diagnostic_sessions', 'equipment_id')
    op.drop_index(op.f('ix_equipment_home_id'), table_name='equipment')
    op.drop_table('equipment')
    op.drop_column('media_assets', 'thumb_key')
    op.drop_index(op.f('ix_rooms_home_id'), table_name='rooms')
    op.drop_table('rooms')
    op.drop_index('uq_homes_one_default_per_user', table_name='homes')
    op.drop_index(op.f('ix_homes_user_id'), table_name='homes')
    op.drop_table('homes')
