"""equipment documents (manuals) + passages indexés + provenance des réponses

Revision ID: 0005
Revises: 0004
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = '0005'
down_revision = '0004'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table('equipment_documents',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('equipment_id', sa.UUID(), nullable=False),
    sa.Column('document_type', sa.String(length=16), nullable=False),
    sa.Column('status', sa.String(length=24), nullable=False),
    sa.Column('error_code', sa.String(length=48), nullable=True),
    sa.Column('title', sa.String(length=300), nullable=True),
    sa.Column('manufacturer', sa.String(length=60), nullable=True),
    sa.Column('model_reference', sa.String(length=80), nullable=True),
    sa.Column('source_url', sa.Text(), nullable=True),
    sa.Column('source_domain', sa.String(length=120), nullable=True),
    sa.Column('source_is_official', sa.Boolean(), nullable=False),
    sa.Column('storage_key', sa.String(length=512), nullable=True),
    sa.Column('mime_type', sa.String(length=64), nullable=True),
    sa.Column('file_size', sa.Integer(), nullable=True),
    sa.Column('checksum', sa.String(length=64), nullable=True),
    sa.Column('page_count', sa.Integer(), nullable=True),
    sa.Column('language', sa.String(length=8), nullable=True),
    sa.Column('match_level', sa.String(length=16), nullable=True),
    sa.Column('retrieved_at', sa.DateTime(timezone=True), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['equipment_id'], ['equipment.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_equipment_documents_equipment_id'), 'equipment_documents', ['equipment_id'], unique=False)

    op.create_table('document_chunks',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('document_id', sa.UUID(), nullable=False),
    sa.Column('idx', sa.Integer(), nullable=False),
    sa.Column('page', sa.Integer(), nullable=False),
    sa.Column('section', sa.String(length=200), nullable=True),
    sa.Column('text', sa.Text(), nullable=False),
    sa.Column('tsv', postgresql.TSVECTOR(), sa.Computed("to_tsvector('french', text)", persisted=True), nullable=False),
    sa.ForeignKeyConstraint(['document_id'], ['equipment_documents.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_document_chunks_document_id'), 'document_chunks', ['document_id'], unique=False)
    op.create_index('ix_document_chunks_tsv', 'document_chunks', ['tsv'], unique=False, postgresql_using='gin')

    op.add_column('session_messages', sa.Column('manual_document_id', sa.UUID(), nullable=True))
    op.add_column('session_messages', sa.Column('manual_pages', postgresql.ARRAY(sa.Integer()), nullable=True))
    op.create_foreign_key('fk_session_messages_manual_document', 'session_messages', 'equipment_documents',
                          ['manual_document_id'], ['id'], ondelete='SET NULL')


def downgrade() -> None:
    op.drop_constraint('fk_session_messages_manual_document', 'session_messages', type_='foreignkey')
    op.drop_column('session_messages', 'manual_pages')
    op.drop_column('session_messages', 'manual_document_id')
    op.drop_index('ix_document_chunks_tsv', table_name='document_chunks', postgresql_using='gin')
    op.drop_index(op.f('ix_document_chunks_document_id'), table_name='document_chunks')
    op.drop_table('document_chunks')
    op.drop_index(op.f('ix_equipment_documents_equipment_id'), table_name='equipment_documents')
    op.drop_table('equipment_documents')
