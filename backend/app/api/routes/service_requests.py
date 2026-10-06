import logging
import uuid

from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import current_user_id, get_service_area_policy, get_service_request_service
from app.api.schemas import (
    ServiceAreaCheckIn,
    ServiceAreaCheckOut,
    ServiceAreaInfo,
    ServiceRequestCreate,
    ServiceRequestMediaSelection,
    ServiceRequestOut,
    ServiceRequestSubmit,
    ServiceRequestUpdate,
    service_request_out,
)
from app.service_area.policy import AreaError, ServiceAreaPolicy
from app.service_requests.validation import CONSENT_VERSION, InvalidField
from app.services.service_request_service import InvalidState, ServiceRequestService
from app.services.session_service import NotFound

# Journaux : identifiants techniques et statut uniquement (jamais nom, téléphone, texte du problème).
log = logging.getLogger("nalvium.requests")
router = APIRouter(prefix="/v1", tags=["service-requests"])


def _out(svc: ServiceRequestService, user_id: uuid.UUID, req) -> ServiceRequestOut:
    return service_request_out(req, svc.context(user_id, req))


def _guard(call):
    try:
        return call()
    except NotFound as exc:
        raise HTTPException(404, "request_not_found") from exc
    except InvalidField as exc:
        raise HTTPException(422, exc.code) from exc
    except InvalidState as exc:
        raise HTTPException(409, exc.code) from exc


@router.get("/service-area", response_model=ServiceAreaInfo)
def service_area(policy: ServiceAreaPolicy = Depends(get_service_area_policy)):
    """Zone où les interventions humaines sont disponibles (info d'affichage). Nalvium reste utilisable partout."""
    a = policy.areas[0]
    return ServiceAreaInfo(name=a.name, radius_km=round(a.radius_km))


@router.post("/service-area/check", response_model=ServiceAreaCheckOut)
def check_service_area(
    body: ServiceAreaCheckIn,
    user_id: uuid.UUID = Depends(current_user_id),
    policy: ServiceAreaPolicy = Depends(get_service_area_policy),
):
    """Éligibilité rapide (ville + code postal) pour le parcours. Informatif : le contrôle définitif est refait à
    l'envoi. Rien n'est stocké, aucune coordonnée d'utilisateur n'existe."""
    try:
        d = policy.evaluate(body.city, body.postal_code)
    except AreaError as exc:
        return ServiceAreaCheckOut(status="invalid", code=exc.code)
    return ServiceAreaCheckOut(status="in_zone" if d.in_zone else "out_of_zone")


@router.get("/service-requests/consent-version")
def consent_version():
    return {"consent_version": CONSENT_VERSION}


@router.post("/service-requests", response_model=ServiceRequestOut, status_code=201)
def create_request(
    body: ServiceRequestCreate,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: ServiceRequestService = Depends(get_service_request_service),
):
    req = _guard(lambda: svc.create(
        user_id, session_id=body.session_id, equipment_id=body.equipment_id,
        summary=body.problem_summary, category=body.category,
    ))
    log.info("service request draft id=%s from_session=%s", req.id, req.diagnostic_session_id is not None)
    return _out(svc, user_id, req)


@router.post("/sessions/{session_id}/service-request", response_model=ServiceRequestOut)
def request_from_session(
    session_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: ServiceRequestService = Depends(get_service_request_service),
):
    """« Demander de l'aide » depuis un diagnostic : reprend le brouillon existant ou le prépare avec le contexte."""
    req = _guard(lambda: svc.create(user_id, session_id=session_id))
    return _out(svc, user_id, req)


@router.get("/service-requests", response_model=list[ServiceRequestOut])
def list_requests(
    user_id: uuid.UUID = Depends(current_user_id),
    svc: ServiceRequestService = Depends(get_service_request_service),
):
    return [service_request_out(r, {"equipment": (svc.context(user_id, r) or {}).get("equipment")}) for r in svc.list(user_id)]


@router.get("/service-requests/{request_id}", response_model=ServiceRequestOut)
def get_request(
    request_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: ServiceRequestService = Depends(get_service_request_service),
):
    return _out(svc, user_id, _guard(lambda: svc.get(user_id, request_id)))


@router.patch("/service-requests/{request_id}", response_model=ServiceRequestOut)
def update_request(
    request_id: uuid.UUID,
    body: ServiceRequestUpdate,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: ServiceRequestService = Depends(get_service_request_service),
):
    return _out(svc, user_id, _guard(lambda: svc.update(user_id, request_id, body.model_dump(exclude_unset=True))))


@router.put("/service-requests/{request_id}/media", response_model=ServiceRequestOut)
def select_media(
    request_id: uuid.UUID,
    body: ServiceRequestMediaSelection,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: ServiceRequestService = Depends(get_service_request_service),
):
    """Remplace la sélection : seuls ces médias seront joints. Rien n'est joint automatiquement."""
    return _out(svc, user_id, _guard(lambda: svc.select_media(user_id, request_id, body.media_ids)))


@router.post("/service-requests/{request_id}/submit", response_model=ServiceRequestOut)
def submit_request(
    request_id: uuid.UUID,
    body: ServiceRequestSubmit,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: ServiceRequestService = Depends(get_service_request_service),
):
    req = _guard(lambda: svc.submit(user_id, request_id, consent=body.consent, consent_version=body.consent_version))
    log.info("service request submitted id=%s media=%d", req.id, len(req.media))
    return _out(svc, user_id, req)


@router.post("/service-requests/{request_id}/cancel", response_model=ServiceRequestOut)
def cancel_request(
    request_id: uuid.UUID,
    user_id: uuid.UUID = Depends(current_user_id),
    svc: ServiceRequestService = Depends(get_service_request_service),
):
    req = _guard(lambda: svc.cancel(user_id, request_id))
    log.info("service request cancelled id=%s", req.id)
    return _out(svc, user_id, req)
