import os

# Doit précéder tout import de app.* : la config de test ne touche jamais la base de dev.
os.environ["NALVIUM_ENV"] = "test"
os.environ["NALVIUM_DATABASE_URL"] = (
    "postgresql+psycopg://nalvium:nalvium_dev@localhost:5433/nalvium_test"
)
# Les tests ne doivent jamais appeler OpenAI pour de vrai.
os.environ.pop("OPENAI_API_KEY", None)
os.environ.pop("NALVIUM_OPENAI_API_KEY", None)
os.environ["NALVIUM_AI_PROVIDER"] = "none"

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, text

from app.config import get_settings


def alembic_cfg() -> Config:
    cfg = Config("alembic.ini")
    cfg.set_main_option("sqlalchemy.url", get_settings().database_url)
    return cfg


@pytest.fixture(scope="session")
def engine():
    assert get_settings().env.value == "test"
    eng = create_engine(get_settings().database_url)
    with eng.begin() as c:
        c.execute(text("DROP SCHEMA public CASCADE; CREATE SCHEMA public;"))
    command.upgrade(alembic_cfg(), "head")
    yield eng
    eng.dispose()


@pytest.fixture
def clean_db(engine):
    """Vide les tables entre deux tests (le schéma reste migré)."""
    with engine.begin() as c:
        c.execute(
            text(
                "TRUNCATE session_verifications, session_actions, session_hypotheses, "
                "session_observations, session_messages, media_assets, diagnostic_sessions, users CASCADE"
            )
        )
    yield engine
