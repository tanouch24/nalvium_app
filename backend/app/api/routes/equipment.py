import logging
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, Response, UploadFile

from app.ai.provider import AIProviderError, AIProviderNotConfigured
from app.api.deps import current_user_id, get_equipment_service, get_manual_service
from app.api.schemas import (
    EquipmentCreate,
    EquipmentDetail,
    EquipmentDiagnostic,
    EquipmentSummary,
    EquipmentUpdate,
    HomeOut,
    IdentificationOut,
    IdentifyRequest,
    ManualPageOut,
    ManualSearchOut,
    MediaOut,
    RoomOut,
    equipment_summary,
    manual_out,
)
from app.config import get_settings
from app.media.pipeline import InvalidImageError, process_photo
from app.services.equipment_service import EquipmentInput, EquipmentService, InvalidEquipment
from app.services.manual_service import ManualService, ReferenceRequired
from app.services.session_service import NotFound

# Journaux : identifiants techniques uniquement (jamais marque, modèle, nom, pièce ni texte lu sur l'image).
log = logging.getLogger("nalvium.home")
router = APIRouter(prefix="/v1", tags=["home"])


def _detail(svc: EquipmentService, user_id: uuid.UUID, item, manuals: ManualService) -> EquipmentDetail:
    sessions = svc.diagnostics(user_id, item.id)
    base = equipment_summary(item, len(sessions))
    return EquipmentDetail(
        **base.model_dump(),
        diagnostics=[
            EquipmentDiagnostic(id=s.id, title=s.title, status=s.status, risk_level=s.risk_level,
                                updated_at=s.updated_at)
            for s in sessions
        ],
        manual=manual_out(manuals.get(user_id, item.id)),
    )


@router.get("/home", response_model=HomeOut)
def get_home(user_id: uuid.UUID = Depends(current_user_id), svc: EquipmentService = Depends(get_equipment_service)):
    """Crée la Maison par défaut au premier appel. Aucun appel IA."""
    view = svc.home(user_id)
    return HomeOut(
        id=view.home.id,
        rooms=[RoomOut(id=r.id, name=r.name, room_type=r.normalized_type) for r in view.rooms],
        equipment=[equipment_summary(row.equipment, row.diagnostics) for row in view.items],
    )


@router.get("/equipment", response_model=list[EquipmentSummary])
def list_equipment(
    user_id: uuid.UUID = Depends(current_user_id), svc: EquipmentService = Depends(get_equipment_service)
):
    return [equipment_summary(row.equipment, row.diagnostics) for row in svc.home(user_id).items]


@router.post("/equipment", response_model=EquipmentDetail, status_code=201)
def create_equipment(
    body: EquipmentCreate,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: EquipmentService = Depends(get_equipment_service),
    manuals: ManualService = Depends(get_manual_service),
):
    try:
        item = svc.create(user_id, EquipmentInput(**body.model_dump()))
    except InvalidEquipment as exc:
        raise HTTPException(422, str(exc)) from exc
    log.info("equipment created id=%s", item.id)
    return _detail(svc, user_id, item, manuals)


@router.post("/equipment/photo", response_model=MediaOut, status_code=201)
async def upload_equipment_photo(
    file: UploadFile = File(...),
    user_id: uuid.UUID = Depends(current_user_id),
    svc: EquipmentService = Depends(get_equipment_service),
):
    """Photo PRIVÉE d'équipement (EXIF/GPS retirés, redimensionnée, vignette). Aucune session, aucune IA."""
    limit = get_settings().max_upload_bytes
    raw = await file.read(limit + 1)
    if len(raw) > limit:
        raise HTTPException(413, "file_too_large")
    try:
        asset = svc.add_photo(user_id, process_photo(raw))
    except InvalidImageError as exc:
        raise HTTPException(422, "invalid_image") from exc
    log.info("equipment photo uploaded media=%s bytes_stored=%d private", asset.id, asset.size_bytes)
    return MediaOut(id=asset.id, width=asset.width, height=asset.height)


@router.delete("/equipment/photo/{media_id}", status_code=204)
def discard_equipment_photo(
    media_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: EquipmentService = Depends(get_equipment_service),
):
    """Abandon explicite d'une photo temporaire (ajout annulé) : supprimée tout de suite."""
    try:
        svc.discard_photo(user_id, media_id)
    except NotFound as exc:
        raise HTTPException(404, "media_not_found") from exc


@router.post("/equipment/identify", response_model=IdentificationOut)
async def identify_equipment(
    body: IdentifyRequest,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: EquipmentService = Depends(get_equipment_service),
):
    """Propose un type/une marque/un modèle. Ce n'est PAS un diagnostic : aucune session, aucun compteur."""
    try:
        result = await svc.identify(user_id, body.media_id)
    except NotFound as exc:
        raise HTTPException(404, "media_not_found") from exc
    except AIProviderNotConfigured as exc:
        raise HTTPException(503, "identification_unavailable") from exc
    except AIProviderError as exc:
        raise HTTPException(502, "identification_failed") from exc
    return IdentificationOut(**result.model_dump())


@router.get("/equipment/{equipment_id}", response_model=EquipmentDetail)
def get_equipment(
    equipment_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: EquipmentService = Depends(get_equipment_service),
    manuals: ManualService = Depends(get_manual_service),
):
    try:
        return _detail(svc, user_id, svc.get(user_id, equipment_id), manuals)
    except NotFound as exc:
        raise HTTPException(404, "equipment_not_found") from exc


@router.patch("/equipment/{equipment_id}", response_model=EquipmentDetail)
def update_equipment(
    equipment_id: uuid.UUID,
    body: EquipmentUpdate,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: EquipmentService = Depends(get_equipment_service),
    manuals: ManualService = Depends(get_manual_service),
):
    try:
        item = svc.update(user_id, equipment_id, body.model_dump(exclude_unset=True))
    except NotFound as exc:
        raise HTTPException(404, "equipment_not_found") from exc
    except InvalidEquipment as exc:
        raise HTTPException(422, str(exc)) from exc
    return _detail(svc, user_id, item, manuals)


@router.delete("/equipment/{equipment_id}", status_code=204)
def delete_equipment(
    equipment_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: EquipmentService = Depends(get_equipment_service),
):
    """Supprime l'équipement et sa photo. Les diagnostics liés sont conservés (détachés)."""
    try:
        svc.delete(user_id, equipment_id)
    except NotFound as exc:
        raise HTTPException(404, "equipment_not_found") from exc
    log.info("equipment deleted id=%s", equipment_id)


# ---- Notice constructeur ---------------------------------------------------------
@router.post("/equipment/{equipment_id}/manual/search", response_model=ManualSearchOut)
async def search_manual(
    equipment_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    manuals: ManualService = Depends(get_manual_service),
):
    """Cherche la notice OFFICIELLE (marque + référence uniquement). Ce n'est PAS un diagnostic : aucun compteur."""
    try:
        doc, outcome = await manuals.search(user_id, equipment_id)
    except NotFound as exc:
        raise HTTPException(404, "equipment_not_found") from exc
    except ReferenceRequired as exc:
        raise HTTPException(409, "reference_required") from exc
    log.info("manual search equipment=%s outcome=%s", equipment_id, outcome)
    return ManualSearchOut(outcome=outcome, manual=manual_out(doc))


@router.post("/equipment/{equipment_id}/manual/confirm", response_model=ManualSearchOut)
def confirm_manual(
    equipment_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    manuals: ManualService = Depends(get_manual_service),
):
    try:
        doc = manuals.confirm(user_id, equipment_id)
    except NotFound as exc:
        raise HTTPException(404, "manual_not_found") from exc
    return ManualSearchOut(outcome="found", manual=manual_out(doc))


@router.delete("/equipment/{equipment_id}/manual", status_code=204)
def delete_manual(
    equipment_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    manuals: ManualService = Depends(get_manual_service),
):
    try:
        manuals.remove(user_id, equipment_id)
    except NotFound as exc:
        raise HTTPException(404, "equipment_not_found") from exc


@router.get("/equipment/{equipment_id}/manual/pages/{page}", response_model=ManualPageOut)
def manual_page(
    equipment_id: uuid.UUID,
    page: int,
    user_id: uuid.UUID = Depends(current_user_id),
    manuals: ManualService = Depends(get_manual_service),
):
    """Texte extrait d'une page (consultation dans l'app). Privé : identité requise."""
    try:
        doc, text = manuals.page(user_id, equipment_id, page)
    except NotFound as exc:
        raise HTTPException(404, "manual_page_not_found") from exc
    return ManualPageOut(page=page, page_count=doc.page_count or 0, text=text)


@router.get("/equipment/{equipment_id}/manual/file")
def manual_file(
    equipment_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    manuals: ManualService = Depends(get_manual_service),
):
    """Le PDF original, PRIVÉ : jamais public, jamais sans l'identité du propriétaire."""
    try:
        data, _doc = manuals.file(user_id, equipment_id)
    except NotFound as exc:
        raise HTTPException(404, "manual_not_found") from exc
    return Response(data, media_type="application/pdf", headers={"Cache-Control": "private, no-store"})
