import logging
import uuid

from fastapi import APIRouter, Depends

from app.api.deps import current_user_id, get_account_service
from app.services.account_service import AccountService

log = logging.getLogger("nalvium.account")
router = APIRouter(prefix="/v1/me", tags=["account"])


@router.delete("")
def delete_my_data(user_id: uuid.UUID = Depends(current_user_id), svc: AccountService = Depends(get_account_service)):
    """Supprime TOUTES les données rattachées à l'identité anonyme de l'installation (voir AccountService)."""
    return {"deleted": svc.delete_all(user_id)}


@router.get("/export")
def export_my_data(user_id: uuid.UUID = Depends(current_user_id), svc: AccountService = Depends(get_account_service)):
    """Export JSON des données de cette identité (accès aux données). Voir AccountService.export."""
    return svc.export(user_id)
