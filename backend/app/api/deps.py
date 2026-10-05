import uuid
from collections.abc import Iterator
from functools import lru_cache

from fastapi import Depends, Header, HTTPException
from sqlalchemy.orm import Session

from app.ai.registry import build_provider
from app.config import get_settings
from app.db.session import get_db
from app.media.storage import LocalMediaStorage, MediaStorage
from app.repositories.sessions import MediaRepository, SessionRepository, UserRepository
from app.services.diagnostic_service import DiagnosticService
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
        UserRepository(db), SessionRepository(db), MediaRepository(db), storage, diagnostics
    )
