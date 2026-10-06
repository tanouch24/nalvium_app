import logging

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text

from app.api.deps import get_ai_provider, get_diagnostic_service, get_request_notifier, get_storage
from app.domain.diagnosis import NextActionType as T
from app.domain.diagnosis import RiskLevel
from app.main import create_app
from app.media.storage import LocalMediaStorage
from app.notifications.service_requests import NotifyResult
from app.service_requests.validation import CONSENT_VERSION
from app.services.diagnostic_service import DiagnosticService
from tests.helpers import ScriptedProvider, make_analysis, new_install_id

pytestmark = pytest.mark.integration

BASE = {"first_name": "Camille", "phone": "06 12 34 56 78", "availability_type": "asap"}
IN_ZONE = {**BASE, "city": "Villeurbanne", "postal_code": "69100"}
OUT_OF_ZONE = {**BASE, "city": "Grenoble", "postal_code": "38000"}


class FakeNotifier:
    configured = True

    def __init__(self):
        self.messages = []

    def notify(self, text_):
        self.messages.append(text_)
        return NotifyResult("sent")


class Env:
    def __init__(self, client, provider, notifier, headers):
        self.client, self.provider, self.notifier, self.headers = client, provider, notifier, headers

    def draft(self, **body):
        return self.client.post("/v1/service-requests", json={"problem_summary": "Fuite sous mon évier", **body}, headers=self.headers).json()["id"]

    def patch(self, rid, **body):
        return self.client.patch(f"/v1/service-requests/{rid}", json=body, headers=self.headers)

    def submit(self, rid):
        return self.client.post(f"/v1/service-requests/{rid}/submit", json={"consent": True, "consent_version": CONSENT_VERSION}, headers=self.headers)

    def session(self):
        return self.client.post("/v1/sessions", headers=self.headers).json()["id"]

    def turn(self, sid, text_="fuite sous l'évier"):
        return self.client.post(f"/v1/sessions/{sid}/turn", json={"kind": "description", "text": text_}, headers=self.headers)

    def check(self, city, cp):
        return self.client.post("/v1/service-area/check", json={"city": city, "postal_code": cp}, headers=self.headers).json()


@pytest.fixture
def make_env(clean_db, tmp_path):
    def _make(*analyses):
        provider, notifier = ScriptedProvider(*analyses), FakeNotifier()
        app = create_app()
        storage = LocalMediaStorage(tmp_path)
        app.dependency_overrides[get_diagnostic_service] = lambda: DiagnosticService(provider)
        app.dependency_overrides[get_ai_provider] = lambda: provider
        app.dependency_overrides[get_storage] = lambda: storage
        app.dependency_overrides[get_request_notifier] = lambda: notifier
        return Env(TestClient(app), provider, notifier, {"X-Nalvium-Install-Id": new_install_id()})

    return _make


def states(engine):
    with engine.connect() as c:
        return c.execute(text("SELECT status, notification_status FROM service_requests")).all()


def test_service_area_info_comes_from_the_central_config(make_env):
    env = make_env()
    assert env.client.get("/v1/service-area").json() == {"name": "Lyon", "radius_km": 50}


def test_check_endpoint_reports_in_out_and_invalid(make_env):
    env = make_env()
    assert env.check("Lyon", "69003") == {"status": "in_zone", "code": None}
    assert env.check("Villeurbanne", "69100")["status"] == "in_zone"
    assert env.check("Grenoble", "38000") == {"status": "out_of_zone", "code": None}
    assert env.check("Lyon", "75001") == {"status": "invalid", "code": "city_postal_mismatch"}
    assert env.check("Lyon", "99999")["code"] == "unknown_postal_code"
    assert env.check("Zzyzx", "69100")["code"] == "unknown_city"
    assert env.check("Lyon", "69")["code"] == "invalid_postal_code"
    assert env.client.post("/v1/service-area/check", json={"city": "Lyon", "postal_code": "69003"}).status_code == 401


def test_in_zone_request_continues_exactly_as_before_and_notifies(make_env, engine):  # P
    env = make_env()
    rid = env.draft()
    env.patch(rid, **IN_ZONE)
    r = env.submit(rid)
    assert r.status_code == 200 and r.json()["status"] == "SUBMITTED"
    assert len(env.notifier.messages) == 1 and "Ville : Villeurbanne 69100" in env.notifier.messages[0]
    assert states(engine) == [("SUBMITTED", "sent")]


def test_direct_request_out_of_zone_is_never_submitted_and_never_listed(make_env, engine):  # L, O
    env = make_env()
    rid = env.draft()
    env.patch(rid, **OUT_OF_ZONE)  # le brouillon peut exister
    r = env.submit(rid)
    assert r.status_code == 422 and r.json()["detail"] == "out_of_zone"
    assert env.client.get(f"/v1/service-requests/{rid}", headers=env.headers).json()["status"] == "DRAFT"
    assert env.client.get("/v1/service-requests", headers=env.headers).json() == []  # pas dans « Vos demandes »
    assert env.notifier.messages == []
    assert states(engine) == [("DRAFT", None)]
    # corriger la zone permet ensuite l'envoi normal
    env.patch(rid, city="Lyon", postal_code="69003")
    assert env.submit(rid).status_code == 200 and len(env.notifier.messages) == 1


def test_diagnostic_request_out_of_zone_is_never_submitted_and_the_diagnostic_is_intact(make_env, engine):  # M
    env = make_env(make_analysis(T.INSTRUCTION, "Fermez le robinet.", choices=["C'est fait", "Je n'y arrive pas", "Ce n'est pas ce que je vois"]))
    sid = env.session()
    env.turn(sid)
    rid = env.client.post(f"/v1/sessions/{sid}/service-request", headers=env.headers).json()["id"]
    env.patch(rid, **OUT_OF_ZONE)
    assert env.submit(rid).json()["detail"] == "out_of_zone"
    assert env.notifier.messages == []
    s = env.client.get(f"/v1/sessions/{sid}", headers=env.headers).json()
    assert s["status"] == "active" and s["next"]["action_type"] == "INSTRUCTION"  # diagnostic intact
    assert states(engine) == [("DRAFT", None)]


def test_safety_stop_out_of_zone_keeps_safety_and_creates_no_intervention(make_env, engine):  # N
    stop = make_analysis(T.SAFETY_STOP, "Arrêtez-vous ici. Eau et électricité : coupez le courant.", risk=RiskLevel.EMERGENCY, diy=False)
    env = make_env(stop)
    sid = env.session()
    env.turn(sid, "de l'eau sous le tableau")
    rid = env.client.post(f"/v1/sessions/{sid}/service-request", headers=env.headers).json()["id"]
    ctx = env.client.get(f"/v1/service-requests/{rid}", headers=env.headers).json()["context"]
    assert "coupez le courant" in ctx["safety_stop_reason"]  # la raison de sécurité reste disponible
    env.patch(rid, **OUT_OF_ZONE)
    assert env.submit(rid).status_code == 422
    s = env.client.get(f"/v1/sessions/{sid}", headers=env.headers).json()
    assert s["status"] == "stopped" and s["next"]["action_type"] == "SAFETY_STOP"
    assert env.client.get("/v1/service-requests", headers=env.headers).json() == []
    assert env.notifier.messages == [] and states(engine) == [("DRAFT", None)]


@pytest.mark.parametrize("city,cp,code", [("Lyon", "75001", "city_postal_mismatch"), ("Lyon", "95999", "unknown_postal_code"), ("Zzyzx", "69100", "unknown_city")])
def test_unusable_city_postal_never_submits_nor_notifies(make_env, engine, city, cp, code):
    env = make_env()
    rid = env.draft()
    env.patch(rid, **{**BASE, "city": city, "postal_code": cp})
    r = env.submit(rid)
    assert r.status_code == 422 and r.json()["detail"] == code
    assert env.notifier.messages == [] and states(engine) == [("DRAFT", None)]


def test_no_geographic_coordinates_are_stored_or_exposed(make_env, engine):
    env = make_env()
    rid = env.draft()
    env.patch(rid, **IN_ZONE)
    body = env.submit(rid).json()
    flat = str(body).lower()
    for forbidden in ("lat", "lon", "gps", "coord", "distance", "geo"):
        assert forbidden not in flat, forbidden
    with engine.connect() as c:
        cols = {r[0] for r in c.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='service_requests'"))}
    assert not {"latitude", "longitude", "lat", "lon", "address", "distance_km"} & cols
    assert not any(w in env.notifier.messages[0].lower() for w in ("km", "gps", "latitude"))


def test_the_restriction_applies_only_to_human_help__diagnostic_house_community_are_free(make_env):  # Q, R, S
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?"))
    rid = env.draft()
    env.patch(rid, **OUT_OF_ZONE)
    assert env.submit(rid).status_code == 422  # même utilisateur, hors zone
    sid = env.session()
    assert env.turn(sid).status_code == 200  # Q : diagnostic IA
    assert env.client.post("/v1/equipment", json={"equipment_type": "oven", "brand": "Samsung"}, headers=env.headers).status_code == 201  # R : Maison
    assert env.client.get("/v1/home", headers=env.headers).status_code == 200
    from app.community.rules import COMMUNITY_CONSENT_VERSION

    post = {"title": "Joint de robinet changé", "solution": "J'ai changé le joint et resserré l'écrou.", "consent_public": True, "consent_version": COMMUNITY_CONSENT_VERSION}
    assert env.client.post("/v1/community/posts", json=post, headers=env.headers).status_code == 201  # S : Communauté
    assert env.client.get("/v1/community/posts", headers=env.headers).status_code == 200


def test_logs_never_contain_city_or_postal_code(make_env, caplog):
    caplog.set_level(logging.DEBUG)
    env = make_env()
    rid = env.draft()
    env.patch(rid, **OUT_OF_ZONE)
    env.submit(rid)
    assert "grenoble" not in caplog.text.lower() and "38000" not in caplog.text
