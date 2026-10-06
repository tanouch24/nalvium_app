import logging

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text

from app.api.deps import get_ai_provider, get_diagnostic_service, get_request_notifier, get_storage
from app.domain.diagnosis import NextActionType as T
from app.domain.diagnosis import RiskLevel
from app.main import create_app
from app.media.storage import LocalMediaStorage
from app.notifications.service_requests import NotConfiguredNotifier, NotifyResult
from app.service_requests.validation import CONSENT_VERSION
from app.services.diagnostic_service import DiagnosticService
from tests.helpers import ScriptedProvider, jpeg_bytes, make_analysis, new_install_id

pytestmark = pytest.mark.integration

CONTACT = {"first_name": "Camille", "phone": "06 12 34 56 78", "city": "Lyon", "postal_code": "69003",
           "availability_type": "asap", "email": "camille@example.fr"}


class FakeNotifier:
    configured = True

    def __init__(self, result=None, boom=None):
        self.result, self.boom, self.messages = result or NotifyResult("sent"), boom, []

    def notify(self, text_):
        self.messages.append(text_)
        if self.boom:
            raise self.boom
        return self.result


class Env:
    def __init__(self, client, provider, notifier, headers):
        self.client, self.provider, self.notifier, self.headers = client, provider, notifier, headers

    def draft(self, summary="Fuite sous mon évier"):
        return self.client.post("/v1/service-requests", json={"problem_summary": summary, "category": "plumbing"}, headers=self.headers).json()["id"]

    def ready(self, rid):
        return self.client.patch(f"/v1/service-requests/{rid}", json=CONTACT, headers=self.headers)

    def submit(self, rid, consent=True):
        return self.client.post(f"/v1/service-requests/{rid}/submit", json={"consent": consent, "consent_version": CONSENT_VERSION}, headers=self.headers)


@pytest.fixture
def make_env(clean_db, tmp_path):
    def _make(*analyses, notifier=None):
        provider = ScriptedProvider(*analyses)
        notifier = notifier if notifier is not None else FakeNotifier()
        app = create_app()
        storage = LocalMediaStorage(tmp_path)
        app.dependency_overrides[get_diagnostic_service] = lambda: DiagnosticService(provider)
        app.dependency_overrides[get_ai_provider] = lambda: provider
        app.dependency_overrides[get_storage] = lambda: storage
        app.dependency_overrides[get_request_notifier] = lambda: notifier
        return Env(TestClient(app), provider, notifier, {"X-Nalvium-Install-Id": new_install_id()})

    return _make


def state(engine):
    with engine.connect() as c:
        return c.execute(text("SELECT status, notification_status, notification_error, notification_attempted_at IS NOT NULL, notification_sent_at IS NOT NULL FROM service_requests")).one()


def test_submitted_triggers_one_notification_and_records_it(make_env, engine):
    env = make_env()
    rid = env.draft()
    env.ready(rid)
    assert env.submit(rid).status_code == 200
    assert len(env.notifier.messages) == 1 and "#REQ-" in env.notifier.messages[0]
    assert state(engine) == ("SUBMITTED", "sent", None, True, True)


def test_draft_and_invalid_submit_trigger_nothing(make_env, engine):
    env = make_env()
    rid = env.draft()
    env.ready(rid)
    assert env.submit(rid, consent=False).status_code == 422  # consentement refusé
    env2 = env.client.post("/v1/service-requests", json={"problem_summary": "x"}, headers=env.headers)
    assert env2.status_code == 201
    assert env.notifier.messages == []
    assert state_all(engine) == {("DRAFT", None)}


def state_all(engine):
    with engine.connect() as c:
        return {(s, n) for s, n in c.execute(text("SELECT status, notification_status FROM service_requests"))}


def test_not_configured_is_recorded_and_submission_works(make_env, engine, caplog):
    caplog.set_level(logging.INFO)
    env = make_env(notifier=NotConfiguredNotifier())
    rid = env.draft()
    env.ready(rid)
    assert env.submit(rid).status_code == 200
    assert state(engine)[:3] == ("SUBMITTED", "not_configured", None)
    assert "notification not configured" in caplog.text


@pytest.mark.parametrize("result", [NotifyResult("failed", "timeout"), NotifyResult("failed", "http_500"), NotifyResult("failed", "network_ConnectError")])
def test_telegram_failures_never_block_the_submission(make_env, engine, result):
    env = make_env(notifier=FakeNotifier(result))
    rid = env.draft()
    env.ready(rid)
    r = env.submit(rid)
    assert r.status_code == 200 and r.json()["status"] == "SUBMITTED"  # aucun message bloquant pour l'utilisateur
    s = state(engine)
    assert s[0] == "SUBMITTED" and s[1] == "failed" and s[2] == result.error_code and s[4] is False
    assert env.client.get(f"/v1/service-requests/{rid}", headers=env.headers).json()["status"] == "SUBMITTED"


def test_unexpected_notifier_exception_is_contained_and_traced(make_env, engine, caplog):
    caplog.set_level(logging.DEBUG)
    env = make_env(notifier=FakeNotifier(boom=RuntimeError("https://api.telegram.org/botSECRET/send")))
    rid = env.draft()
    env.ready(rid)
    assert env.submit(rid).status_code == 200
    s = state(engine)
    assert s[:3] == ("SUBMITTED", "failed", "internal_RuntimeError")
    assert "SECRET" not in caplog.text  # ni l'URL ni le jeton ne sont journalisés


def test_double_submit_and_retry_never_duplicate_the_notification(make_env, engine):
    env = make_env()
    rid = env.draft()
    env.ready(rid)
    assert env.submit(rid).status_code == 200
    assert env.submit(rid).status_code == 409
    assert env.submit(rid).status_code == 409
    assert len(env.notifier.messages) == 1
    with engine.connect() as c:
        assert c.execute(text("SELECT count(*) FROM service_requests")).scalar() == 1


def test_the_claim_is_atomic_even_if_called_twice(make_env, engine):
    """Course simulée : une seconde réservation sur la même demande échoue."""
    from sqlalchemy.orm import Session

    from app.repositories.service_requests import ServiceRequestRepository

    env = make_env()
    rid = env.draft()
    env.ready(rid)
    env.submit(rid)  # a déjà notifié
    import uuid

    with Session(engine) as db:
        assert ServiceRequestRepository(db).claim_notification(uuid.UUID(rid)) is False
    assert len(env.notifier.messages) == 1


def test_only_consented_media_counts_and_no_media_is_sent(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?"))
    sid = env.client.post("/v1/sessions", headers=env.headers).json()["id"]
    chosen = env.client.post(f"/v1/sessions/{sid}/media", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=env.headers).json()["id"]
    env.client.post(f"/v1/sessions/{sid}/media", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=env.headers)  # privé
    env.client.post(f"/v1/sessions/{sid}/turn", json={"kind": "description", "text": "fuite"}, headers=env.headers)
    rid = env.client.post(f"/v1/sessions/{sid}/service-request", headers=env.headers).json()["id"]
    env.ready(rid)
    env.client.put(f"/v1/service-requests/{rid}/media", json={"media_ids": [chosen]}, headers=env.headers)
    env.submit(rid)
    msg = env.notifier.messages[0]
    assert "Médias autorisés : 1 photo / 0 vidéo" in msg
    assert chosen not in msg and "http" not in msg and ".jpg" not in msg


def test_safety_stop_and_context_in_message_without_internal_data(make_env):
    stop = make_analysis(T.SAFETY_STOP, "Arrêtez-vous ici. Eau et électricité : coupez le courant.", risk=RiskLevel.EMERGENCY, diy=False)
    env = make_env(stop)
    eq = env.client.post("/v1/equipment", json={"equipment_type": "dishwasher", "brand": "Bosch", "model": "SMV4HVX31E"}, headers=env.headers).json()["id"]
    sid = env.client.post("/v1/sessions", json={"equipment_id": eq}, headers=env.headers).json()["id"]
    env.client.post(f"/v1/sessions/{sid}/turn", json={"kind": "description", "text": "eau sous le tableau"}, headers=env.headers)
    rid = env.client.post(f"/v1/sessions/{sid}/service-request", headers=env.headers).json()["id"]
    env.ready(rid)
    env.submit(rid)
    msg = env.notifier.messages[0]
    assert "Sécurité :" in msg and "coupez le courant" in msg
    assert "Lave-vaisselle Bosch SMV4HVX31E" in msg and "Diagnostic Nalvium" in msg
    for forbidden in (env.headers["X-Nalvium-Install-Id"], sid, eq, "prompt", "reasoning", "confidence", "camille@example.fr", ".pdf"):
        assert forbidden not in msg, forbidden


def test_notification_state_is_not_exposed_and_token_never_in_responses(make_env):
    env = make_env()
    rid = env.draft()
    env.ready(rid)
    body = env.submit(rid).text
    assert "notification" not in body and "telegram" not in body.lower()
