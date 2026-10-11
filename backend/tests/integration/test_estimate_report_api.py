"""Estimation indicative conservée sur la session, signalement d'un résultat, limite quotidienne de diagnostics."""
import pytest
from sqlalchemy import text

from app.api.deps import get_diagnostic_service, get_storage
from app.config import get_settings
from app.domain.diagnosis import Difficulty, EstimatePart, RepairEstimate, RiskLevel
from app.domain.diagnosis import NextActionType as T
from app.main import create_app
from app.media.storage import LocalMediaStorage
from app.services.diagnostic_service import DiagnosticService
from tests.helpers import ScriptedProvider, make_analysis, new_install_id
from tests.integration.test_sessions_api import Env

pytestmark = pytest.mark.integration

@pytest.fixture
def make_env(clean_db, tmp_path):
    def _make(*analyses):
        from fastapi.testclient import TestClient

        provider = ScriptedProvider(*analyses)
        app = create_app()
        storage = LocalMediaStorage(tmp_path)
        app.dependency_overrides[get_diagnostic_service] = lambda: DiagnosticService(provider)
        app.dependency_overrides[get_storage] = lambda: storage
        return Env(TestClient(app), provider, {"X-Nalvium-Install-Id": new_install_id()}, storage)

    return _make


EST = RepairEstimate(
    diy_feasibility=8, difficulty=Difficulty.EASY, duration_minutes=20, diy_cost_min=5, diy_cost_max=12,
    pro_cost_min=120, pro_cost_max=180, parts=[EstimatePart(name="Joint fibre 15×21", approx_eur=2)],
)


def test_estimate_is_exposed_and_kept_across_turns(make_env):
    env = make_env(
        make_analysis(T.ASK_QUESTION, "Où coule l'eau ?", choices=["Oui", "Non"], estimate=EST),
        make_analysis(T.INSTRUCTION, "Serrez l'écrou à la main.", choices=["C'est fait"]),  # sans estimation
    )
    sid = env.create()
    body = env.turn(sid, {"kind": "description", "text": "Fuite sous l'évier"}).json()
    assert body["estimate"]["diy_feasibility"] == 8
    assert body["estimate"]["parts"] == [{"name": "Joint fibre 15×21", "approx_eur": 2}]
    body = env.turn(sid, {"kind": "answer", "text": "Oui"}).json()
    assert body["estimate"]["pro_cost_max"] == 180  # la dernière estimation connue reste affichée
    listed = env.client.get("/v1/sessions", headers=env.headers).json()
    assert listed[0]["estimate"]["diy_cost_min"] == 5


def test_estimate_then_user_safety_stop_removes_the_estimate(make_env):
    # Tour 1 : estimation ; tour 2 : l'utilisateur signale une odeur de gaz → STOP avant l'IA, plus aucun chiffrage.
    env = make_env(make_analysis(T.ASK_QUESTION, "Où coule l'eau ?", choices=["Oui"], estimate=EST))
    sid = env.create()
    assert env.turn(sid, {"kind": "description", "text": "Fuite sous l'évier"}).json()["estimate"] is not None
    body = env.turn(sid, {"kind": "answer", "text": "Il y a une odeur de gaz dans la cuisine"}).json()
    assert body["status"] == "stopped" and body["next"]["action_type"] == "SAFETY_STOP"
    assert body["estimate"] is None
    assert env.client.get(f"/v1/sessions/{sid}", headers=env.headers).json()["estimate"] is None
    assert env.client.get("/v1/sessions", headers=env.headers).json()[0]["estimate"] is None


def test_estimate_then_ai_safety_stop_with_estimate_never_shows_a_cost(make_env):
    # Même si l'IA joint (à tort) une estimation à son propre arrêt de sécurité, elle n'est jamais exposée.
    env = make_env(
        make_analysis(T.ASK_QUESTION, "Où coule l'eau ?", choices=["Oui"], estimate=EST),
        make_analysis(T.SAFETY_STOP, "Arrêtez : fils dénudés.", risk=RiskLevel.EMERGENCY, diy=False, estimate=EST),
    )
    sid = env.create()
    env.turn(sid, {"kind": "description", "text": "Fuite sous l'évier"})
    body = env.turn(sid, {"kind": "answer", "text": "Oui"}).json()
    assert body["status"] == "stopped" and body["estimate"] is None


def test_no_estimate_by_default(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "Où coule l'eau ?", choices=["Oui"]))
    sid = env.create()
    assert env.turn(sid, {"kind": "description", "text": "Fuite"}).json()["estimate"] is None


def test_report_result_is_owned_and_deleted_with_data(make_env, clean_db):
    env = make_env(make_analysis(T.ASK_QUESTION, "Où coule l'eau ?", choices=["Oui"]))
    sid = env.create()
    env.turn(sid, {"kind": "description", "text": "Fuite"})
    r = env.client.post(f"/v1/sessions/{sid}/report", json={"reason": "wrong", "details": " pas ça "}, headers=env.headers)
    assert r.status_code == 201
    other = {"X-Nalvium-Install-Id": new_install_id()}
    assert env.client.post(f"/v1/sessions/{sid}/report", json={"reason": "wrong"}, headers=other).status_code == 404
    assert env.client.post(f"/v1/sessions/{sid}/report", json={"reason": "spam"}, headers=env.headers).status_code == 422
    with clean_db.begin() as c:
        assert c.execute(text("SELECT reason, details FROM result_reports")).all() == [("wrong", "pas ça")]
    assert env.client.delete("/v1/me", headers=env.headers).status_code in (200, 204)
    with clean_db.begin() as c:
        assert c.execute(text("SELECT count(*) FROM result_reports")).scalar_one() == 0


def test_daily_session_limit(make_env, monkeypatch):
    monkeypatch.setattr(get_settings(), "daily_session_limit", 2)
    env = make_env()
    env.create()
    env.create()
    r = env.client.post("/v1/sessions", headers=env.headers)
    assert r.status_code == 429 and r.json()["detail"] == "daily_limit"
    # Un autre utilisateur n'est pas concerné.
    assert env.client.post("/v1/sessions", headers={"X-Nalvium-Install-Id": new_install_id()}).status_code == 201


def test_turn_limit_concludes_without_ai_toward_a_professional(make_env, monkeypatch):
    monkeypatch.setattr(get_settings(), "max_session_turns", 2)
    env = make_env(
        make_analysis(T.ASK_QUESTION, "Où coule l'eau ?", choices=["Oui"], estimate=EST),
        make_analysis(T.ASK_QUESTION, "Depuis quand ?", choices=["Hier"]),
    )
    sid = env.create()
    env.turn(sid, {"kind": "description", "text": "Fuite sous l'évier"})
    env.turn(sid, {"kind": "answer", "text": "Oui"})
    r = env.turn(sid, {"kind": "answer", "text": "Hier"})
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "referred" and body["next"]["action_type"] == "RECOMMEND_PROFESSIONAL"
    assert "professionnel" in body["next"]["message"]
    assert body["title"] == "Fuite sous l'évier" and body["estimate"]["pro_cost_max"] == 180  # contexte conservé
    assert len(env.provider.contexts) == 2  # aucun appel IA au-delà de la limite
    # Session terminée : les tours suivants n'appellent plus rien.
    assert env.turn(sid, {"kind": "answer", "text": "Encore"}).json()["status"] == "referred"
    assert len(env.provider.contexts) == 2


def test_turn_limit_never_hides_a_safety_stop(make_env, monkeypatch):
    monkeypatch.setattr(get_settings(), "max_session_turns", 1)
    env = make_env(make_analysis(T.ASK_QUESTION, "Où coule l'eau ?", choices=["Oui"], estimate=EST))
    sid = env.create()
    env.turn(sid, {"kind": "description", "text": "Fuite sous l'évier"})
    body = env.turn(sid, {"kind": "answer", "text": "Maintenant il y a une odeur de gaz"}).json()
    assert body["status"] == "stopped" and body["next"]["action_type"] == "SAFETY_STOP"
    assert body["estimate"] is None and len(env.provider.contexts) == 1
