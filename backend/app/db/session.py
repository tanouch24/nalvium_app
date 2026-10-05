from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.config import get_settings


def make_engine(url: str | None = None):
    return create_engine(url or get_settings().database_url, pool_pre_ping=True)


_SessionLocal: sessionmaker[Session] | None = None


def get_db() -> Iterator[Session]:
    global _SessionLocal
    if _SessionLocal is None:
        _SessionLocal = sessionmaker(bind=make_engine(), expire_on_commit=False)
    with _SessionLocal() as session:
        yield session
