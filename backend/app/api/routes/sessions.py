import logging
import time
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, Response, UploadFile
from fastapi.concurrency import run_in_threadpool

from app.ai.provider import AIProviderError, AIProviderNotConfigured
from app.api.deps import current_user_id, get_equipment_service, get_session_service
from app.api.ratelimit import rate_limit
from app.api.schemas import (
    CreateSessionRequest,
    EquipmentSuggestionsOut,
    LinkEquipmentRequest,
    MediaOut,
    SessionOut,
    SessionSummary,
    TurnRequest,
    equipment_summary,
    session_out,
    summary_out,
)
from app.config import get_settings
from app.media.pipeline import InvalidImageError, process_photo
from app.media.video import InvalidVideoError, VideoTooLongError, process_video
from app.services.equipment_service import EquipmentService
from app.services.session_service import InvalidTurn, NotFound, SessionService, TurnInput

log = logging.getLogger("nalvium.api")
router = APIRouter(prefix="/v1", tags=["sessions"])


@router.post("/sessions", response_model=SessionOut, status_code=201)
def create_session(
    body: CreateSessionRequest | None = None,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: SessionService = Depends(get_session_service),
):
    """Corps facultatif : `equipment_id` lie le diagnostic à un équipement de la Maison dès la création."""
    try:
        session = svc.create(user_id, body.equipment_id if body else None)
    except NotFound as exc:
        raise HTTPException(404, "equipment_not_found") from exc
    log.info("session created id=%s linked=%s", session.id, session.equipment_id is not None)
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


@router.post("/sessions/{session_id}/equipment", response_model=SessionOut)
def link_equipment(
    session_id: uuid.UUID,
    body: LinkEquipmentRequest,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: SessionService = Depends(get_session_service),
):
    """Rattache un diagnostic existant à un équipement (null = détacher). L'app ne l'appelle qu'après
    confirmation explicite de l'utilisateur : Nalvium ne lie jamais sur une simple supposition."""
    try:
        session = svc.link_equipment(user_id, session_id, body.equipment_id)
    except NotFound as exc:
        raise HTTPException(404, "session_or_equipment_not_found") from exc
    log.info("session %s linked=%s", session_id, session.equipment_id is not None)
    return session_out(session)


@router.get("/sessions/{session_id}/equipment/suggestions", response_model=EquipmentSuggestionsOut)
def equipment_suggestions(
    session_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: SessionService = Depends(get_session_service),
    equipment: EquipmentService = Depends(get_equipment_service),
):
    """Propositions seulement (type probable + équipements du même type) : rien n'est lié ici."""
    try:
        session = svc.get(user_id, session_id)
    except NotFound as exc:
        raise HTTPException(404, "session_not_found") from exc
    found = equipment.suggestions(user_id, session)
    return EquipmentSuggestionsOut(
        detected_type=found.detected_type, matches=[equipment_summary(e) for e in found.matches]
    )


@router.post("/sessions/{session_id}/media", response_model=MediaOut, status_code=201, dependencies=[Depends(rate_limit("upload", 60, 600))])
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


@router.post("/sessions/{session_id}/video", response_model=MediaOut, status_code=201, dependencies=[Depends(rate_limit("upload", 60, 600))])
async def upload_video(
    session_id: uuid.UUID,
    file: UploadFile = File(...),
    user_id: uuid.UUID = Depends(current_user_id),
    svc: SessionService = Depends(get_session_service),
):
    """Vidéo courte (≤ 15 s) : validée, normalisée, nettoyée de ses métadonnées, stockée en PRIVÉ.
    Le contenu n'est jamais loggé : seules des métadonnées techniques (durée, taille) le sont."""
    settings = get_settings()
    raw = await file.read(settings.max_video_bytes + 1)
    if len(raw) > settings.max_video_bytes:
        raise HTTPException(413, "file_too_large")
    started = time.monotonic()
    try:
        svc.get(user_id, session_id)  # propriétaire et session valides AVANT tout traitement coûteux
        video = await run_in_threadpool(
            process_video, raw, max_seconds=settings.max_video_seconds, max_frames=settings.video_frames_max
        )
        asset = svc.add_video(user_id, session_id, video)
    except VideoTooLongError as exc:
        raise HTTPException(422, "video_too_long") from exc
    except InvalidVideoError as exc:
        raise HTTPException(422, "invalid_video") from exc
    except NotFound as exc:
        raise HTTPException(404, "session_not_found") from exc
    except InvalidTurn as exc:
        raise HTTPException(409, str(exc)) from exc
    log.info(
        "video uploaded session=%s bytes_in=%d bytes_stored=%d duration=%.1fs size=%dx%d audio=%s frames=%d "
        "processing=%.1fs private",
        session_id, len(raw), asset.size_bytes, asset.duration_s or 0, asset.width or 0, asset.height or 0,
        asset.has_audio, len(video.frames), time.monotonic() - started,
    )
    return MediaOut(
        id=asset.id, width=asset.width, height=asset.height, media_type="video",
        duration_s=asset.duration_s, has_audio=asset.has_audio,
    )


@router.post("/sessions/{session_id}/turn", response_model=SessionOut, dependencies=[Depends(rate_limit("analysis", 60, 600))])
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


@router.get("/media/{media_id}/thumbnail")
def media_thumbnail(
    media_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: SessionService = Depends(get_session_service),
):
    """Image d'aperçu (photo, ou image représentative d'une vidéo). Toujours PRIVÉE : identité requise."""
    try:
        data, content_type = svc.read_thumbnail(user_id, media_id)
    except NotFound as exc:
        raise HTTPException(404, "media_not_found") from exc
    return Response(data, media_type=content_type, headers={"Cache-Control": "private, max-age=3600"})
