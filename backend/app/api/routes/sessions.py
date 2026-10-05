import logging
import time
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, Response, UploadFile

from app.ai.provider import AIProviderError, AIProviderNotConfigured
from app.api.deps import current_user_id, get_session_service
from app.api.schemas import (
    MediaOut,
    SessionOut,
    SessionSummary,
    TurnRequest,
    session_out,
    summary_out,
)
from app.config import get_settings
from app.media.pipeline import InvalidImageError, process_photo
from app.services.session_service import InvalidTurn, NotFound, SessionService, TurnInput

log = logging.getLogger("nalvium.api")
router = APIRouter(prefix="/v1", tags=["sessions"])


@router.post("/sessions", response_model=SessionOut, status_code=201)
def create_session(
    user_id: uuid.UUID = Depends(current_user_id), svc: SessionService = Depends(get_session_service)
):
    session = svc.create(user_id)
    log.info("session created id=%s", session.id)
    return session_out(session)


@router.get("/sessions", response_model=list[SessionSummary])
def list_sessions(
    active: bool = False,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: SessionService = Depends(get_session_service),
):
    return [summary_out(s) for s in svc.list(user_id, active_only=active)]


@router.get("/sessions/{session_id}", response_model=SessionOut)
def get_session(
    session_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: SessionService = Depends(get_session_service),
):
    try:
        return session_out(svc.get(user_id, session_id))
    except NotFound as exc:
        raise HTTPException(404, "session_not_found") from exc


@router.post("/sessions/{session_id}/media", response_model=MediaOut, status_code=201)
async def upload_media(
    session_id: uuid.UUID,
    file: UploadFile = File(...),
    user_id: uuid.UUID = Depends(current_user_id),
    svc: SessionService = Depends(get_session_service),
):
    limit = get_settings().max_upload_bytes
    raw = await file.read(limit + 1)
    if len(raw) > limit:
        raise HTTPException(413, "file_too_large")
    try:
        image = process_photo(raw)
        asset = svc.add_photo(user_id, session_id, image)
    except InvalidImageError as exc:
        raise HTTPException(422, "invalid_image") from exc
    except NotFound as exc:
        raise HTTPException(404, "session_not_found") from exc
    except InvalidTurn as exc:
        raise HTTPException(409, str(exc)) from exc
    log.info(
        "media uploaded session=%s bytes_in=%d bytes_stored=%d size=%dx%d private",
        session_id, len(raw), asset.size_bytes, asset.width or 0, asset.height or 0,
    )
    return MediaOut(id=asset.id, width=asset.width, height=asset.height)


@router.post("/sessions/{session_id}/turn", response_model=SessionOut)
async def turn(
    session_id: uuid.UUID,
    body: TurnRequest | None = None,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: SessionService = Depends(get_session_service),
):
    """Enregistre l'entrée utilisateur puis analyse. Sans corps : relance l'analyse en attente."""
    inp = (
        TurnInput(kind=body.kind, text=body.text, choice=body.choice, media_id=body.media_id)
        if body
        else None
    )
    started = time.monotonic()
    try:
        result = await svc.turn(user_id, session_id, inp)
        out = session_out(result)
        log.info(
            "turn session=%s input=%s -> state=%s status=%s duration=%.1fs",
            session_id, inp.kind if inp else "retry", out.current_state, out.status,
            time.monotonic() - started,
        )
        return out
    except NotFound as exc:
        raise HTTPException(404, "session_not_found") from exc
    except InvalidTurn as exc:
        raise HTTPException(422, str(exc)) from exc
    except AIProviderNotConfigured as exc:
        log.warning("analysis unavailable: provider not configured")
        raise HTTPException(503, "analysis_unavailable") from exc
    except AIProviderError as exc:
        raise HTTPException(502, "analysis_failed") from exc


@router.get("/media/{media_id}/content")
def media_content(
    media_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: SessionService = Depends(get_session_service),
):
    try:
        data, content_type = svc.read_media(user_id, media_id)
    except NotFound as exc:
        raise HTTPException(404, "media_not_found") from exc
    return Response(data, media_type=content_type, headers={"Cache-Control": "private, max-age=3600"})
