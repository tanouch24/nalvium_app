import uuid
from collections.abc import Iterator
from functools import lru_cache

from fastapi import Depends, Header, HTTPException
from sqlalchemy.orm import Session

from app.ai.provider import AIProvider
from app.ai.registry import build_provider
from app.config import get_settings
from app.db.session import get_db
from app.manuals.fetcher import HttpxPdfFetcher, PdfFetcher
from app.media.storage import LocalMediaStorage, MediaStorage
from app.repositories.documents import DocumentRepository
from app.repositories.equipment import EquipmentRepository, HomeRepository
from app.repositories.sessions import MediaRepository, SessionRepository, UserRepository
from app.services.diagnostic_service import DiagnosticService
from app.services.equipment_service import EquipmentService
from app.services.manual_service import ManualRetriever, ManualService
from app.services.session_service import SessionService


def current_user_id(x_nalvium_install_id: str | None = Header(default=None)) -> uuid.UUID:
    """Identité anonyme par installation : un UUID aléatoire généré par l'app.
    Ce n'est pas une authentification (V1) ; il est prévu pour être rattaché plus tard à un compte."""
    if not x_nalvium_install_id:
        raise HTTPException(status_code=401, detail="missing_install_id")
    try:
        return uuid.UUID(x_nalvium_install_id)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail="invalid_install_id") from exc


@lru_cache
def _storage() -> MediaStorage:
    return LocalMediaStorage(get_settings().media_root)


def get_storage() -> MediaStorage:
    return _storage()


def get_diagnostic_service() -> DiagnosticService:
    return DiagnosticService(build_provider(get_settings()))


def get_session_service(
    db: Session = Depends(get_db),
    storage: MediaStorage = Depends(get_storage),
    diagnostics: DiagnosticService = Depends(get_diagnostic_service),
) -> Iterator[SessionService]:
    yield SessionService(
        UserRepository(db), SessionRepository(db), MediaRepository(db), storage, diagnostics,
        EquipmentRepository(db), ManualRetriever(DocumentRepository(db)),
    )


def get_ai_provider() -> AIProvider:
    return build_provider(get_settings())


def get_equipment_service(
    db: Session = Depends(get_db),
    storage: MediaStorage = Depends(get_storage),
    provider: AIProvider = Depends(get_ai_provider),
) -> Iterator[EquipmentService]:
    yield EquipmentService(
        UserRepository(db), HomeRepository(db), EquipmentRepository(db), MediaRepository(db), storage, provider,
        DocumentRepository(db),
    )


def get_pdf_fetcher() -> PdfFetcher:
    return HttpxPdfFetcher()


def get_manual_service(
    db: Session = Depends(get_db),
    storage: MediaStorage = Depends(get_storage),
    provider: AIProvider = Depends(get_ai_provider),
    fetcher: PdfFetcher = Depends(get_pdf_fetcher),
) -> Iterator[ManualService]:
    yield ManualService(EquipmentRepository(db), DocumentRepository(db), storage, provider, fetcher)
