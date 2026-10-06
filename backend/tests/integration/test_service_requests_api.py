from datetime import UTC, datetime, timedelta

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text

from app.api.deps import get_ai_provider, get_diagnostic_service, get_storage
from app.domain.diagnosis import NextActionType as T
from app.domain.diagnosis import RiskLevel
from app.main import create_app
from app.media.storage import LocalMediaStorage
from app.service_requests.handoff import handoff_payload
from app.service_requests.validation import CONSENT_VERSION
from app.services.diagnostic_service import DiagnosticService
from tests.helpers import ScriptedProvider, jpeg_bytes, make_analysis, new_install_id

pytestmark = pytest.mark.integration

CONTACT = {"first_name": "Camille", "phone": "06 12 34 56 78", "city": "Lyon", "postal_code": "69003",
           "availability_type": "asap"}


class Env:
    def __init__(self, client, provider, headers):
        self.client, self.provider, self.headers = client, provider, headers

    def other(self):
        return {"X-Nalvium-Install-Id": new_install_id()}

    def session(self, equipment_id=None, headers=None):
        body = {"equipment_id": equipment_id} if equipment_id else None
        return self.client.post("/v1/sessions", json=body, headers=headers or self.headers).json()["id"]

    def turn(self, sid, text_="Mon lave-vaisselle ne vidange plus"):
        return self.client.post(f"/v1/sessions/{sid}/turn", json={"kind": "description", "text": text_}, headers=self.headers)

    def photo(self, sid):
        r = self.client.post(f"/v1/sessions/{sid}/media", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=self.headers)
        return r.json()["id"]

    def draft(self, **body):
        return self.client.post("/v1/service-requests", json=body, headers=self.headers)

    def from_session(self, sid, headers=None):
        return self.client.post(f"/v1/sessions/{sid}/service-request", headers=headers or self.headers)

    def patch(self, rid, **body):
        return self.client.patch(f"/v1/service-requests/{rid}", json=body, headers=self.headers)

    def submit(self, rid, consent=True, version=CONSENT_VERSION, headers=None):
        return self.client.post(f"/v1/service-requests/{rid}/submit", json={"consent": consent, "consent_version": version},
                                headers=headers or self.headers)

    def ready(self, rid, **extra):
        return self.patch(rid, **{**CONTACT, **extra})


@pytest.fixture
def make_env(clean_db, tmp_path):
    def _make(*analyses):
        provider = ScriptedProvider(*analyses)
        app = create_app()
        storage = LocalMediaStorage(tmp_path)
        app.dependency_overrides[get_diagnostic_service] = lambda: DiagnosticService(provider)
        app.dependency_overrides[get_ai_provider] = lambda: provider
        app.dependency_overrides[get_storage] = lambda: storage
        return Env(TestClient(app), provider, {"X-Nalvium-Install-Id": new_install_id()})

    return _make


def test_direct_draft_without_diagnostic_and_without_ai(make_env):
    env = make_env()
    r = env.draft(problem_summary="Fuite sous mon évier", category="plumbing")
    assert r.status_code == 201
    body = r.json()
    assert body["status"] == "DRAFT" and body["diagnostic_session_id"] is None
    assert body["problem_summary"] == "Fuite sous mon évier" and body["context"]["source"] == "direct"
    assert env.provider.contexts == []  # aucun appel GPT-5 pour créer un lead
    assert env.client.get("/v1/service-requests", headers=env.headers).json() == []  # les brouillons ne sont pas listés
    assert env.draft(category="inconnue").status_code == 422


def test_draft_from_diagnostic_carries_structured_context(make_env):
    a = make_analysis(T.INSTRUCTION, "Retirez le filtre.", choices=["C'est fait", "Je n'y arrive pas", "Ce n'est pas ce que je vois"],
                      title="Lave-vaisselle qui ne vidange plus", manual_pages_used=[])
    env = make_env(a)
    eq = env.client.post("/v1/equipment", json={"equipment_type": "dishwasher", "room_type": "kitchen", "brand": "Bosch",
                                                "model": "SMV4HVX31E"}, headers=env.headers).json()["id"]
    sid = env.session(eq)
    env.turn(sid)
    r = env.from_session(sid)
    assert r.status_code == 200
    body = r.json()
    ctx = body["context"]
    assert body["diagnostic_session_id"] == sid and body["equipment_id"] == eq
    assert body["problem_category"] == "plumbing" and "ne vidange plus" in body["problem_summary"]
    assert ctx["equipment"]["brand"] == "Bosch" and ctx["equipment"]["model"] == "SMV4HVX31E" and ctx["equipment"]["room"] == "Cuisine"
    assert ctx["observations"] == ["De l'eau près du siphon"]
    assert ctx["hypotheses"][0]["note"].startswith("hypothèse") and ctx["hypotheses"][0]["label"] == "Joint usé"
    assert ctx["actions_tried"] == [{"instruction": "Retirez le filtre.", "result": "proposé"}]
    assert ctx["manual"] is None
    assert env.from_session(sid).json()["id"] == body["id"]  # un seul brouillon par diagnostic
    assert env.client.get(f"/v1/sessions/{sid}", headers=env.headers).json()["status"] == "active"  # diagnostic intact


def test_ownership_everywhere(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?"))
    sid = env.session()
    env.turn(sid)
    rid = env.from_session(sid).json()["id"]
    other = env.other()
    assert env.from_session(sid, headers=other).status_code == 404
    assert env.client.get(f"/v1/service-requests/{rid}", headers=other).status_code == 404
    assert env.client.patch(f"/v1/service-requests/{rid}", json={"city": "X"}, headers=other).status_code == 404
    assert env.submit(rid, headers=other).status_code == 404
    assert env.client.post(f"/v1/service-requests/{rid}/cancel", headers=other).status_code == 404
    assert env.client.put(f"/v1/service-requests/{rid}/media", json={"media_ids": []}, headers=other).status_code == 404
    assert env.client.get("/v1/service-requests", headers=other).json() == []
    assert env.client.get("/v1/service-requests").status_code == 401
    eq = env.client.post("/v1/equipment", json={"equipment_type": "oven"}, headers=env.headers).json()["id"]
    assert env.client.post("/v1/service-requests", json={"equipment_id": eq}, headers=other).status_code == 404


@pytest.mark.parametrize("field,value,code", [
    ("phone", "123", "invalid_phone"), ("postal_code", "7501", "invalid_postal_code"), ("email", "nope", "invalid_email"),
    ("availability_type", "never", "invalid_availability"),
])
def test_field_validation_messages(make_env, field, value, code):
    env = make_env()
    rid = env.draft(problem_summary="x").json()["id"]
    r = env.patch(rid, **{field: value})
    assert r.status_code == 422 and r.json()["detail"] == code


def test_phone_is_normalized_and_availability_custom(make_env):
    env = make_env()
    rid = env.draft(problem_summary="x").json()["id"]
    tomorrow = (datetime.now(UTC) + timedelta(days=1)).date().isoformat()
    body = env.patch(rid, phone="06 12 34 56 78", availability_type="custom", preferred_date=tomorrow,
                     preferred_time_window="afternoon").json()
    assert body["phone"] == "+33612345678" and body["preferred_date"] == tomorrow and body["preferred_time_window"] == "afternoon"
    assert env.patch(rid, preferred_date="2020-01-01").status_code == 422
    assert env.patch(rid, availability_type="custom", preferred_time_window="night").status_code == 422


def test_media_selection_only_chosen_media_and_no_foreign_media(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?"))
    sid = env.session()
    m1, m2 = env.photo(sid), env.photo(sid)
    env.turn(sid)
    rid = env.from_session(sid).json()["id"]
    assert env.client.get(f"/v1/service-requests/{rid}", headers=env.headers).json()["media_ids"] == []  # rien d'auto
    r = env.client.put(f"/v1/service-requests/{rid}/media", json={"media_ids": [m1]}, headers=env.headers)
    assert r.json()["media_ids"] == [m1]
    other = env.other()
    osid = env.session(headers=other)
    foreign = env.client.post(f"/v1/sessions/{osid}/media", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=other).json()["id"]
    assert env.client.put(f"/v1/service-requests/{rid}/media", json={"media_ids": [foreign]}, headers=env.headers).status_code == 422
    other_session_own = env.photo(env.session())  # média à moi mais d'une AUTRE session
    assert env.client.put(f"/v1/service-requests/{rid}/media", json={"media_ids": [other_session_own]}, headers=env.headers).status_code == 422
    assert m2 not in env.client.get(f"/v1/service-requests/{rid}", headers=env.headers).json()["media_ids"]


def test_consent_is_mandatory_never_prechecked_and_recorded(make_env, engine):
    env = make_env()
    rid = env.draft(problem_summary="Prise qui chauffe").json()["id"]
    env.ready(rid)
    assert env.submit(rid, consent=False).json()["detail"] == "consent_required"
    r = env.client.post(f"/v1/service-requests/{rid}/submit", json={}, headers=env.headers)
    assert r.json()["detail"] == "consent_required"  # corps vide : refus par défaut
    assert env.submit(rid, version="ancienne").json()["detail"] == "consent_version_mismatch"
    assert env.client.get(f"/v1/service-requests/{rid}", headers=env.headers).json()["status"] == "DRAFT"
    ok = env.submit(rid).json()
    assert ok["status"] == "SUBMITTED" and ok["consent_version"] == CONSENT_VERSION and ok["consented_at"] and ok["submitted_at"]
    with engine.connect() as c:
        cats = c.execute(text("SELECT consented_categories FROM service_requests")).scalar()
    assert set(cats) == {"problem", "contact", "availability"}


@pytest.mark.parametrize("missing,code", [
    ("first_name", "first_name_required"), ("phone", "phone_required"), ("city", "city_required"),
    ("postal_code", "postal_code_required"), ("availability_type", "availability_required"),
])
def test_submit_requires_contact_fields(make_env, missing, code):
    env = make_env()
    rid = env.draft(problem_summary="x").json()["id"]
    contact = {k: v for k, v in CONTACT.items() if k != missing}
    env.patch(rid, **contact)
    r = env.submit(rid)
    assert r.status_code == 422 and r.json()["detail"] == code


def test_submit_requires_a_problem(make_env):
    env = make_env()
    rid = env.draft().json()["id"]
    env.ready(rid)
    assert env.submit(rid).json()["detail"] == "problem_required"


def test_double_submit_and_edit_after_submit_are_refused(make_env):
    env = make_env()
    rid = env.draft(problem_summary="x").json()["id"]
    env.ready(rid)
    assert env.submit(rid).status_code == 200
    again = env.submit(rid)
    assert again.status_code == 409 and again.json()["detail"] == "already_submitted"
    assert env.patch(rid, city="Paris").status_code == 409
    assert env.client.put(f"/v1/service-requests/{rid}/media", json={"media_ids": []}, headers=env.headers).status_code == 409


def test_cancel_rules_list_and_detail(make_env):
    env = make_env()
    r1 = env.draft(problem_summary="Un").json()["id"]
    r2 = env.draft(problem_summary="Deux").json()["id"]
    env.ready(r1), env.ready(r2)
    env.submit(r1), env.submit(r2)
    c = env.client.post(f"/v1/service-requests/{r1}/cancel", headers=env.headers).json()
    assert c["status"] == "CANCELLED"
    assert env.client.post(f"/v1/service-requests/{r1}/cancel", headers=env.headers).status_code == 409
    listed = env.client.get("/v1/service-requests", headers=env.headers).json()
    assert [r["id"] for r in listed] == [r2, r1] and {r["status"] for r in listed} == {"SUBMITTED", "CANCELLED"}
    assert env.client.get(f"/v1/service-requests/{r2}", headers=env.headers).json()["problem_summary"] == "Deux"


def test_snapshot_is_frozen_at_submit_and_keeps_safety_stop_reason(make_env):
    stop = make_analysis(T.SAFETY_STOP, "Arrêtez-vous ici. Eau et électricité : coupez le courant.", risk=RiskLevel.EMERGENCY, diy=False)
    env = make_env(stop)
    sid = env.session()
    env.turn(sid, "de l'eau sous le tableau")
    rid = env.from_session(sid).json()["id"]
    env.ready(rid)
    body = env.submit(rid).json()
    ctx = body["context"]
    assert ctx["diagnostic_status"] == "stopped" and "coupez le courant" in ctx["safety_stop_reason"]
    # le diagnostic évolue / disparaît ensuite : la demande conserve ce que l'utilisateur a validé
    again = env.client.get(f"/v1/service-requests/{rid}", headers=env.headers).json()["context"]
    assert again == ctx


def test_snapshot_survives_session_changes(make_env, engine):
    env = make_env(make_analysis(T.RECOMMEND_PROFESSIONAL, "Appelez un professionnel.", title="Fuite"))
    sid = env.session()
    env.turn(sid)
    rid = env.from_session(sid).json()["id"]
    env.ready(rid)
    ctx = env.submit(rid).json()["context"]
    assert ctx["professional_reason"] == "Appelez un professionnel."
    with engine.begin() as c:
        c.execute(text("UPDATE diagnostic_sessions SET title='Modifié', description='autre'"))
    assert env.client.get(f"/v1/service-requests/{rid}", headers=env.headers).json()["context"]["title"] == "Fuite"


def test_manual_used_is_kept_as_pages_without_the_pdf(make_env, engine):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?"))
    sid = env.session()
    env.turn(sid)
    with engine.begin() as c:
        c.execute(text("UPDATE session_messages SET manual_pages='{31,17}' WHERE role='nalvium'"))
    eq = env.client.post("/v1/equipment", json={"equipment_type": "dishwasher", "brand": "Bosch", "model": "SMV4HVX31E"}, headers=env.headers).json()["id"]
    env.client.post(f"/v1/sessions/{sid}/equipment", json={"equipment_id": eq}, headers=env.headers)
    rid = env.from_session(sid).json()["id"]
    env.ready(rid)
    body = env.submit(rid).json()
    assert body["context"]["manual"] == {"consulted": True, "manufacturer": "Bosch", "model": "SMV4HVX31E", "pages": [17, 31]}
    assert "pdf" not in str(body["context"]).lower() and body["media_ids"] == []


def test_handoff_contains_only_consented_data(make_env, engine):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?"))
    sid = env.session()
    chosen, private = env.photo(sid), env.photo(sid)
    env.turn(sid)
    rid = env.from_session(sid).json()["id"]
    env.ready(rid, email="camille@example.fr")
    env.client.put(f"/v1/service-requests/{rid}/media", json={"media_ids": [chosen]}, headers=env.headers)
    env.submit(rid)
    import uuid

    from sqlalchemy.orm import Session

    from app.repositories.service_requests import ServiceRequestRepository
    with Session(engine) as db:
        req = ServiceRequestRepository(db).get_owned(uuid.UUID(rid), uuid.UUID(env.headers["X-Nalvium-Install-Id"]))
        payload = handoff_payload(req)
    flat = str(payload)
    assert [m["media_id"] for m in payload["media"]] == [chosen] and private not in flat
    assert payload["consent"]["version"] == CONSENT_VERSION and payload["consent"]["at"]
    assert payload["contact"] == {"first_name": "Camille", "phone": "+33612345678", "email": "camille@example.fr",
                                  "city": "Lyon", "postal_code": "69003"}
    for forbidden in ("prompt", "reasoning", "confidence", "install", env.headers["X-Nalvium-Install-Id"]):
        assert forbidden not in flat.lower()
    assert "address" not in flat.lower()
    assert [c for c in payload["consent"]["categories"]] == ["problem", "contact", "availability", "diagnostic_context", "media"]


def test_nothing_in_the_db_for_unselected_media_and_counter_untouched(make_env, engine):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?"))
    sid = env.session()
    env.photo(sid)
    env.turn(sid)
    rid = env.from_session(sid).json()["id"]
    env.ready(rid)
    env.submit(rid)
    with engine.connect() as c:
        assert c.execute(text("SELECT count(*) FROM service_request_media")).scalar() == 0
        assert c.execute(text("SELECT count(*) FROM diagnostic_sessions")).scalar() == 1  # aucune nouvelle session
    assert len(env.provider.contexts) == 1  # l'analyse du diagnostic seulement, aucun appel IA pour la demande


def test_standalone_photo_can_be_attached_to_a_direct_request(make_env):
    env = make_env()
    mid = env.client.post("/v1/equipment/photo", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=env.headers).json()["id"]
    rid = env.draft(problem_summary="Volet bloqué").json()["id"]
    r = env.client.put(f"/v1/service-requests/{rid}/media", json={"media_ids": [mid]}, headers=env.headers)
    assert r.json()["media_ids"] == [mid]


def test_deleting_equipment_keeps_the_frozen_request(make_env):
    env = make_env()
    eq = env.client.post("/v1/equipment", json={"equipment_type": "oven", "brand": "Samsung"}, headers=env.headers).json()["id"]
    rid = env.draft(problem_summary="Four en panne", equipment_id=eq).json()["id"]
    env.ready(rid)
    env.submit(rid)
    env.client.delete(f"/v1/equipment/{eq}", headers=env.headers)
    body = env.client.get(f"/v1/service-requests/{rid}", headers=env.headers).json()
    assert body["equipment_id"] is None and body["context"]["equipment"]["brand"] == "Samsung"
