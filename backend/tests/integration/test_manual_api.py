import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text

from app.ai.provider import AIProviderError
from app.api.deps import get_ai_provider, get_diagnostic_service, get_pdf_fetcher, get_storage
from app.domain.diagnosis import ManualCandidate
from app.domain.diagnosis import NextActionType as T
from app.main import create_app
from app.manuals.fetcher import FetchError
from app.media.storage import LocalMediaStorage
from app.services.diagnostic_service import DiagnosticService
from tests.helpers import ScriptedProvider, make_analysis, make_pdf, new_install_id

pytestmark = pytest.mark.integration

URL = "https://www.bosch-home.com/manuals/sms46gi01e.pdf"
BODY = "Texte de la notice d'utilisation de l'appareil. " * 12


def notice(model="SMS46GI01E"):
    return make_pdf([
        f"NOTICE D'UTILISATION\nLave-vaisselle Bosch {model}\n{BODY}",
        f"SECURITE\nDebranchez l'appareil avant tout entretien. {BODY}",
        "CODES ERREUR\nE15 : fuite detectee. Fermez le robinet d'arrivee d'eau et videz le bac de securite.\n"
        + f"E24 : vidange impossible, nettoyez le filtre. {BODY}",
    ])


class FakeFetcher:
    def __init__(self):
        self.files: dict[str, bytes | Exception] = {}
        self.calls: list[tuple[str, str]] = []

    def fetch(self, url, brand):
        self.calls.append((url, brand))
        result = self.files[url]
        if isinstance(result, Exception):
            raise result
        return result


class Env:
    def __init__(self, client, provider, fetcher, headers, storage):
        self.client, self.provider, self.fetcher, self.headers, self.storage = client, provider, fetcher, headers, storage

    def equipment(self, brand="Bosch", model="SMS46GI01E", headers=None):
        body = {"equipment_type": "dishwasher", "room_type": "kitchen", "brand": brand, "model": model}
        return self.client.post("/v1/equipment", json=body, headers=headers or self.headers).json()["id"]

    def search(self, eid, headers=None):
        return self.client.post(f"/v1/equipment/{eid}/manual/search", headers=headers or self.headers)

    def detail(self, eid):
        return self.client.get(f"/v1/equipment/{eid}", headers=self.headers).json()

    def stage(self, pdf=None, url=URL, title="Notice"):
        self.provider.manual_candidates = [ManualCandidate(url=url, title=title)]
        self.fetcher.files[url] = pdf if pdf is not None else notice()


@pytest.fixture
def make_env(clean_db, tmp_path):
    def _make(*analyses):
        provider, fetcher = ScriptedProvider(*analyses), FakeFetcher()
        app = create_app()
        storage = LocalMediaStorage(tmp_path)
        app.dependency_overrides[get_diagnostic_service] = lambda: DiagnosticService(provider)
        app.dependency_overrides[get_ai_provider] = lambda: provider
        app.dependency_overrides[get_pdf_fetcher] = lambda: fetcher
        app.dependency_overrides[get_storage] = lambda: storage
        return Env(TestClient(app), provider, fetcher, {"X-Nalvium-Install-Id": new_install_id()}, storage)

    return _make


def test_equipment_without_reference_still_works_and_search_needs_a_reference(make_env):
    env = make_env()
    eid = env.equipment(model=None)
    assert env.detail(eid)["manual"] is None
    r = env.search(eid)
    assert r.status_code == 409 and r.json()["detail"] == "reference_required"
    assert env.provider.find_manual_calls == []  # rien n'est cherché sans référence
    no_brand = env.equipment(brand=None, model="X123")
    assert env.search(no_brand).status_code == 409


def test_exact_official_manual_is_fetched_stored_privately_and_indexed(make_env, engine):
    env = make_env()
    eid = env.equipment()
    env.stage()
    r = env.search(eid)
    assert r.status_code == 200
    body = r.json()
    assert body["outcome"] == "found"
    m = body["manual"]
    assert m["status"] == "available" and m["source_is_official"] is True and m["match_level"] == "exact"
    assert m["page_count"] == 3 and m["source_domain"] == "www.bosch-home.com" and m["file_size"] > 500
    assert m["manufacturer"] == "Bosch" and m["model_reference"] == "SMS46GI01E" and m["source_url"] == URL
    assert env.detail(eid)["manual"]["status"] == "available"
    with engine.connect() as c:
        assert c.execute(text("SELECT count(*) FROM document_chunks")).scalar() >= 3
        key, checksum = c.execute(text("SELECT storage_key, checksum FROM equipment_documents")).one()
    assert len(checksum) == 64 and (env.storage._path(key)).read_bytes().startswith(b"%PDF")
    # une recherche de notice n'est pas un diagnostic
    assert env.client.get("/v1/sessions", headers=env.headers).json() == []


def test_search_sends_only_brand_and_reference(make_env):
    env = make_env()
    eid = env.equipment()
    env.stage()
    env.search(eid)
    assert env.provider.find_manual_calls == [("Bosch", "SMS46GI01E")]
    assert env.fetcher.calls == [(URL, "Bosch")]  # le fetcher ne reçoit ni identité ni session


def test_page_text_and_private_file_with_ownership(make_env):
    env = make_env()
    eid = env.equipment()
    env.stage()
    env.search(eid)
    page = env.client.get(f"/v1/equipment/{eid}/manual/pages/3", headers=env.headers).json()
    assert page["page"] == 3 and page["page_count"] == 3 and "E15" in page["text"]
    assert env.client.get(f"/v1/equipment/{eid}/manual/pages/9", headers=env.headers).status_code == 404
    pdf = env.client.get(f"/v1/equipment/{eid}/manual/file", headers=env.headers)
    assert pdf.status_code == 200 and pdf.content.startswith(b"%PDF") and "no-store" in pdf.headers["cache-control"]
    other = {"X-Nalvium-Install-Id": new_install_id()}
    for path in ("manual/file", "manual/pages/1"):
        assert env.client.get(f"/v1/equipment/{eid}/{path}", headers=other).status_code == 404
        assert env.client.get(f"/v1/equipment/{eid}/{path}").status_code == 401
    assert env.search(eid, headers=other).status_code == 404
    assert env.client.post(f"/v1/equipment/{eid}/manual/confirm", headers=other).status_code == 404
    assert env.client.delete(f"/v1/equipment/{eid}/manual", headers=other).status_code == 404


def test_wrong_model_is_refused(make_env):
    env = make_env()
    eid = env.equipment()
    env.stage(pdf=notice("WAT28400FF"))
    body = env.search(eid).json()
    assert body["outcome"] == "not_found" and body["manual"]["status"] == "not_found"
    assert env.client.get(f"/v1/equipment/{eid}/manual/file", headers=env.headers).status_code == 404


def test_approximate_model_is_not_associated_silently(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?"))
    eid = env.equipment()
    env.stage(pdf=notice("SMS46GI01"))  # modèle voisin
    body = env.search(eid).json()
    assert body["outcome"] == "needs_confirmation" and body["manual"]["status"] == "needs_confirmation"
    assert body["manual"]["match_level"] == "approximate"
    # tant que ce n'est pas confirmé : inutilisable (pages, fichier, diagnostic)
    assert env.client.get(f"/v1/equipment/{eid}/manual/pages/1", headers=env.headers).status_code == 404
    sid = env.client.post("/v1/sessions", json={"equipment_id": eid}, headers=env.headers).json()["id"]
    env.client.post(f"/v1/sessions/{sid}/turn", json={"kind": "description", "text": "erreur E15"}, headers=env.headers)
    assert env.provider.contexts[0].manual is None
    # l'utilisateur confirme
    ok = env.client.post(f"/v1/equipment/{eid}/manual/confirm", headers=env.headers).json()
    assert ok["manual"]["status"] == "available" and ok["manual"]["match_level"] == "approximate"
    assert env.client.post(f"/v1/equipment/{eid}/manual/confirm", headers=env.headers).status_code == 404


def test_unofficial_source_is_never_downloaded(make_env):
    env = make_env()
    eid = env.equipment()
    env.provider.manual_candidates = [ManualCandidate(url="https://manuals-for-all.example/bosch.pdf", title="x")]
    env.fetcher.files["https://manuals-for-all.example/bosch.pdf"] = FetchError("source_not_official")
    assert env.search(eid).json()["outcome"] == "not_found"


def test_invalid_pdf_is_refused_and_download_errors_are_reported(make_env):
    env = make_env()
    eid = env.equipment()
    env.stage(pdf=b"%PDF-1.4 corrompu")
    assert env.search(eid).json()["outcome"] == "not_found"
    env.stage(pdf=FetchError("network_error"))
    body = env.search(eid).json()
    assert body["outcome"] == "error" and body["manual"]["error_code"] == "download_failed"
    env.provider.manual_candidates = []
    assert env.search(eid).json()["outcome"] == "not_found"  # honnête : « notice exacte introuvable »


def test_provider_failure_is_an_error_and_never_destroys_an_existing_manual(make_env):
    env = make_env()
    eid = env.equipment()
    env.provider.manual_candidates = AIProviderError("down")
    assert env.search(eid).json()["outcome"] == "error"
    env.stage()
    assert env.search(eid).json()["outcome"] == "found"
    env.provider.manual_candidates = AIProviderError("down")
    again = env.search(eid).json()
    assert again["outcome"] == "kept" and again["manual"]["status"] == "available"


def test_update_with_same_file_is_up_to_date(make_env):
    env = make_env()
    eid = env.equipment()
    env.stage()
    env.search(eid)
    assert env.search(eid).json()["outcome"] == "up_to_date"


def test_changing_brand_or_model_drops_the_manual(make_env, engine):
    env = make_env()
    eid = env.equipment()
    env.stage()
    env.search(eid)
    env.client.patch(f"/v1/equipment/{eid}", json={"room_type": "bathroom"}, headers=env.headers)
    assert env.detail(eid)["manual"]["status"] == "available"  # pièce modifiée : la notice reste
    env.client.patch(f"/v1/equipment/{eid}", json={"model": "SMS99ZZ99"}, headers=env.headers)
    assert env.detail(eid)["manual"] is None
    with engine.connect() as c:
        assert c.execute(text("SELECT count(*) FROM equipment_documents")).scalar() == 0


def test_deleting_equipment_deletes_document_chunks_and_file(make_env, engine):
    env = make_env()
    eid = env.equipment()
    env.stage()
    env.search(eid)
    with engine.connect() as c:
        key = c.execute(text("SELECT storage_key FROM equipment_documents")).scalar()
    assert env.storage._path(key).exists()
    assert env.client.delete(f"/v1/equipment/{eid}", headers=env.headers).status_code == 204
    assert not env.storage._path(key).exists()
    with engine.connect() as c:
        assert c.execute(text("SELECT count(*) FROM equipment_documents")).scalar() == 0
        assert c.execute(text("SELECT count(*) FROM document_chunks")).scalar() == 0


def test_deleting_the_manual_only(make_env):
    env = make_env()
    eid = env.equipment()
    env.stage()
    env.search(eid)
    assert env.client.delete(f"/v1/equipment/{eid}/manual", headers=env.headers).status_code == 204
    assert env.detail(eid)["manual"] is None
    assert env.client.get(f"/v1/equipment/{eid}", headers=env.headers).status_code == 200


# ---- diagnostic ------------------------------------------------------------------
def start(env, eid, text_="Mon lave-vaisselle affiche E15"):
    sid = env.client.post("/v1/sessions", json={"equipment_id": eid}, headers=env.headers).json()["id"]
    r = env.client.post(f"/v1/sessions/{sid}/turn", json={"kind": "description", "text": text_}, headers=env.headers)
    return sid, r


def test_diagnostic_automatically_searches_the_manual_and_cites_real_pages(make_env):
    env = make_env(make_analysis(T.INSTRUCTION, "Fermez le robinet d'arrivée d'eau.", manual_pages_used=[3],
                                 choices=["C'est fait", "Je n'y arrive pas", "Ce n'est pas ce que je vois"]))
    eid = env.equipment()
    env.stage()
    env.search(eid)
    _, r = start(env, eid)
    ctx = env.provider.contexts[0]
    assert ctx.manual is not None and ctx.manual.exact and ctx.manual.manufacturer == "Bosch"
    assert ctx.manual.excerpts[0].page == 3 and "E15" in ctx.manual.excerpts[0].text
    assert ctx.manual.excerpts[0].section == "CODES ERREUR"
    assert len(ctx.manual.excerpts) <= 4
    assert r.json()["next"]["manual"] == {"manufacturer": "Bosch", "pages": [3]}
    assert r.json()["next"]["action_type"] == "INSTRUCTION"  # parcours Nalvium inchangé
    from app.ai.openai_provider import build_input

    sent = build_input(ctx)[0]["content"][0]["text"]
    assert "Notice constructeur : document EXACT" in sent and "[page 3 — CODES ERREUR]" in sent


def test_no_citation_when_the_answer_did_not_use_the_manual(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?", manual_pages_used=[]))
    eid = env.equipment()
    env.stage()
    env.search(eid)
    _, r = start(env, eid)
    assert env.provider.contexts[0].manual is not None  # extraits fournis…
    assert r.json()["next"]["manual"] is None  # …mais pas utilisés : jamais « d'après la notice »


def test_citation_of_a_page_that_was_never_provided_is_dropped(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?", manual_pages_used=[99, 3]))
    eid = env.equipment()
    env.stage()
    env.search(eid)
    _, r = start(env, eid)
    assert r.json()["next"]["manual"]["pages"] == [3]  # 99 n'a jamais été fourni


def test_diagnostic_without_manual_or_without_relevant_passage(make_env):
    env = make_env(make_analysis(T.ASK_QUESTION, "Q ?", manual_pages_used=[2]),
                   make_analysis(T.ASK_QUESTION, "Q ?", manual_pages_used=[2]))
    eid = env.equipment()
    _, r = start(env, eid)  # équipement sans notice
    assert env.provider.contexts[0].manual is None and r.json()["next"]["manual"] is None
    env.stage()
    env.search(eid)
    _, r = start(env, eid, "bruit bizarre quartz zzzz")  # aucun passage pertinent
    assert env.provider.contexts[1].manual is None and r.json()["next"]["manual"] is None


def test_safety_engine_comes_first_even_with_a_manual(make_env):
    env = make_env(make_analysis(T.INSTRUCTION, "Rebranchez l'appareil.", manual_pages_used=[2]))
    eid = env.equipment()
    env.stage()
    env.search(eid)
    _, r = start(env, eid, "J'ai une odeur de gaz près du lave-vaisselle, erreur E15")
    body = r.json()
    assert body["next"]["action_type"] == "SAFETY_STOP" and body["status"] == "stopped"
    assert env.provider.contexts == []  # le Safety pré-contrôle bloque avant l'IA ; la notice ne le contourne pas
    assert body["next"]["manual"] is None


def test_manual_does_not_bypass_post_ai_safety(make_env):
    unsafe = make_analysis(T.INSTRUCTION, "Ouvrez le tableau électrique et touchez les fils nus.",
                           manual_pages_used=[2], risk=__import__("app.domain.diagnosis", fromlist=["x"]).RiskLevel.LOW)
    env = make_env(unsafe)
    eid = env.equipment()
    env.stage()
    env.search(eid)
    _, r = start(env, eid, "erreur E15")
    assert r.json()["next"]["action_type"] == "SAFETY_STOP"


def test_manual_search_does_not_touch_sessions_or_counters(make_env, engine):
    env = make_env()
    eid = env.equipment()
    env.stage()
    env.search(eid)
    with engine.connect() as c:
        assert c.execute(text("SELECT count(*) FROM diagnostic_sessions")).scalar() == 0


def test_safety_stop_is_never_presented_as_coming_from_the_manual(make_env):
    from app.domain.diagnosis import RiskLevel

    stop = make_analysis(T.SAFETY_STOP, "Coupez l'alimentation.", risk=RiskLevel.EMERGENCY, diy=False,
                         manual_pages_used=[3])
    env = make_env(stop)
    eid = env.equipment()
    env.stage()
    env.search(eid)
    _, r = start(env, eid)
    assert r.json()["next"]["action_type"] == "SAFETY_STOP" and r.json()["next"]["manual"] is None
