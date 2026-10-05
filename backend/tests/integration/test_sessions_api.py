import io

import pytest
from fastapi.testclient import TestClient
from PIL import Image

from app.ai.provider import AIProviderError, AIProviderNotConfigured
from app.api.deps import get_diagnostic_service, get_storage
from app.domain.diagnosis import NextActionType as T
from app.domain.diagnosis import RiskLevel, VerificationOutcome
from app.main import create_app
from app.media.storage import LocalMediaStorage
from app.services.diagnostic_service import DiagnosticService
from tests.helpers import ScriptedProvider, jpeg_bytes, make_analysis, new_install_id

pytestmark = pytest.mark.integration


class Env:
    def __init__(self, client, provider, headers, storage):
        self.client, self.provider, self.headers, self.storage = client, provider, headers, storage

    def create(self):
        r = self.client.post("/v1/sessions", headers=self.headers)
        assert r.status_code == 201
        return r.json()["id"]

    def upload(self, sid, raw=None, headers=None):
        raw = raw or jpeg_bytes()
        return self.client.post(
            f"/v1/sessions/{sid}/media",
            files={"file": ("p.jpg", raw, "image/jpeg")},
            headers=headers or self.headers,
        )

    def turn(self, sid, body=None):
        return self.client.post(f"/v1/sessions/{sid}/turn", json=body, headers=self.headers)


@pytest.fixture
def make_env(clean_db, tmp_path):
    def _make(*analyses):
        provider = ScriptedProvider(*analyses)
        app = create_app()
        storage = LocalMediaStorage(tmp_path)
        app.dependency_overrides[get_diagnostic_service] = lambda: DiagnosticService(provider)
        app.dependency_overrides[get_storage] = lambda: storage
        return Env(TestClient(app), provider, {"X-Nalvium-Install-Id": new_install_id()}, storage)

    return _make


def test_requires_install_id(make_env):
    env = make_env()
    assert env.client.post("/v1/sessions").status_code == 401
    assert env.client.post("/v1/sessions", headers={"X-Nalvium-Install-Id": "pas-un-uuid"}).status_code == 401


def test_create_session_and_empty_sessions_are_not_listed(make_env):
    env = make_env()
    sid = env.create()
    body = env.client.get(f"/v1/sessions/{sid}", headers=env.headers).json()
    assert body["status"] == "active" and body["messages"] == [] and body["next"] is None
    assert env.client.get("/v1/sessions", headers=env.headers).json() == []


def test_photo_upload_is_private_clean_and_owned(make_env):
    env = make_env()
    sid = env.create()
    exif = Image.Exif()
    exif[0x010F] = "SecretPhoneMaker"
    exif.get_ifd(0x8825)[2] = (48.0, 51.0, 24.0)
    r = env.upload(sid, jpeg_bytes(size=(3000, 2000), exif=exif.tobytes()))
    assert r.status_code == 201
    media_id = r.json()["id"]

    stored = env.client.get(f"/v1/media/{media_id}/content", headers=env.headers)
    assert stored.status_code == 200 and stored.headers["content-type"] == "image/jpeg"
    img = Image.open(io.BytesIO(stored.content))
    assert max(img.size) == 1600 and len(img.getexif()) == 0
    assert b"SecretPhoneMaker" not in stored.content

    # Un autre utilisateur ne voit ni la session ni le média ; sans en-tête : refusé.
    other = {"X-Nalvium-Install-Id": new_install_id()}
    assert env.client.get(f"/v1/media/{media_id}/content", headers=other).status_code == 404
    assert env.client.get(f"/v1/sessions/{sid}", headers=other).status_code == 404
    assert env.upload(sid, headers=other).status_code == 404
    assert env.client.get(f"/v1/media/{media_id}/content").status_code == 401


def test_upload_rejects_non_images(make_env):
    env = make_env()
    sid = env.create()
    assert env.upload(sid, b"hello").status_code == 422


def test_photo_flow_question_then_instruction_verification_resolved(make_env):
    env = make_env(
        make_analysis(T.ASK_QUESTION, "L'eau apparaît-elle uniquement quand vous ouvrez le robinet ?",
                      choices=["Oui", "Non", "Je ne sais pas"]),
        make_analysis(T.INSTRUCTION, "Fermez le robinet d'arrêt sous le lavabo.",
                      choices=["C'est fait", "Je n'y arrive pas", "Ce n'est pas ce que je vois"],
                      required_items=["Un torchon"]),
        make_analysis(T.VERIFICATION, "L'eau coule-t-elle encore ?", choices=["Non", "Oui", "Je ne sais pas"]),
        make_analysis(T.RESOLVED, "Le problème semble résolu.",
                      verification_outcome=VerificationOutcome.RESOLVED),
    )
    sid = env.create()
    media_id = env.upload(sid).json()["id"]

    r = env.turn(sid, {"kind": "photo", "media_id": media_id})
    assert r.status_code == 200
    body = r.json()
    assert body["next"]["action_type"] == "ASK_QUESTION"
    assert body["next"]["choices"] == ["Oui", "Non", "Je ne sais pas"]
    assert body["title"] == "Fuite sous l'évier" and body["category"] == "plumbing"
    assert body["pending_analysis"] is False and body["latest_media_id"] == media_id
    assert body["next"]["hypotheses"][0]["confidence"] == 0.6
    assert env.provider.contexts[0].photos[0].data  # la photo traitée est bien transmise à l'IA

    body = env.turn(sid, {"kind": "answer", "text": "Oui"}).json()
    assert body["next"]["action_type"] == "INSTRUCTION" and body["next"]["step_number"] == 1
    ctx = env.provider.contexts[1]
    assert any("Oui" in line for line in ctx.history)  # contexte précédent conservé

    body = env.turn(sid, {"kind": "action_result", "choice": "done"}).json()
    assert body["next"]["action_type"] == "VERIFICATION"
    assert "étape 1 (done)" in env.provider.contexts[2].completed_actions[0]

    body = env.turn(sid, {"kind": "answer", "text": "Non"}).json()
    assert body["next"]["action_type"] == "RESOLVED" and body["status"] == "resolved"
    assert env.provider.contexts[3].previous_outcomes == []
    # La vérification évaluée est mémorisée pour les tours suivants / l'historique.
    # Une session terminée n'appelle plus l'IA.
    again = env.turn(sid, {"kind": "answer", "text": "merci"}).json()
    assert again["status"] == "resolved" and len(env.provider.contexts) == 4


def test_request_photo_then_new_photo_carries_previous_context(make_env):
    env = make_env(
        make_analysis(T.REQUEST_PHOTO, "Montrez-moi la connexion sous le lavabo."),
        make_analysis(T.INSTRUCTION, "Fermez le robinet d'arrêt.", title="Fuite connexion"),
    )
    sid = env.create()
    m1 = env.upload(sid).json()["id"]
    assert env.turn(sid, {"kind": "photo", "media_id": m1}).json()["next"]["action_type"] == "REQUEST_PHOTO"
    m2 = env.upload(sid, jpeg_bytes(color=(200, 10, 10))).json()["id"]
    body = env.turn(sid, {"kind": "photo", "media_id": m2}).json()
    assert body["next"]["action_type"] == "INSTRUCTION" and body["latest_media_id"] == m2
    ctx = env.provider.contexts[1]
    assert len(ctx.photos) == 2
    assert any("Montrez-moi la connexion" in h for h in ctx.history)
    assert body["title"] == "Fuite connexion"  # une nouvelle analyse peut réviser la conclusion


def test_action_failure_and_mismatch_are_recorded_and_reevaluated(make_env):
    env = make_env(
        make_analysis(T.INSTRUCTION, "Fermez le robinet d'arrêt."),
        make_analysis(T.ASK_QUESTION, "Pouvez-vous décrire ce que vous voyez ?"),
    )
    sid = env.create()
    env.turn(sid, {"kind": "description", "text": "Mon évier fuit"})
    body = env.turn(sid, {"kind": "action_result", "choice": "mismatch"}).json()
    assert body["next"]["action_type"] == "ASK_QUESTION"
    assert "Ce n'est pas ce que je vois" in " ".join(env.provider.contexts[1].history)
    assert "étape 1 (mismatch)" in env.provider.contexts[1].completed_actions[0]


def test_text_flow(make_env):
    env = make_env(make_analysis(T.REQUEST_PHOTO, "Montrez-moi le robinet."))
    sid = env.create()
    body = env.turn(sid, {"kind": "description", "text": "Mon robinet goutte"}).json()
    assert body["next"]["action_type"] == "REQUEST_PHOTO"
    assert env.provider.contexts[0].description == "Mon robinet goutte"
    assert env.turn(sid, {"kind": "description", "text": "  "}).status_code in (422,)


def test_safety_stop_on_dangerous_text_never_calls_ai_and_is_final(make_env):
    env = make_env(make_analysis(T.INSTRUCTION, "Ouvrez le tableau"))
    sid = env.create()
    body = env.turn(sid, {"kind": "description", "text": "Ça sent le gaz dans la cuisine"}).json()
    assert body["next"]["action_type"] == "SAFETY_STOP"
    assert body["status"] == "stopped" and body["risk_level"] == "emergency"
    assert body["next"]["diy_allowed"] is False
    assert env.provider.contexts == []  # l'IA n'a pas été appelée

    # Après un STOP : plus d'IA, plus d'instruction, plus de photo.
    after = env.turn(sid, {"kind": "answer", "text": "Que dois-je faire pour réparer ?"}).json()
    assert after["next"]["action_type"] == "SAFETY_STOP" and env.provider.contexts == []
    assert env.upload(sid).status_code == 409


def test_ai_cannot_bypass_stop_via_dangerous_instruction_or_flags(make_env):
    env = make_env(
        make_analysis(T.INSTRUCTION, "Ouvrez le tableau électrique et coupez le disjoncteur"),
    )
    sid = env.create()
    body = env.turn(sid, {"kind": "description", "text": "Une lampe ne s'allume plus"}).json()
    assert body["next"]["action_type"] == "SAFETY_STOP" and body["status"] == "stopped"

    env2 = make_env(make_analysis(T.INSTRUCTION, "Continuez", risk=RiskLevel.EMERGENCY))
    sid2 = env2.create()
    assert env2.turn(sid2, {"kind": "description", "text": "bruit bizarre"}).json()["next"]["action_type"] == "SAFETY_STOP"


def test_danger_reported_in_a_later_turn_stops_the_session(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "D'où vient l'eau ?"), make_analysis(T.INSTRUCTION, "x"))
    sid = env.create()
    env.turn(sid, {"kind": "description", "text": "Mon évier fuit"})
    body = env.turn(sid, {"kind": "answer", "text": "L'eau touche la multiprise"}).json()
    assert body["next"]["action_type"] == "SAFETY_STOP" and len(env.provider.contexts) == 1


def test_recommend_professional_ends_session_as_referred(make_env):
    env = make_env(make_analysis(T.RECOMMEND_PROFESSIONAL, "Cette intervention nécessite un professionnel.", diy=False))
    sid = env.create()
    body = env.turn(sid, {"kind": "description", "text": "Mon lave-linge ne démarre plus"}).json()
    assert body["next"]["action_type"] == "RECOMMEND_PROFESSIONAL" and body["status"] == "referred"


def test_provider_unavailable_keeps_input_and_retry_works(make_env):
    env = make_env()

    class Failing:
        calls = 0

        async def analyze(self, ctx):
            Failing.calls += 1
            if Failing.calls == 1:
                raise AIProviderNotConfigured("no key")
            if Failing.calls == 2:
                raise AIProviderError("boom")
            return make_analysis(T.ASK_QUESTION, "Et maintenant ?")

    env.client.app.dependency_overrides[get_diagnostic_service] = lambda: DiagnosticService(Failing())
    sid = env.create()
    r = env.turn(sid, {"kind": "description", "text": "Mon robinet goutte"})
    assert r.status_code == 503 and r.json()["detail"] == "analysis_unavailable"

    state = env.client.get(f"/v1/sessions/{sid}", headers=env.headers).json()
    assert state["pending_analysis"] is True and len(state["messages"]) == 1  # entrée conservée

    assert env.turn(sid).status_code == 502  # retry sans corps, échec provider
    ok = env.turn(sid)  # retry réussi, sans dupliquer le message utilisateur
    assert ok.status_code == 200 and ok.json()["next"]["action_type"] == "ASK_QUESTION"
    assert [m["role"] for m in ok.json()["messages"]] == ["user", "nalvium"]
    assert env.turn(sid).json()["next"]["message"] == "Et maintenant ?"  # rien en attente : no-op


def test_resume_session_and_history(make_env):
    env = make_env(
        make_analysis(T.ASK_QUESTION, "Question ?", choices=["Oui", "Non"]),
        make_analysis(T.RESOLVED, "Résolu."),
    )
    sid_active = env.create()
    env.turn(sid_active, {"kind": "description", "text": "Un problème"})
    sid_done = env.create()
    env.turn(sid_done, {"kind": "description", "text": "Autre problème"})

    active = env.client.get("/v1/sessions?active=true", headers=env.headers).json()
    assert [s["id"] for s in active] == [sid_active]
    assert active[0]["current_state"] == "ASK_QUESTION" and active[0]["title"]
    allsessions = env.client.get("/v1/sessions", headers=env.headers).json()
    assert {s["id"] for s in allsessions} == {sid_active, sid_done}

    # « Redémarrage » : nouvelle app/client, même installation => même état.
    fresh = TestClient(env.client.app)
    state = fresh.get(f"/v1/sessions/{sid_active}", headers=env.headers).json()
    assert state["next"]["action_type"] == "ASK_QUESTION" and state["next"]["choices"] == ["Oui", "Non"]
    other = {"X-Nalvium-Install-Id": new_install_id()}
    assert fresh.get("/v1/sessions", headers=other).json() == []


def test_invalid_turn_inputs(make_env):
    env = make_env()
    sid = env.create()
    assert env.turn(sid, {"kind": "photo", "media_id": new_install_id()}).status_code == 422
    assert env.turn(sid, {"kind": "action_result", "choice": "nope"}).status_code == 422
    assert env.turn(sid, {"kind": "bogus"}).status_code == 422
