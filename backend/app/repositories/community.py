import base64
import uuid
from datetime import datetime

from sqlalchemy import and_, delete, exists, func, or_, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.orm import Session, selectinload

from app.db.models import (
    CommunityComment,
    CommunityHelpful,
    CommunityMedia,
    CommunityPost,
    CommunityReport,
    CommunitySave,
)


def encode_cursor(created: datetime, ident: uuid.UUID) -> str:
    return base64.urlsafe_b64encode(f"{created.isoformat()}|{ident}".encode()).decode()


def decode_cursor(cursor: str) -> tuple[datetime, uuid.UUID]:
    raw = base64.urlsafe_b64decode(cursor.encode()).decode()
    ts, ident = raw.split("|")
    return datetime.fromisoformat(ts), uuid.UUID(ident)


class CommunityRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    # ---- posts ------------------------------------------------------------
    def add(self, obj):
        self._db.add(obj)
        self._db.flush()
        return obj

    def post(self, post_id: uuid.UUID, *, published_only: bool = True) -> CommunityPost | None:
        stmt = select(CommunityPost).where(CommunityPost.id == post_id).options(selectinload(CommunityPost.media))
        if published_only:
            stmt = stmt.where(CommunityPost.status == "PUBLISHED")
        return self._db.execute(stmt).scalar_one_or_none()

    def page(self, viewer: uuid.UUID, *, cursor: str | None, limit: int, saved_only: bool = False):
        """Une requête pour la page (compteurs et états du lecteur calculés en SQL : pas de N+1). Clé stable
        (created_at, id) : pas de doublon ni de trou quand de nouveaux posts arrivent pendant le défilement."""
        helpful = select(func.count()).where(CommunityHelpful.post_id == CommunityPost.id).scalar_subquery()
        comments = (
            select(func.count())
            .where(CommunityComment.post_id == CommunityPost.id, CommunityComment.status == "PUBLISHED")
            .scalar_subquery()
        )
        my_helpful = exists().where(CommunityHelpful.post_id == CommunityPost.id, CommunityHelpful.owner_user_id == viewer)
        my_save = exists().where(CommunitySave.post_id == CommunityPost.id, CommunitySave.owner_user_id == viewer)
        stmt = (
            select(CommunityPost, helpful, comments, my_helpful, my_save)
            .where(CommunityPost.status == "PUBLISHED")
            .options(selectinload(CommunityPost.media))
            .order_by(CommunityPost.created_at.desc(), CommunityPost.id.desc())
            .limit(limit + 1)
        )
        if saved_only:
            stmt = stmt.where(my_save)
        if cursor:
            created, ident = decode_cursor(cursor)
            stmt = stmt.where(
                or_(CommunityPost.created_at < created, and_(CommunityPost.created_at == created, CommunityPost.id < ident))
            )
        rows = self._db.execute(stmt).all()
        has_more = len(rows) > limit
        return rows[:limit], has_more

    def one(self, post_id: uuid.UUID, viewer: uuid.UUID):
        helpful = select(func.count()).where(CommunityHelpful.post_id == post_id).scalar_subquery()
        comments = (
            select(func.count())
            .where(CommunityComment.post_id == post_id, CommunityComment.status == "PUBLISHED")
            .scalar_subquery()
        )
        my_helpful = exists().where(CommunityHelpful.post_id == post_id, CommunityHelpful.owner_user_id == viewer)
        my_save = exists().where(CommunitySave.post_id == post_id, CommunitySave.owner_user_id == viewer)
        stmt = (
            select(CommunityPost, helpful, comments, my_helpful, my_save)
            .where(CommunityPost.id == post_id, CommunityPost.status == "PUBLISHED")
            .options(selectinload(CommunityPost.media))
        )
        return self._db.execute(stmt).first()

    # ---- médias -----------------------------------------------------------
    def media(self, media_id: uuid.UUID) -> CommunityMedia | None:
        return self._db.get(CommunityMedia, media_id)

    def delete_media(self, media: CommunityMedia) -> None:
        self._db.delete(media)
        self._db.flush()

    # ---- utile / sauvegardes ---------------------------------------------
    def set_helpful(self, post_id, user_id, on: bool) -> None:
        if on:
            self._db.execute(pg_insert(CommunityHelpful).values(post_id=post_id, owner_user_id=user_id).on_conflict_do_nothing())
        else:
            self._db.execute(delete(CommunityHelpful).where(CommunityHelpful.post_id == post_id, CommunityHelpful.owner_user_id == user_id))

    def set_saved(self, post_id, user_id, on: bool) -> None:
        if on:
            self._db.execute(pg_insert(CommunitySave).values(post_id=post_id, owner_user_id=user_id).on_conflict_do_nothing())
        else:
            self._db.execute(delete(CommunitySave).where(CommunitySave.post_id == post_id, CommunitySave.owner_user_id == user_id))

    # ---- commentaires -----------------------------------------------------
    def comment(self, comment_id: uuid.UUID) -> CommunityComment | None:
        return self._db.get(CommunityComment, comment_id)

    def comments(self, post_id: uuid.UUID, *, cursor: str | None, limit: int):
        stmt = (
            select(CommunityComment)
            .where(CommunityComment.post_id == post_id, CommunityComment.status == "PUBLISHED")
            .order_by(CommunityComment.created_at.asc(), CommunityComment.id.asc())
            .limit(limit + 1)
        )
        if cursor:
            created, ident = decode_cursor(cursor)
            stmt = stmt.where(
                or_(CommunityComment.created_at > created, and_(CommunityComment.created_at == created, CommunityComment.id > ident))
            )
        rows = list(self._db.execute(stmt).scalars())
        return rows[:limit], len(rows) > limit

    # ---- signalements -----------------------------------------------------
    def add_report(self, reporter, reason, details, *, post_id=None, comment_id=None) -> bool:
        """True si créé ; False si ce membre avait déjà signalé cette cible (aucun doublon)."""
        stmt = (
            pg_insert(CommunityReport)
            .values(reporter_user_id=reporter, post_id=post_id, comment_id=comment_id, reason=reason, details=details)
            .on_conflict_do_nothing()
            .returning(CommunityReport.id)
        )
        return self._db.execute(stmt).first() is not None

    def commit(self) -> None:
        self._db.commit()
