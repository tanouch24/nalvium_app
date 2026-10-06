import logging
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, Response, UploadFile

from app.api.deps import current_user_id, get_community_service, optional_user_id
from app.api.ratelimit import rate_limit
from app.api.schemas import (
    CommunityCommentCreate,
    CommunityCommentOut,
    CommunityCommentPage,
    CommunityFromPrivate,
    CommunityMediaOut,
    CommunityPage,
    CommunityPostCreate,
    CommunityPostOut,
    CommunityPostUpdate,
    CommunityReportIn,
    CommunityReportOut,
    community_post_out,
)
from app.community.rules import COMMUNITY_CONSENT_VERSION, InvalidContent
from app.config import get_settings
from app.services.community_service import CommunityService, Forbidden
from app.services.session_service import NotFound

# Journaux : identifiants techniques seulement (jamais le contenu des publications ni des commentaires).
log = logging.getLogger("nalvium.community")
router = APIRouter(prefix="/v1/community", tags=["community"])


def _guard(call):
    try:
        return call()
    except NotFound as exc:
        raise HTTPException(404, "not_found") from exc
    except Forbidden as exc:
        raise HTTPException(403, "forbidden") from exc
    except InvalidContent as exc:
        raise HTTPException(422, exc.code) from exc


@router.get("/consent-version")
def consent_version():
    return {"consent_version": COMMUNITY_CONSENT_VERSION}


@router.post("/media", response_model=CommunityMediaOut, status_code=201, dependencies=[Depends(rate_limit("upload", 60, 600))])
async def upload_photo(
    file: UploadFile = File(...),
    user_id: uuid.UUID = Depends(current_user_id),
    svc: CommunityService = Depends(get_community_service),
):
    """Photo prise pour la Communauté : nettoyée (EXIF/GPS), optimisée, copie publique distincte (brouillon)."""
    limit = get_settings().max_upload_bytes
    raw = await file.read(limit + 1)
    if len(raw) > limit:
        raise HTTPException(413, "file_too_large")
    m = _guard(lambda: svc.upload_photo(user_id, raw))
    return CommunityMediaOut(id=m.id, width=m.width, height=m.height)


@router.post("/media/from-private", response_model=CommunityMediaOut, status_code=201)
def derive_from_private(
    body: CommunityFromPrivate,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: CommunityService = Depends(get_community_service),
):
    """Copie PUBLIQUE dérivée d'une photo privée, après consentement explicite. L'original reste privé."""
    m = _guard(lambda: svc.derive_from_private(user_id, body.media_id, body.consent_public))
    return CommunityMediaOut(id=m.id, width=m.width, height=m.height)


@router.delete("/media/{media_id}", status_code=204)
def discard_media(media_id: uuid.UUID, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    _guard(lambda: svc.discard_draft_media(user_id, media_id))


@router.get("/media/{media_id}/{variant}")
def media_content(
    media_id: uuid.UUID,
    variant: str,
    viewer: uuid.UUID | None = Depends(optional_user_id),
    svc: CommunityService = Depends(get_community_service),
):
    """Image PUBLIQUE d'une publication (variante `thumb` pour la liste, `large` pour le détail)."""
    if variant not in ("thumb", "large"):
        raise HTTPException(404, "not_found")
    data, ctype = _guard(lambda: svc.read_media(media_id, variant, viewer))
    return Response(data, media_type=ctype, headers={"Cache-Control": "public, max-age=86400"})


@router.get("/posts", response_model=CommunityPage)
def feed(cursor: str | None = None, limit: int | None = None, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    items, nxt = _guard(lambda: svc.feed(user_id, cursor, limit))
    return CommunityPage(items=[community_post_out(r, user_id) for r in items], next_cursor=nxt)


@router.get("/saved", response_model=CommunityPage)
def saved(cursor: str | None = None, limit: int | None = None, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    items, nxt = _guard(lambda: svc.feed(user_id, cursor, limit, saved=True))
    return CommunityPage(items=[community_post_out(r, user_id) for r in items], next_cursor=nxt)


@router.post("/posts", response_model=CommunityPostOut, status_code=201, dependencies=[Depends(rate_limit("post", 20, 3600))])
def create_post(body: CommunityPostCreate, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    row = _guard(lambda: svc.create_post(
        user_id, title=body.title, solution=body.solution, category=body.category, materials=body.materials,
        media_id=body.media_id, consent=body.consent_public, consent_version=body.consent_version,
    ))
    log.info("post published id=%s", row.post.id)
    return community_post_out(row, user_id)


@router.get("/posts/{post_id}", response_model=CommunityPostOut)
def get_post(post_id: uuid.UUID, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    return community_post_out(_guard(lambda: svc.get(user_id, post_id)), user_id)


@router.patch("/posts/{post_id}", response_model=CommunityPostOut)
def update_post(post_id: uuid.UUID, body: CommunityPostUpdate, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    return community_post_out(_guard(lambda: svc.update_post(user_id, post_id, body.model_dump(exclude_unset=True))), user_id)


@router.delete("/posts/{post_id}", status_code=204)
def delete_post(post_id: uuid.UUID, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    _guard(lambda: svc.delete_post(user_id, post_id))
    log.info("post removed id=%s", post_id)


@router.put("/posts/{post_id}/helpful", response_model=CommunityPostOut)
def helpful_on(post_id: uuid.UUID, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    return community_post_out(_guard(lambda: svc.set_helpful(user_id, post_id, True)), user_id)


@router.delete("/posts/{post_id}/helpful", response_model=CommunityPostOut)
def helpful_off(post_id: uuid.UUID, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    return community_post_out(_guard(lambda: svc.set_helpful(user_id, post_id, False)), user_id)


@router.put("/posts/{post_id}/save", response_model=CommunityPostOut)
def save_on(post_id: uuid.UUID, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    return community_post_out(_guard(lambda: svc.set_saved(user_id, post_id, True)), user_id)


@router.delete("/posts/{post_id}/save", response_model=CommunityPostOut)
def save_off(post_id: uuid.UUID, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    return community_post_out(_guard(lambda: svc.set_saved(user_id, post_id, False)), user_id)


@router.get("/posts/{post_id}/comments", response_model=CommunityCommentPage)
def list_comments(post_id: uuid.UUID, cursor: str | None = None, limit: int | None = None, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    rows, nxt = _guard(lambda: svc.comments(post_id, cursor, limit))
    return CommunityCommentPage(
        items=[CommunityCommentOut(id=c.id, body=c.body, created_at=c.created_at, mine=c.owner_user_id == user_id) for c in rows],
        next_cursor=nxt,
    )


@router.post("/posts/{post_id}/comments", response_model=CommunityCommentOut, status_code=201, dependencies=[Depends(rate_limit("comment", 60, 600))])
def add_comment(post_id: uuid.UUID, body: CommunityCommentCreate, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    c = _guard(lambda: svc.add_comment(user_id, post_id, body.body))
    return CommunityCommentOut(id=c.id, body=c.body, created_at=c.created_at, mine=True)


@router.delete("/comments/{comment_id}", status_code=204)
def delete_comment(comment_id: uuid.UUID, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    _guard(lambda: svc.delete_comment(user_id, comment_id))


@router.post("/posts/{post_id}/report", response_model=CommunityReportOut, dependencies=[Depends(rate_limit("report", 30, 3600))])
def report_post(post_id: uuid.UUID, body: CommunityReportIn, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    return CommunityReportOut(created=_guard(lambda: svc.report(user_id, post_id=post_id, reason=body.reason, details=body.details)))


@router.post("/comments/{comment_id}/report", response_model=CommunityReportOut, dependencies=[Depends(rate_limit("report", 30, 3600))])
def report_comment(comment_id: uuid.UUID, body: CommunityReportIn, user_id: uuid.UUID = Depends(current_user_id), svc: CommunityService = Depends(get_community_service)):
    return CommunityReportOut(created=_guard(lambda: svc.report(user_id, comment_id=comment_id, reason=body.reason, details=body.details)))
