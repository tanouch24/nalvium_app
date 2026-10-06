"""communauté : publications, médias publics dérivés, utile, sauvegardes, commentaires, signalements

Revision ID: 0008
Revises: 0007
"""
import sqlalchemy as sa
from alembic import op

revision = '0008'
down_revision = '0007'
branch_labels = None
depends_on = None

_NOW = sa.text('now()')


def upgrade() -> None:
    op.create_table('community_posts',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('owner_user_id', sa.UUID(), nullable=False),
    sa.Column('title', sa.String(length=120), nullable=False),
    sa.Column('solution', sa.Text(), nullable=False),
    sa.Column('category', sa.String(length=16), nullable=True),
    sa.Column('materials', sa.String(length=200), nullable=True),
    sa.Column('status', sa.String(length=12), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
    sa.ForeignKeyConstraint(['owner_user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id'))
    op.create_index('ix_community_posts_owner_user_id', 'community_posts', ['owner_user_id'])
    op.create_index('ix_community_posts_status', 'community_posts', ['status'])
    op.create_index('ix_community_posts_feed', 'community_posts', ['created_at', 'id'])

    op.create_table('community_media',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('owner_user_id', sa.UUID(), nullable=False),
    sa.Column('post_id', sa.UUID(), nullable=True),
    sa.Column('source_private_media_id', sa.UUID(), nullable=True),
    sa.Column('storage_key', sa.String(length=512), nullable=False),
    sa.Column('thumb_key', sa.String(length=512), nullable=False),
    sa.Column('mime_type', sa.String(length=32), nullable=False),
    sa.Column('width', sa.Integer(), nullable=True),
    sa.Column('height', sa.Integer(), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
    sa.ForeignKeyConstraint(['owner_user_id'], ['users.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['post_id'], ['community_posts.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['source_private_media_id'], ['media_assets.id'], ondelete='SET NULL'),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('storage_key'), sa.UniqueConstraint('thumb_key'))
    op.create_index('ix_community_media_owner_user_id', 'community_media', ['owner_user_id'])
    op.create_index('ix_community_media_post_id', 'community_media', ['post_id'])

    for name in ('community_helpful', 'community_saves'):
        op.create_table(name,
        sa.Column('post_id', sa.UUID(), nullable=False),
        sa.Column('owner_user_id', sa.UUID(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
        sa.ForeignKeyConstraint(['post_id'], ['community_posts.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['owner_user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('post_id', 'owner_user_id'))
        op.create_index(f'ix_{name}_owner_user_id', name, ['owner_user_id'])

    op.create_table('community_comments',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('post_id', sa.UUID(), nullable=False),
    sa.Column('owner_user_id', sa.UUID(), nullable=False),
    sa.Column('body', sa.String(length=500), nullable=False),
    sa.Column('status', sa.String(length=12), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
    sa.ForeignKeyConstraint(['post_id'], ['community_posts.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['owner_user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id'))
    op.create_index('ix_community_comments_post_id', 'community_comments', ['post_id'])
    op.create_index('ix_community_comments_owner_user_id', 'community_comments', ['owner_user_id'])

    op.create_table('community_reports',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('reporter_user_id', sa.UUID(), nullable=False),
    sa.Column('post_id', sa.UUID(), nullable=True),
    sa.Column('comment_id', sa.UUID(), nullable=True),
    sa.Column('reason', sa.String(length=24), nullable=False),
    sa.Column('details', sa.String(length=300), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=_NOW, nullable=False),
    sa.ForeignKeyConstraint(['reporter_user_id'], ['users.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['post_id'], ['community_posts.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['comment_id'], ['community_comments.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id'))
    op.create_index('ix_community_reports_reporter_user_id', 'community_reports', ['reporter_user_id'])
    # Pas de doublon : un seul signalement par (auteur, publication) et par (auteur, commentaire).
    op.create_index('uq_report_post', 'community_reports', ['reporter_user_id', 'post_id'], unique=True,
                    postgresql_where=sa.text('comment_id IS NULL'))
    op.create_index('uq_report_comment', 'community_reports', ['reporter_user_id', 'comment_id'], unique=True,
                    postgresql_where=sa.text('comment_id IS NOT NULL'))


def downgrade() -> None:
    for t in ('community_reports', 'community_comments', 'community_saves', 'community_helpful', 'community_media',
              'community_posts'):
        op.drop_table(t)
