import logging

import pytest
from fastapi.testclient import TestClient

from app.api import ratelimit
from app.api.deps import get_ai_provider, get_diagnostic_service, get_storage
from app.community.rules import COMMUNITY_CONSENT_VERSION
from app.config import Settings, get_settings
from app.main import create_app
from app.media.storage import LocalMediaStorage
from app.services.diagnostic_service import DiagnosticService
from tests.helpers import ScriptedProvider, new_install_id

pytestmark = pytest.mark.integration


@pytest.fixture
def client(clean_db, tmp_path):
    app = create_app()
    app.dependency_overrides[get_storage] = lambda: LocalMediaStorage(tmp_path)
    app.dependency_overrides[get_ai_provider] = lambda: ScriptedProvider()
    app.dependency_overrides[get_diagnostic_service] = lambda: DiagnosticService(ScriptedProvider())
    return TestClient(app, raise_server_exceptions=False), {"X-Nalvium-Install-Id": new_install_id()}


def post_body(i):
    return {"title": f"Solution numéro {i}", "solution": "Une solution suffisamment longue.", "consent_public": True, "consent_version": COMMUNITY_CONSENT_VERSION}


def test_normal_use_is_never_limited_but_abuse_is(client):
    c, h = client
    for i in range(20):  # plafond horaire de publication = 20
        assert c.post("/v1/community/posts", json=post_body(i), headers=h).status_code == 201
    r = c.post("/v1/community/posts", json=post_body(99), headers=h)
    assert r.status_code == 429 and r.json()["detail"] == "rate_limited" and "retry-after" in r.headers
    other = {"X-Nalvium-Install-Id": new_install_id()}  # un autre utilisateur n'est pas affecté
    assert c.post("/v1/community/posts", json=post_body(1), headers=other).status_code == 201
    assert c.get("/v1/community/posts", headers=h).status_code == 200  # la lecture n'est pas limitée


def test_comments_reports_and_requests_have_limits(client):
    c, h = client
    pid = c.post("/v1/community/posts", json=post_body(1), headers=h).json()["id"]
    codes = [c.post(f"/v1/community/posts/{pid}/comments", json={"body": f"Commentaire {i}"}, headers=h).status_code for i in range(62)]
    assert codes[:60] == [201] * 60 and 429 in codes[60:]
    sr = [c.post("/v1/service-requests", json={"problem_summary": "x"}, headers=h).status_code for _ in range(32)]
    assert sr[:30] == [201] * 30 and sr[30] == 429


def test_rate_limit_can_be_disabled_by_configuration(client, monkeypatch):
    c, h = client
    monkeypatch.setattr(get_settings(), "rate_limit_enabled", False)
    assert all(c.post("/v1/community/posts", json=post_body(i), headers=h).status_code == 201 for i in range(22))
    ratelimit.reset()


def test_unexpected_errors_never_leak_internals(client, caplog, monkeypatch):
    c, h = client
    caplog.set_level(logging.DEBUG)
    import app.services.community_service as svc

    def boom(*a, **k):
        raise RuntimeError("SELECT * FROM users WHERE token='sk-secret-key' /srv/private/path.py")

    monkeypatch.setattr(svc.CommunityService, "feed", boom)
    r = c.get("/v1/community/posts", headers=h)
    assert r.status_code == 500 and r.json() == {"detail": "internal_error"}
    for leak in ("SELECT", "sk-secret-key", "/srv/private", "Traceback", "RuntimeError: "):
        assert leak not in r.text
    assert "sk-secret-key" not in caplog.text and "unhandled error type=RuntimeError" in caplog.text


def test_security_headers_and_homogeneous_errors(client):
    c, h = client
    r = c.get("/health")
    assert r.headers["x-content-type-options"] == "nosniff" and r.headers["referrer-policy"] == "no-referrer"
    assert c.get("/v1/sessions").status_code == 401  # identité requise
    assert c.get("/v1/community/posts/not-a-uuid", headers=h).status_code == 422
    assert c.get("/v1/does-not-exist", headers=h).status_code == 404


def test_production_exposes_no_docs_or_schema_and_no_cors():
    import app.config as cfg

    cfg.get_settings.cache_clear()
    prod = Settings(
        env="production", database_url="postgresql+psycopg://u:p@db/prod", media_root="/data/media", ai_provider="none"
    )
    assert prod.is_production
    orig = cfg.get_settings
    cfg.get_settings = lambda: prod
    try:
        from app import main

        main.get_settings = lambda: prod
        app = main.create_app()
    finally:
        cfg.get_settings = orig
        main.get_settings = orig
        orig.cache_clear()
    assert app.docs_url is None and app.openapi_url is None and app.redoc_url is None
    assert not any(m.cls.__name__ == "CORSMiddleware" for m in app.user_middleware)  # pas de CORS : app mobile


def test_production_refuses_dev_database_credentials():
    with pytest.raises(RuntimeError):
        Settings(env="production").validate_for_runtime()


def test_no_debug_routes_are_exposed():
    paths = create_app().openapi()["paths"]
    assert paths and not any(w in p for p in paths for w in ("debug", "test", "admin", "internal"))


def test_database_url_hebergeur_est_complete_pour_psycopg(monkeypatch):
    from app.config import Settings

    monkeypatch.delenv("NALVIUM_DATABASE_URL", raising=False)
    monkeypatch.setenv("DATABASE_URL", "postgresql://u:p@db.example:5432/nalvium")
    assert Settings().database_url == "postgresql+psycopg://u:p@db.example:5432/nalvium"
    assert Settings(database_url="postgres://u:p@h/n").database_url == "postgresql+psycopg://u:p@h/n"
    kept = "postgresql+psycopg://u:p@h/n"
    assert Settings(database_url=kept).database_url == kept


def test_production_refuse_media_ephemeres_et_ia_sans_cle():
    import pytest

    from app.config import Settings

    good = {"env": "production", "database_url": "postgresql://u:p@h/n", "ai_provider": "none"}
    Settings(**good, media_root="/data/media").validate_for_runtime()
    with pytest.raises(RuntimeError, match="MEDIA_ROOT"):
        Settings(**good, media_root="./var/media").validate_for_runtime()
    with pytest.raises(RuntimeError, match="OPENAI_API_KEY"):
        Settings(**{**good, "ai_provider": "openai"}, openai_api_key=None, media_root="/data/media").validate_for_runtime()
    Settings(**{**good, "ai_provider": "openai"}, openai_api_key="x", media_root="/data/media").validate_for_runtime()
