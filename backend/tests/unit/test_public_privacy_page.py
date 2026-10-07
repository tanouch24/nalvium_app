from pathlib import Path

from fastapi.testclient import TestClient

from app.api.routes.legal import render_markdown
from app.main import app

ROOT = Path(__file__).resolve().parents[3]


def _html() -> str:
    r = TestClient(app).get("/privacy")
    assert r.status_code == 200 and r.headers["content-type"].startswith("text/html")
    return r.text


def test_public_without_auth_and_mobile_ready():
    html = _html()
    assert 'name="viewport"' in html and "Politique de confidentialité — Nalvium" in html


def test_covers_required_topics_and_identity():
    html = _html()
    for needed in ["509 817 649 00080", "NB CONSULTING", "10 rue d&#x27;Hanoï, 69100 Villeurbanne", "contact@nalvium.com",
                   "2026-10", "octobre 2026", "OpenAI", "Telegram", "Railway", "EU West", "AdMob", "RGPD", "CNIL",
                   "Communauté", "identifiant anonyme", "notices"]:
        assert needed in html, needed


def test_no_false_promises():
    low = _html().lower()
    for bad in ["avocat", "juriste", "supprimées automatiquement", "exclusivement dans l'union", "exclusivement dans l&#x27;union"]:
        assert bad not in low
    assert "ne sont pas envoyées à telegram" in low


def test_privacy_md_in_sync_with_page():
    assert (ROOT / "docs" / "PRIVACY.md").read_text(encoding="utf-8") == render_markdown() + "\n"


def test_dart_and_page_agree_on_telegram_and_version():
    dart = (ROOT / "app/lib/features/settings/legal_texts.dart").read_text(encoding="utf-8")
    assert "kLegalVersion = '2026-10'" in dart
    assert "ne sont PAS envoyées à Telegram" in dart
