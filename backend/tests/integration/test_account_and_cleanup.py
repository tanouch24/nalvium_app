import logging
import os
from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text

from app.api.deps import get_ai_provider, get_diagnostic_service, get_request_notifier, get_storage
from app.community.rules import COMMUNITY_CONSENT_VERSION
from app.config import Settings
from app.domain.diagnosis import NextActionType as T
from app.main import create_app
from app.maintenance.cleanup import run_cleanup
from app.media.storage import LocalMediaStorage
from app.notifications.service_requests import NotifyResult
from app.service_requests.validation import CONSENT_VERSION
from app.services.diagnostic_service import DiagnosticService
from tests.helpers import ScriptedProvider, jpeg_bytes, make_analysis, new_install_id

pytestmark = pytest.mark.integration

PRIVATE = {"phone": "06 12 34 56 78", "email": "secret@example.fr", "city": "Lyon", "postal_code": "69003"}


class FakeNotifier:
    configured = True

    def notify(self, text_):
        return NotifyResult("sent")


class Env:
    def __init__(self, client, storage, engine):
        self.client, self.storage, self.engine = client, storage, engine

    def h(self):
        return {"X-Nalvium-Install-Id": new_install_id()}

    def populate(self, headers, tag):
        """Un jeu de données COMPLET pour un utilisateur."""
        c = self.client
        sid = c.post("/v1/sessions", headers=headers).json()["id"]
        photo = c.post(f"/v1/sessions/{sid}/media", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=headers).json()["id"]
        c.post(f"/v1/sessions/{sid}/turn", json={"kind": "description", "text": f"fuite {tag}"}, headers=headers)
        eq = c.post("/v1/equipment", json={"equipment_type": "oven", "brand": f"Marque{tag}", "model": "ABC123", "room_type": "kitchen"}, headers=headers).json()["id"]
        eq_photo = c.post("/v1/equipment/photo", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=headers).json()["id"]
        c.patch(f"/v1/equipment/{eq}", json={"primary_media_id": eq_photo}, headers=headers)
        rid = c.post(f"/v1/sessions/{sid}/service-request", headers=headers).json()["id"]
        c.patch(f"/v1/service-requests/{rid}", json={"first_name": f"Prenom{tag}", "availability_type": "asap", **PRIVATE}, headers=headers)
        c.put(f"/v1/service-requests/{rid}/media", json={"media_ids": [photo]}, headers=headers)
        assert c.post(f"/v1/service-requests/{rid}/submit", json={"consent": True, "consent_version": CONSENT_VERSION}, headers=headers).status_code == 200
        pub = c.post("/v1/community/media", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=headers).json()["id"]
        post = c.post("/v1/community/posts", json={"title": f"Titre {tag}", "solution": "Solution suffisamment longue.", "media_id": pub, "consent_public": True, "consent_version": COMMUNITY_CONSENT_VERSION}, headers=headers).json()["id"]
        return {"sid": sid, "photo": photo, "eq": eq, "rid": rid, "post": post, "pub": pub}

    def files(self):
        return {k for k, _ in self.storage.iter_keys()}


@pytest.fixture
def env(clean_db, tmp_path, engine):
    provider = ScriptedProvider(*[make_analysis(T.ASK_QUESTION, "Q ?") for _ in range(4)])
    app = create_app()
    storage = LocalMediaStorage(tmp_path)
    app.dependency_overrides[get_diagnostic_service] = lambda: DiagnosticService(provider)
    app.dependency_overrides[get_ai_provider] = lambda: provider
    app.dependency_overrides[get_storage] = lambda: storage
    app.dependency_overrides[get_request_notifier] = lambda: FakeNotifier()
    return Env(TestClient(app), storage, engine)


def count(engine, table):
    with engine.connect() as c:
        return c.execute(text(f"SELECT count(*) FROM {table}")).scalar()


ALL_TABLES = ["diagnostic_sessions", "session_messages", "media_assets", "homes", "rooms", "equipment", "service_requests",
              "service_request_media", "community_posts", "community_media", "community_helpful", "community_saves",
              "community_comments", "community_reports", "users"]


def test_delete_all_removes_user_a_and_leaves_user_b_intact(env, engine):
    a, b = env.h(), env.h()
    da, db_ = env.populate(a, "A"), env.populate(b, "B")
    # interactions croisées : A aime/enregistre/commente/signale le post de B ; B interagit avec le post de A
    c = env.client
    c.put(f"/v1/community/posts/{db_['post']}/helpful", headers=a)
    c.put(f"/v1/community/posts/{db_['post']}/save", headers=a)
    c.post(f"/v1/community/posts/{db_['post']}/comments", json={"body": "Commentaire de A"}, headers=a)
    c.post(f"/v1/community/posts/{db_['post']}/report", json={"reason": "spam"}, headers=a)
    c.post(f"/v1/community/posts/{da['post']}/comments", json={"body": "Commentaire de B sous le post de A"}, headers=b)
    c.put(f"/v1/community/posts/{da['post']}/helpful", headers=b)
    files_before = env.files()

    r = c.delete("/v1/me", headers=a)
    assert r.status_code == 200 and r.json()["deleted"]["diagnostics"] == 1 and r.json()["deleted"]["files"] >= 5

    # A : plus rien, y compris avec la même identité
    assert c.get("/v1/sessions", headers=a).json() == []
    assert c.get("/v1/home", headers=a).json()["equipment"] == []
    assert c.get("/v1/service-requests", headers=a).json() == []
    assert c.get("/v1/community/saved", headers=a).json()["items"] == []
    assert c.get(f"/v1/sessions/{da['sid']}", headers=a).status_code == 404
    assert c.get(f"/v1/community/posts/{da['post']}", headers=b).status_code == 404  # sa publication a disparu
    assert c.get(f"/v1/media/{da['photo']}/content", headers=a).status_code == 404
    new_identity = env.h()  # nouvelle identité : aucun ancien contenu
    assert c.get("/v1/sessions", headers=new_identity).json() == [] and c.get("/v1/home", headers=new_identity).json()["equipment"] == []
    # fichiers de A effacés, ceux de B conservés et lisibles
    assert len(env.files()) < len(files_before) and len(env.files()) >= 5
    assert c.get(f"/v1/media/{db_['photo']}/content", headers=b).status_code == 200
    assert c.get(f"/v1/community/media/{db_['pub']}/thumb").status_code == 200
    # B : intact (sauf le commentaire de A et ses interactions, supprimés avec A)
    assert count(engine, "diagnostic_sessions") == 1 and count(engine, "equipment") == 1 and count(engine, "community_posts") == 1
    post_b = c.get(f"/v1/community/posts/{db_['post']}", headers=b).json()
    assert post_b["helpful_count"] == 0 and post_b["comment_count"] == 0 and post_b["title"] == "Titre B"
    assert c.get("/v1/service-requests", headers=b).json()[0]["first_name"] == "PrenomB"
    assert count(engine, "community_reports") == 0  # signalements faits par A supprimés
    # aucune référence cassée : tous les fichiers référencés existent encore
    with engine.connect() as conn:
        refs = {k for (k,) in conn.execute(text("SELECT storage_key FROM media_assets UNION SELECT thumb_key FROM media_assets WHERE thumb_key IS NOT NULL UNION SELECT storage_key FROM community_media UNION SELECT thumb_key FROM community_media"))}
    assert refs <= env.files()


def test_delete_is_idempotent_and_total(env, engine):
    a = env.h()
    env.populate(a, "A")
    assert env.client.delete("/v1/me", headers=a).status_code == 200
    again = env.client.delete("/v1/me", headers=a)
    assert again.status_code == 200 and again.json()["deleted"]["files"] == 0
    for t in ALL_TABLES:
        assert count(engine, t) == 0, t
    assert env.files() == set()
    assert env.client.delete("/v1/me").status_code == 401


def test_delete_with_logs_leaks_nothing(env, caplog):
    caplog.set_level(logging.DEBUG)
    a = env.h()
    env.populate(a, "A")
    env.client.delete("/v1/me", headers=a)
    for secret in ("secret@example.fr", "06 12 34", "+33612345678", "PrenomA", "MarqueA", a["X-Nalvium-Install-Id"]):
        assert secret not in caplog.text, secret


def test_export_contains_own_data_only_and_no_internal_fields(env):
    a, b = env.h(), env.h()
    env.populate(a, "A")
    env.populate(b, "B")
    data = env.client.get("/v1/me/export", headers=a).json()
    flat = str(data)
    assert data["export_version"] == 1 and data["diagnostics"][0]["description"] == "fuite A"
    assert data["service_requests"][0]["phone"] == "+33612345678" and data["home"][0]["equipment"][0]["brand"] == "MarqueA"
    assert data["community"]["posts"][0]["title"] == "Titre A"
    for forbidden in ("PrenomB", "MarqueB", "Titre B", "storage_key", "storage", "var/", "prompt", "reasoning", "token", "api_key", "OPENAI", "install_id"):
        assert forbidden.lower() not in flat.lower(), forbidden
    assert a["X-Nalvium-Install-Id"] not in flat
    assert env.client.get("/v1/me/export").status_code == 401


# ---- cleanup ----------------------------------------------------------------------------------------
def age(engine, table, column, id_col, ident, hours):
    with engine.begin() as c:
        c.execute(text(f"UPDATE {table} SET {column} = now() - make_interval(hours => :h) WHERE {id_col} = :i"), {"h": hours, "i": ident})


def test_cleanup_old_drafts_removed_recent_kept_and_submitted_never_touched(env, engine, tmp_path):
    a = env.h()
    old = env.client.post("/v1/service-requests", json={"problem_summary": "ancien"}, headers=a).json()["id"]
    recent = env.client.post("/v1/service-requests", json={"problem_summary": "récent"}, headers=a).json()["id"]
    d = env.populate(a, "A")  # contient une demande SUBMITTED
    age(engine, "service_requests", "updated_at", "id", old, 24 * 30)
    age(engine, "service_requests", "updated_at", "id", d["rid"], 24 * 30)  # ancienne mais SUBMITTED
    from sqlalchemy.orm import Session

    with Session(engine) as db:
        rep = run_cleanup(db, env.storage, Settings())
    assert rep.draft_requests == 1
    with engine.connect() as c:
        rows = {str(i): s for i, s in c.execute(text("SELECT id, status FROM service_requests"))}
    assert old not in rows and recent in rows and rows[d["rid"]] == "SUBMITTED"


def test_cleanup_temp_photos_orphans_and_community_drafts_without_touching_referenced_media(env, engine):
    a = env.h()
    d = env.populate(a, "A")
    temp_old = env.client.post("/v1/equipment/photo", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=a).json()["id"]
    temp_new = env.client.post("/v1/equipment/photo", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=a).json()["id"]
    draft_old = env.client.post("/v1/community/media", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=a).json()["id"]
    draft_new = env.client.post("/v1/community/media", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=a).json()["id"]
    age(engine, "media_assets", "created_at", "id", temp_old, 24 * 5)
    age(engine, "community_media", "created_at", "id", draft_old, 72)
    for ident in (d["photo"], d["pub"]):  # médias RÉFÉRENCÉS mais anciens
        age(engine, "media_assets", "created_at", "id", ident, 24 * 90) if ident == d["photo"] else age(engine, "community_media", "created_at", "id", ident, 24 * 90)
    # photo d'équipement principale ancienne : référencée par l'équipement
    with engine.connect() as c:
        eq_photo = c.execute(text("SELECT primary_media_id FROM equipment")).scalar()
    age(engine, "media_assets", "created_at", "id", str(eq_photo), 24 * 90)
    # fichier orphelin ancien / récent
    old_file = env.storage._path("ghost/old.bin")
    old_file.parent.mkdir(parents=True, exist_ok=True)
    old_file.write_bytes(b"x")
    os.utime(old_file, (1, 1))
    new_file = env.storage._path("ghost/new.bin")
    new_file.write_bytes(b"x")
    from sqlalchemy.orm import Session

    with Session(engine) as db:
        rep = run_cleanup(db, env.storage, Settings())
    assert (rep.temp_photos, rep.community_drafts, rep.orphan_files) == (1, 1, 1)
    with engine.connect() as c:
        media = {str(i) for (i,) in c.execute(text("SELECT id FROM media_assets"))}
        cm = {str(i) for (i,) in c.execute(text("SELECT id FROM community_media"))}
    assert temp_old not in media and temp_new in media and d["photo"] in media and str(eq_photo) in media
    assert draft_old not in cm and draft_new in cm and d["pub"] in cm
    assert not old_file.exists() and new_file.exists()
    # tous les fichiers référencés existent encore
    assert env.client.get(f"/v1/media/{d['photo']}/content", headers=a).status_code == 200
    assert env.client.get(f"/v1/community/media/{d['pub']}/large").status_code == 200
    assert env.client.get(f"/v1/media/{eq_photo}/content", headers=a).status_code == 200


def test_cleanup_is_idempotent_bounded_and_does_not_touch_diagnostics(env, engine):
    a = env.h()
    d = env.populate(a, "A")
    from sqlalchemy.orm import Session

    for _ in range(5):
        env.client.post("/v1/service-requests", json={"problem_summary": "ancien"}, headers=a)
    with engine.begin() as c:
        c.execute(text("UPDATE service_requests SET updated_at = now() - interval '60 days' WHERE status='DRAFT'"))
        c.execute(text("UPDATE diagnostic_sessions SET updated_at = now() - interval '400 days', created_at = now() - interval '400 days'"))
    with Session(engine) as db:
        first = run_cleanup(db, env.storage, Settings(cleanup_batch_limit=3))
    assert first.draft_requests == 3 and "draft_requests" in first.capped  # borné
    with Session(engine) as db:
        second = run_cleanup(db, env.storage, Settings(cleanup_batch_limit=3))
        third = run_cleanup(db, env.storage, Settings(cleanup_batch_limit=3))
    assert second.draft_requests == 2 and third.draft_requests == 0 and third.errors == 0  # relançable sans erreur
    assert count(engine, "diagnostic_sessions") == 1  # un vieux diagnostic n'est JAMAIS supprimé par le nettoyage
    assert env.client.get(f"/v1/sessions/{d['sid']}", headers=a).status_code == 200


def test_cleanup_logs_counts_only(env, engine, caplog):
    caplog.set_level(logging.DEBUG)
    a = env.h()
    env.populate(a, "A")
    from sqlalchemy.orm import Session

    with Session(engine) as db:
        run_cleanup(db, env.storage, Settings(), now=datetime.now(UTC) + timedelta(days=60))
    assert "cleanup drafts=" in caplog.text
    for secret in ("PrenomA", "MarqueA", "secret@example.fr", a["X-Nalvium-Install-Id"]):
        assert secret not in caplog.text
