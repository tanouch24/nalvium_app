import io

import pytest
from fastapi.testclient import TestClient
from PIL import Image
from sqlalchemy import text

from app.ai.provider import AIProviderError
from app.api.deps import get_ai_provider, get_diagnostic_service, get_storage
from app.domain.diagnosis import EquipmentIdentification
from app.domain.diagnosis import NextActionType as T
from app.main import create_app
from app.media.storage import LocalMediaStorage
from app.services.diagnostic_service import DiagnosticService
from tests.helpers import ScriptedProvider, jpeg_bytes, make_analysis, new_install_id

pytestmark = pytest.mark.integration


class Env:
    def __init__(self, client, provider, headers, storage):
        self.client, self.provider, self.headers, self.storage = client, provider, headers, storage

    def other(self):
        return {"X-Nalvium-Install-Id": new_install_id()}

    def add(self, headers=None, **body):
        body = {"equipment_type": "dishwasher", "room_type": "kitchen", **body}
        return self.client.post("/v1/equipment", json=body, headers=headers or self.headers)

    def photo(self, headers=None, raw=None):
        return self.client.post(
            "/v1/equipment/photo", files={"file": ("p.jpg", raw or jpeg_bytes(), "image/jpeg")},
            headers=headers or self.headers,
        )

    def session(self, equipment_id=None, headers=None):
        body = {"equipment_id": equipment_id} if equipment_id else None
        return self.client.post("/v1/sessions", json=body, headers=headers or self.headers)

    def turn(self, sid, body):
        return self.client.post(f"/v1/sessions/{sid}/turn", json=body, headers=self.headers)


@pytest.fixture
def make_env(clean_db, tmp_path):
    def _make(*analyses):
        provider = ScriptedProvider(*analyses)
        app = create_app()
        storage = LocalMediaStorage(tmp_path)
        app.dependency_overrides[get_diagnostic_service] = lambda: DiagnosticService(provider)
        app.dependency_overrides[get_ai_provider] = lambda: provider
        app.dependency_overrides[get_storage] = lambda: storage
        return Env(TestClient(app), provider, {"X-Nalvium-Install-Id": new_install_id()}, storage)

    return _make


def test_home_is_created_automatically_and_empty(make_env):
    env = make_env()
    body = env.client.get("/v1/home", headers=env.headers).json()
    assert body["equipment"] == [] and body["rooms"] == []
    again = env.client.get("/v1/home", headers=env.headers).json()
    assert again["id"] == body["id"]  # une seule Maison par défaut
    assert env.client.get("/v1/home").status_code == 401


def test_create_minimal_equipment_without_brand_model_or_photo(make_env):
    env = make_env()
    r = env.add()
    assert r.status_code == 201
    body = r.json()
    assert body["display_name"] == "Lave-vaisselle" and body["room_name"] == "Cuisine"
    assert body["brand"] is None and body["model"] is None and body["photo_media_id"] is None
    assert body["diagnostics"] == [] and body["diagnostics_count"] == 0


def test_create_without_room_and_unknown_type_slug(make_env):
    env = make_env()
    body = env.add(equipment_type="barbecue", room_type=None, display_name="  Barbecue   du jardin ").json()
    assert body["room_id"] is None and body["display_name"] == "Barbecue du jardin"
    assert env.add(equipment_type="Pas Un Slug!").status_code == 422
    assert env.add(room_type="grenier").status_code == 422


def test_rooms_are_reused_and_home_groups_equipment(make_env):
    env = make_env()
    env.add()
    env.add(equipment_type="oven", brand="Samsung")
    env.add(equipment_type="water_heater", room_type="bathroom", brand="Atlantic")
    home = env.client.get("/v1/home", headers=env.headers).json()
    assert sorted(r["name"] for r in home["rooms"]) == ["Cuisine", "Salle de bain"]
    assert len(home["equipment"]) == 3
    assert {e["room_name"] for e in home["equipment"]} == {"Cuisine", "Salle de bain"}
    assert len(env.client.get("/v1/equipment", headers=env.headers).json()) == 3


def test_update_equipment_and_clear_optional_fields(make_env):
    env = make_env()
    eid = env.add(brand="Bosch", model="SMS46").json()["id"]
    r = env.client.patch(
        f"/v1/equipment/{eid}",
        json={"room_type": "laundry", "display_name": "Lave-vaisselle du fond", "brand": None},
        headers=env.headers,
    ).json()
    assert r["room_name"] == "Buanderie" and r["display_name"] == "Lave-vaisselle du fond"
    assert r["brand"] is None and r["model"] == "SMS46"  # modèle non fourni : inchangé
    r = env.client.patch(f"/v1/equipment/{eid}", json={"room_type": None}, headers=env.headers).json()
    assert r["room_id"] is None
    bad = env.client.patch(f"/v1/equipment/{eid}", json={"display_name": "  "}, headers=env.headers)
    assert bad.status_code == 422


def test_cross_user_access_is_forbidden_everywhere(make_env):
    env = make_env()
    eid = env.add().json()["id"]
    media = env.photo().json()["id"]
    other = env.other()
    assert env.client.get(f"/v1/equipment/{eid}", headers=other).status_code == 404
    assert env.client.patch(f"/v1/equipment/{eid}", json={"brand": "X"}, headers=other).status_code == 404
    assert env.client.delete(f"/v1/equipment/{eid}", headers=other).status_code == 404
    assert env.client.get("/v1/home", headers=other).json()["equipment"] == []
    assert env.session(eid, headers=other).status_code == 404
    assert env.client.get(f"/v1/media/{media}/thumbnail", headers=other).status_code == 404
    # l'autre utilisateur ne peut pas s'approprier la photo ni l'identifier
    assert env.add(headers=other, primary_media_id=media).status_code == 422
    assert env.client.post("/v1/equipment/identify", json={"media_id": media}, headers=other).status_code == 404
    # ni lier SA session à MON équipement
    sid = env.session(headers=other).json()["id"]
    r = env.client.post(f"/v1/sessions/{sid}/equipment", json={"equipment_id": eid}, headers=other)
    assert r.status_code == 404
    # l'équipement est intact
    assert env.client.get(f"/v1/equipment/{eid}", headers=env.headers).status_code == 200


def test_equipment_photo_is_private_clean_resized_with_thumbnail(make_env):
    env = make_env()
    exif = Image.Exif()
    exif[0x010F] = "SecretPhoneMaker"
    exif.get_ifd(0x8825)[2] = (48.0, 51.0, 24.0)
    r = env.photo(raw=jpeg_bytes(size=(3000, 2000), exif=exif.tobytes()))
    assert r.status_code == 201
    mid = r.json()["id"]
    full = env.client.get(f"/v1/media/{mid}/content", headers=env.headers)
    assert max(Image.open(io.BytesIO(full.content)).size) == 1600
    assert len(Image.open(io.BytesIO(full.content)).getexif()) == 0 and b"SecretPhoneMaker" not in full.content
    thumb = env.client.get(f"/v1/media/{mid}/thumbnail", headers=env.headers)
    img = Image.open(io.BytesIO(thumb.content))
    assert max(img.size) <= 480 and len(thumb.content) < len(full.content)
    assert env.client.get(f"/v1/media/{mid}/thumbnail").status_code == 401
    assert env.photo(raw=b"pas une image").status_code == 422


def test_photo_becomes_primary_then_is_replaced_and_removed(make_env):
    env = make_env()
    first = env.photo().json()["id"]
    eid = env.add(primary_media_id=first).json()["id"]
    assert env.client.get(f"/v1/equipment/{eid}", headers=env.headers).json()["photo_media_id"] == first
    second = env.photo().json()["id"]
    env.client.patch(f"/v1/equipment/{eid}", json={"primary_media_id": second}, headers=env.headers)
    # l'ancienne photo est supprimée (plus de fichier orphelin)
    assert env.client.get(f"/v1/media/{first}/content", headers=env.headers).status_code == 404
    env.client.patch(f"/v1/equipment/{eid}", json={"primary_media_id": None}, headers=env.headers)
    body = env.client.get(f"/v1/equipment/{eid}", headers=env.headers).json()
    assert body["photo_media_id"] is None
    assert env.client.get(f"/v1/media/{second}/content", headers=env.headers).status_code == 404


def test_session_media_cannot_be_used_as_equipment_photo(make_env):
    env = make_env()
    sid = env.session().json()["id"]
    media = env.client.post(
        f"/v1/sessions/{sid}/media", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")}, headers=env.headers
    ).json()["id"]
    assert env.add(primary_media_id=media).status_code == 422


# ---- identification -----------------------------------------------------------
def test_identification_is_structured_uncertain_and_creates_no_session(make_env, engine):
    env = make_env()
    env.provider.identifications.append(
        EquipmentIdentification(equipment_type="dishwasher", brand="Bosch", model=None,
                                confidence=0.62, visible_text=["Bosch"], needs_confirmation=True)
    )
    media = env.photo().json()["id"]
    r = env.client.post("/v1/equipment/identify", json={"media_id": media}, headers=env.headers)
    assert r.status_code == 200
    body = r.json()
    assert body == {"equipment_type": "dishwasher", "brand": "Bosch", "model": None, "confidence": 0.62,
                    "visible_text": ["Bosch"], "needs_confirmation": True}
    # ce n'est pas un diagnostic : aucune session, aucune analyse de diagnostic
    assert env.client.get("/v1/sessions", headers=env.headers).json() == []
    with engine.connect() as c:
        assert c.execute(text("SELECT count(*) FROM diagnostic_sessions")).scalar() == 0
    assert env.provider.contexts == []


def test_identification_unknown_stays_unknown(make_env):
    env = make_env()
    env.provider.identifications.append(
        EquipmentIdentification(equipment_type="unknown", confidence=0.1)
    )
    media = env.photo().json()["id"]
    body = env.client.post("/v1/equipment/identify", json={"media_id": media}, headers=env.headers).json()
    assert body["equipment_type"] == "unknown" and body["brand"] is None and body["model"] is None
    assert body["needs_confirmation"] is True


def test_identification_failure_keeps_the_photo_usable(make_env):
    env = make_env()
    env.provider.identifications.append(AIProviderError("boom"))
    media = env.photo().json()["id"]
    r = env.client.post("/v1/equipment/identify", json={"media_id": media}, headers=env.headers)
    assert r.status_code == 502 and r.json()["detail"] == "identification_failed"
    # la photo n'est pas perdue : on peut créer l'équipement avec
    assert env.add(primary_media_id=media).status_code == 201


def test_identification_unavailable_without_provider(make_env, clean_db, tmp_path):
    app = create_app()
    app.dependency_overrides[get_storage] = lambda: LocalMediaStorage(tmp_path)
    client = TestClient(app)
    h = {"X-Nalvium-Install-Id": new_install_id()}
    media = client.post("/v1/equipment/photo", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")},
                        headers=h).json()["id"]
    r = client.post("/v1/equipment/identify", json={"media_id": media}, headers=h)
    assert r.status_code == 503 and r.json()["detail"] == "identification_unavailable"


# ---- diagnostic lié ------------------------------------------------------------
def test_session_started_from_equipment_is_linked_and_context_is_structured(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "Entendez-vous la pompe ?", choices=["Oui", "Non"]))
    eid = env.add(brand="Bosch", model="SMS46").json()["id"]
    r = env.session(eid)
    assert r.status_code == 201 and r.json()["equipment"]["id"] == eid
    sid = r.json()["id"]
    assert r.json()["equipment"]["room_name"] == "Cuisine"
    out = env.turn(sid, {"kind": "description", "text": "Elle ne vidange plus"}).json()
    assert out["equipment"]["brand"] == "Bosch"
    ctx = env.provider.contexts[0]
    assert ctx.equipment.type == "dishwasher" and ctx.equipment.brand == "Bosch"
    assert ctx.equipment.model == "SMS46" and ctx.equipment.room == "Cuisine"
    assert ctx.equipment_history == []  # aucun antécédent
    assert env.session("00000000-0000-0000-0000-000000000000").status_code == 404


def test_history_limited_and_marked_as_context_not_proof(make_env):
    env = make_env(*[make_analysis(T.RESOLVED, "ok", title=f"Panne {i}") for i in range(5)],
                   make_analysis(T.ASK_QUESTION, "Question ?", title="Nouvelle panne"))
    eid = env.add().json()["id"]
    for i in range(5):  # 5 anciens diagnostics terminés
        sid = env.session(eid).json()["id"]
        env.turn(sid, {"kind": "description", "text": f"problème {i}"})
    sid = env.session(eid).json()["id"]
    env.turn(sid, {"kind": "description", "text": "encore un souci"})
    ctx = env.provider.contexts[-1]
    assert len(ctx.equipment_history) == 3  # borné
    assert all("résolu" in line for line in ctx.equipment_history)
    from app.ai.openai_provider import build_input

    rendered = build_input(ctx)[0]["content"][0]["text"]
    assert "ne prouvent PAS" in rendered and "marque: inconnue" in rendered


def test_unlinked_session_has_no_equipment_context(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?"))
    sid = env.session().json()["id"]
    out = env.turn(sid, {"kind": "description", "text": "fuite"}).json()
    assert out["equipment"] is None and env.provider.contexts[0].equipment is None


def test_equipment_history_lists_only_real_started_sessions(make_env):
    env = make_env(make_analysis(T.RESOLVED, "Réglé", title="Ne vidange plus"),
                   make_analysis(T.RECOMMEND_PROFESSIONAL, "Appelez", title="Fuite sous l'appareil"))
    eid = env.add().json()["id"]
    s1 = env.session(eid).json()["id"]
    env.turn(s1, {"kind": "description", "text": "ne vidange plus"})
    s2 = env.session(eid).json()["id"]
    env.turn(s2, {"kind": "description", "text": "fuite"})
    env.session(eid)  # session jamais démarrée : ignorée
    body = env.client.get(f"/v1/equipment/{eid}", headers=env.headers).json()
    assert body["diagnostics_count"] == 2
    assert {d["title"]: d["status"] for d in body["diagnostics"]} == {
        "Ne vidange plus": "resolved", "Fuite sous l'appareil": "referred"}
    home = env.client.get("/v1/home", headers=env.headers).json()
    assert home["equipment"][0]["diagnostics_count"] == 2
    listed = env.client.get("/v1/sessions", headers=env.headers).json()
    assert all(s["equipment_id"] == eid for s in listed)


def test_link_existing_session_then_detach(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?", title="Lave-vaisselle qui ne vidange plus"))
    sid = env.session().json()["id"]
    env.turn(sid, {"kind": "description", "text": "Mon lave-vaisselle ne vidange plus"})
    eid = env.add().json()["id"]
    r = env.client.post(f"/v1/sessions/{sid}/equipment", json={"equipment_id": eid}, headers=env.headers)
    assert r.status_code == 200 and r.json()["equipment"]["id"] == eid
    assert env.client.get(f"/v1/equipment/{eid}", headers=env.headers).json()["diagnostics_count"] == 1
    r = env.client.post(f"/v1/sessions/{sid}/equipment", json={"equipment_id": None}, headers=env.headers)
    assert r.json()["equipment"] is None
    nope = env.client.post(f"/v1/sessions/{sid}/equipment",
                           json={"equipment_id": "00000000-0000-0000-0000-000000000000"}, headers=env.headers)
    assert nope.status_code == 404


def test_suggestions_propose_but_never_link(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?", title="Lave-vaisselle qui ne vidange plus"))
    eid = env.add(brand="Bosch").json()["id"]
    env.add(equipment_type="oven")
    sid = env.session().json()["id"]
    env.turn(sid, {"kind": "description", "text": "Mon lave-vaisselle ne vidange plus"})
    body = env.client.get(f"/v1/sessions/{sid}/equipment/suggestions", headers=env.headers).json()
    assert body["detected_type"] == "dishwasher"
    assert [m["id"] for m in body["matches"]] == [eid]
    assert env.client.get(f"/v1/sessions/{sid}", headers=env.headers).json()["equipment"] is None
    assert env.client.get(f"/v1/sessions/{sid}/equipment/suggestions", headers=env.other()).status_code == 404


def test_delete_equipment_detaches_diagnostics_and_removes_photo(make_env):
    env = make_env(make_analysis(T.RESOLVED, "Réglé", title="Ne vidange plus"))
    media = env.photo().json()["id"]
    eid = env.add(primary_media_id=media).json()["id"]
    sid = env.session(eid).json()["id"]
    env.turn(sid, {"kind": "description", "text": "ne vidange plus"})
    assert env.client.delete(f"/v1/equipment/{eid}", headers=env.headers).status_code == 204
    assert env.client.get(f"/v1/equipment/{eid}", headers=env.headers).status_code == 404
    session = env.client.get(f"/v1/sessions/{sid}", headers=env.headers).json()
    assert session["status"] == "resolved" and session["title"] == "Ne vidange plus"
    assert session["equipment"] is None  # détaché, pas supprimé
    assert env.client.get("/v1/sessions", headers=env.headers).json()[0]["equipment_id"] is None
    assert env.client.get(f"/v1/media/{media}/content", headers=env.headers).status_code == 404
    assert env.client.delete(f"/v1/equipment/{eid}", headers=env.headers).status_code == 404


def test_home_listing_uses_constant_query_count(make_env):
    from sqlalchemy import event
    from sqlalchemy.engine import Engine

    env = make_env()
    statements: list[str] = []

    def count(conn, cursor, statement, *args):
        statements.append(statement)

    def measure() -> int:
        statements.clear()
        env.client.get("/v1/home", headers=env.headers)
        return len(statements)

    for _ in range(3):
        env.add()
    event.listen(Engine, "before_cursor_execute", count)
    try:
        few = measure()
        for _ in range(9):
            env.add()
        many = measure()
    finally:
        event.remove(Engine, "before_cursor_execute", count)
    assert many == few  # 12 équipements coûtent autant de requêtes que 3 (pas de N+1)


def test_abandoned_temporary_photo_is_deleted_immediately(make_env):
    env = make_env()
    media = env.photo().json()["id"]
    other = env.other()
    assert env.client.delete(f"/v1/equipment/photo/{media}", headers=other).status_code == 404  # pas à autrui
    assert env.client.delete(f"/v1/equipment/photo/{media}", headers=env.headers).status_code == 204
    assert env.client.get(f"/v1/media/{media}/content", headers=env.headers).status_code == 404
    assert env.client.delete(f"/v1/equipment/photo/{media}", headers=env.headers).status_code == 404


def test_discard_refuses_a_photo_in_use_or_a_session_media(make_env):
    env = make_env()
    media = env.photo().json()["id"]
    env.add(primary_media_id=media)
    assert env.client.delete(f"/v1/equipment/photo/{media}", headers=env.headers).status_code == 404
    assert env.client.get(f"/v1/media/{media}/content", headers=env.headers).status_code == 200  # intacte
    sid = env.session().json()["id"]
    sm = env.client.post(f"/v1/sessions/{sid}/media", files={"file": ("p.jpg", jpeg_bytes(), "image/jpeg")},
                         headers=env.headers).json()["id"]
    assert env.client.delete(f"/v1/equipment/photo/{sm}", headers=env.headers).status_code == 404
