"""Communauté : publications, médias PUBLICS dérivés, Utile, sauvegardes, commentaires, signalements.

Règles : l'auteur n'est jamais exposé ; une photo privée ne devient jamais publique directement (copie dérivée,
nettoyée, après consentement explicite) ; aucune modération IA ; garde-fous déterministes seulement."""
import uuid
from dataclasses import dataclass

from app.community.rules import (
    COMMENT_MAX,
    COMMUNITY_CONSENT_VERSION,
    PAGE_DEFAULT,
    PAGE_MAX,
    REPORT_REASONS,
    InvalidContent,
    check_safety,
    clean,
    validate_post,
)
from app.db.models import CommunityComment, CommunityMedia, CommunityPost
from app.media.pipeline import InvalidImageError, ProcessedImage, make_thumbnail, process_photo
from app.media.storage import MediaStorage
from app.repositories.community import CommunityRepository, encode_cursor
from app.repositories.sessions import MediaRepository, UserRepository
from app.services.session_service import NotFound

DETAIL_SIDE = 1280


class Forbidden(Exception):
    pass


@dataclass(frozen=True)
class PostRow:
    post: CommunityPost
    helpful: int
    comments: int
    my_helpful: bool
    my_saved: bool


def _row(r) -> PostRow:
    return PostRow(r[0], r[1], r[2], bool(r[3]), bool(r[4]))


class CommunityService:
    def __init__(self, users: UserRepository, repo: CommunityRepository, media: MediaRepository, storage: MediaStorage):
        self._users, self._repo, self._media, self._storage = users, repo, media, storage

    # ---- médias publics ----------------------------------------------------
    def _store_variants(self, user_id: uuid.UUID, image: ProcessedImage, source: uuid.UUID | None) -> CommunityMedia:
        mid = uuid.uuid4()
        key, thumb_key = f"community/{mid}.jpg", f"community/{mid}_t.jpg"
        detail = make_thumbnail(image, DETAIL_SIDE, 82)  # variante détail raisonnable
        self._storage.put(key, detail)
        self._storage.put(thumb_key, make_thumbnail(image))
        w, h = image.width, image.height
        scale = min(1.0, DETAIL_SIDE / max(w, h))
        media = CommunityMedia(
            id=mid, owner_user_id=user_id, post_id=None, source_private_media_id=source, storage_key=key,
            thumb_key=thumb_key, width=round(w * scale), height=round(h * scale),
        )
        self._repo.add(media)
        self._repo.commit()
        return media

    def upload_photo(self, user_id: uuid.UUID, raw: bytes) -> CommunityMedia:
        """Photo prise pour la Communauté : EXIF/GPS retirés, optimisée, asset public DISTINCT (brouillon)."""
        self._users.ensure(user_id)
        try:
            return self._store_variants(user_id, process_photo(raw), None)
        except InvalidImageError as exc:
            raise InvalidContent("invalid_image") from exc

    def derive_from_private(self, user_id: uuid.UUID, private_media_id: uuid.UUID, consent: bool) -> CommunityMedia:
        """Copie PUBLIQUE dérivée d'une photo privée. Consentement explicite obligatoire ; l'original reste privé."""
        if not consent:
            raise InvalidContent("public_consent_required")
        asset = self._media.get_owned(private_media_id, user_id)
        if asset is None or asset.kind != "photo":
            raise NotFound
        self._users.ensure(user_id)
        try:
            image = process_photo(self._storage.get(asset.storage_key))  # re-nettoyage complet
        except InvalidImageError as exc:
            raise InvalidContent("invalid_image") from exc
        return self._store_variants(user_id, image, asset.id)

    def discard_draft_media(self, user_id: uuid.UUID, media_id: uuid.UUID) -> None:
        m = self._repo.media(media_id)
        if m is None or m.owner_user_id != user_id or m.post_id is not None:
            raise NotFound
        self._drop_files(m)
        self._repo.delete_media(m)
        self._repo.commit()

    def read_media(self, media_id: uuid.UUID, variant: str, viewer: uuid.UUID | None) -> tuple[bytes, str]:
        m = self._repo.media(media_id)
        if m is None:
            raise NotFound
        if m.post_id is None:  # brouillon : visible de son seul auteur
            if viewer is None or viewer != m.owner_user_id:
                raise NotFound
        elif self._repo.post(m.post_id) is None:  # post supprimé : plus de média
            raise NotFound
        return self._storage.get(m.thumb_key if variant == "thumb" else m.storage_key), m.mime_type

    def _drop_files(self, m: CommunityMedia) -> None:
        self._storage.delete(m.storage_key)
        self._storage.delete(m.thumb_key)

    # ---- publications ------------------------------------------------------
    def _attach(self, user_id: uuid.UUID, post: CommunityPost, media_id: uuid.UUID) -> None:
        m = self._repo.media(media_id)
        if m is None or m.owner_user_id != user_id or (m.post_id not in (None, post.id)):
            raise InvalidContent("unknown_media")
        m.post_id = post.id

    def create_post(self, user_id: uuid.UUID, *, title, solution, category, materials, media_id, consent: bool, consent_version: str) -> PostRow:
        if not consent:
            raise InvalidContent("public_consent_required")
        if consent_version != COMMUNITY_CONSENT_VERSION:
            raise InvalidContent("consent_version_mismatch")
        fields = validate_post(title, solution, category, materials)
        self._users.ensure(user_id)
        post = self._repo.add(CommunityPost(owner_user_id=user_id, status="PUBLISHED", **fields))
        if media_id is not None:
            self._attach(user_id, post, media_id)
        self._repo.commit()
        return self.get(user_id, post.id)

    def get(self, viewer: uuid.UUID, post_id: uuid.UUID) -> PostRow:
        row = self._repo.one(post_id, viewer)
        if row is None:
            raise NotFound
        return _row(row)

    def update_post(self, user_id: uuid.UUID, post_id: uuid.UUID, fields: dict) -> PostRow:
        post = self._repo.post(post_id)
        if post is None:
            raise NotFound
        if post.owner_user_id != user_id:
            raise Forbidden
        merged = validate_post(
            fields.get("title", post.title), fields.get("solution", post.solution),
            fields.get("category", post.category), fields.get("materials", post.materials),
        )
        for k, v in merged.items():
            setattr(post, k, v)
        if "media_id" in fields:
            for old in list(post.media):
                if old.id != fields["media_id"]:
                    self._drop_files(old)
                    self._repo.delete_media(old)
            if fields["media_id"] is not None:
                self._attach(user_id, post, fields["media_id"])
        self._repo.commit()
        return self.get(user_id, post_id)

    def delete_post(self, user_id: uuid.UUID, post_id: uuid.UUID) -> None:
        post = self._repo.post(post_id)
        if post is None:
            raise NotFound
        if post.owner_user_id != user_id:
            raise Forbidden
        post.status = "REMOVED"  # retiré du fil, des sauvegardes et des détails ; commentaires conservés sans erreur
        for m in list(post.media):
            self._drop_files(m)
            self._repo.delete_media(m)
        self._repo.commit()

    def feed(self, viewer: uuid.UUID, cursor: str | None, limit: int | None, *, saved: bool = False):
        limit = min(max(limit or PAGE_DEFAULT, 1), PAGE_MAX)
        try:
            rows, more = self._repo.page(viewer, cursor=cursor, limit=limit, saved_only=saved)
        except (ValueError, UnicodeError) as exc:
            raise InvalidContent("invalid_cursor") from exc
        items = [_row(r) for r in rows]
        nxt = encode_cursor(items[-1].post.created_at, items[-1].post.id) if more and items else None
        return items, nxt

    # ---- Utile / sauvegarde -----------------------------------------------
    def set_helpful(self, user_id: uuid.UUID, post_id: uuid.UUID, on: bool) -> PostRow:
        self._visible(post_id)
        self._users.ensure(user_id)
        self._repo.set_helpful(post_id, user_id, on)
        self._repo.commit()
        return self.get(user_id, post_id)

    def set_saved(self, user_id: uuid.UUID, post_id: uuid.UUID, on: bool) -> PostRow:
        self._visible(post_id)
        self._users.ensure(user_id)
        self._repo.set_saved(post_id, user_id, on)
        self._repo.commit()
        return self.get(user_id, post_id)

    def _visible(self, post_id: uuid.UUID) -> CommunityPost:
        post = self._repo.post(post_id)
        if post is None:
            raise NotFound
        return post

    # ---- commentaires ------------------------------------------------------
    def add_comment(self, user_id: uuid.UUID, post_id: uuid.UUID, body: str | None) -> CommunityComment:
        self._visible(post_id)
        text = clean(body, COMMENT_MAX + 100)
        if not text:
            raise InvalidContent("comment_required")
        if len(text) > COMMENT_MAX:
            raise InvalidContent("comment_too_long")
        check_safety(text)
        self._users.ensure(user_id)
        c = self._repo.add(CommunityComment(post_id=post_id, owner_user_id=user_id, body=text, status="PUBLISHED"))
        self._repo.commit()
        return c

    def comments(self, post_id: uuid.UUID, cursor: str | None, limit: int | None):
        self._visible(post_id)
        limit = min(max(limit or PAGE_DEFAULT, 1), PAGE_MAX)
        try:
            rows, more = self._repo.comments(post_id, cursor=cursor, limit=limit)
        except (ValueError, UnicodeError) as exc:
            raise InvalidContent("invalid_cursor") from exc
        return rows, (encode_cursor(rows[-1].created_at, rows[-1].id) if more and rows else None)

    def delete_comment(self, user_id: uuid.UUID, comment_id: uuid.UUID) -> None:
        c = self._repo.comment(comment_id)
        if c is None or c.status != "PUBLISHED":
            raise NotFound
        if c.owner_user_id != user_id:
            raise Forbidden
        c.status = "REMOVED"
        self._repo.commit()

    # ---- signalements ------------------------------------------------------
    def report(self, user_id: uuid.UUID, *, post_id=None, comment_id=None, reason: str, details: str | None) -> bool:
        if reason not in REPORT_REASONS:
            raise InvalidContent("invalid_reason")
        if comment_id is not None:
            c = self._repo.comment(comment_id)
            if c is None or c.status != "PUBLISHED":
                raise NotFound
        else:
            self._visible(post_id)
        self._users.ensure(user_id)
        created = self._repo.add_report(user_id, reason, clean(details, 300), post_id=post_id if comment_id is None else None, comment_id=comment_id)
        self._repo.commit()
        return created
