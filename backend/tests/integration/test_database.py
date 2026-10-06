import pytest
from alembic import command
from fastapi.testclient import TestClient
from sqlalchemy import inspect

from tests.conftest import alembic_cfg

pytestmark = pytest.mark.integration


def test_migrations_upgrade_and_downgrade(engine):
    cfg = alembic_cfg()
    tables = set(inspect(engine).get_table_names())
    assert {"users", "diagnostic_sessions", "media_assets", "session_messages",
            "session_observations", "session_hypotheses", "session_actions",
            "session_verifications", "homes", "rooms", "equipment"} <= tables
    assert "equipment_id" in {c["name"] for c in inspect(engine).get_columns("diagnostic_sessions")}

    command.downgrade(cfg, "base")
    assert "users" not in set(inspect(engine).get_table_names())
    command.upgrade(cfg, "head")  # le schéma doit rester migré pour la suite


def test_media_defaults_to_private(engine):
    cols = {c["name"]: c for c in inspect(engine).get_columns("media_assets")}
    assert "visibility" in cols and "exif_stripped" in cols


def test_users_have_account_link_for_future(engine):
    assert "account_id" in {c["name"] for c in inspect(engine).get_columns("users")}


def test_health_endpoints(engine):
    from app.main import create_app

    client = TestClient(create_app())
    assert client.get("/health").json() == {"status": "ok"}
    assert client.get("/health/db").json()["database"] == "up"


def test_analyze_without_provider_is_unavailable_not_simulated():
    from app.main import create_app

    client = TestClient(create_app())
    r = client.post("/v1/diagnostic/analyze", json={"session_id": "s", "description": "robinet qui goutte"})
    assert r.status_code == 503


def test_analyze_dangerous_returns_stop_even_without_provider():
    from app.main import create_app

    client = TestClient(create_app())
    r = client.post("/v1/diagnostic/analyze", json={"session_id": "s", "description": "odeur de gaz"})
    assert r.status_code == 200
    body = r.json()
    assert body["next_action"]["type"] == "SAFETY_STOP"
    assert body["diy_allowed"] is False


def test_home_schema_supports_future_multi_home_but_one_default(engine):
    cols = {c["name"] for c in inspect(engine).get_columns("homes")}
    assert {"id", "user_id", "is_default", "created_at", "updated_at"} <= cols
    eq = {c["name"] for c in inspect(engine).get_columns("equipment")}
    assert {"home_id", "room_id", "equipment_type", "display_name", "brand", "model",
            "primary_media_id"} <= eq
    assert {"home_id", "name", "normalized_type"} <= {c["name"] for c in inspect(engine).get_columns("rooms")}
