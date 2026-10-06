import logging

import httpx

from app.notifications.service_requests import (
    NotConfiguredNotifier,
    TelegramServiceRequestNotifier,
    build_message,
    build_notifier,
)

TOKEN = "123456:SECRET-TOKEN-VALUE"


def notifier(handler, timeout=1.0):
    return TelegramServiceRequestNotifier(TOKEN, "-100999", timeout, transport=httpx.MockTransport(handler))


def test_not_configured_without_variables():
    assert isinstance(build_notifier(None, None), NotConfiguredNotifier)
    assert isinstance(build_notifier("tok", None), NotConfiguredNotifier)
    assert isinstance(build_notifier("tok", "chat"), TelegramServiceRequestNotifier)
    assert NotConfiguredNotifier().notify("x").status == "not_configured"


def test_success_sends_plain_text_to_the_configured_chat():
    seen = {}

    def handler(req):
        seen["url"], seen["body"] = str(req.url), req.read().decode()
        return httpx.Response(200, json={"ok": True})

    assert notifier(handler).notify("Bonjour").status == "sent"
    assert seen["url"] == f"https://api.telegram.org/bot{TOKEN}/sendMessage"
    assert '"chat_id":"-100999"' in seen["body"].replace(" ", "") and "Bonjour" in seen["body"]
    assert "parse_mode" not in seen["body"]


def test_http_error_timeout_and_network_failures_are_results_not_exceptions(caplog):
    caplog.set_level(logging.DEBUG)
    assert notifier(lambda r: httpx.Response(500)).notify("x") == notifier(lambda r: httpx.Response(500)).notify("x")
    assert notifier(lambda r: httpx.Response(401)).notify("x").error_code == "http_401"

    def timeout(req):
        raise httpx.ReadTimeout("boom", request=req)

    assert notifier(timeout).notify("x").error_code == "timeout"

    def down(req):
        raise httpx.ConnectError(f"cannot reach {req.url}", request=req)

    r = notifier(down).notify("x")
    assert r.status == "failed" and r.error_code == "network_ConnectError"
    assert TOKEN not in str(r) and "SECRET" not in r.error_code and TOKEN not in caplog.text


PAYLOAD = {
    "request_id": "6f1f2d0c-0000-0000-0000-000000000000",
    "submitted_at": "2026-10-06T08:00:00+00:00",
    "problem": {"category": "plumbing", "summary": "Fuite sous évier\nsur le siphon"},
    "context": {
        "source": "diagnostic", "equipment": {"label": "Lave-vaisselle", "brand": "Bosch", "model": "SMV4HVX31E"},
        "observations": ["Eau près du siphon", "Joint visible", "Rien d'autre", "Quatrième"],
        "hypotheses": [{"label": "Joint usé", "note": "x"}],
        "actions_tried": [{"instruction": "a", "result": "fait"}],
        "safety_stop_reason": "Arrêtez-vous ici. Eau et électricité.",
        "manual": {"consulted": True, "pages": [43]},
        "reasoning": "SECRET-REASONING", "prompt": "SECRET-PROMPT",
    },
    "contact": {"first_name": "Camille", "phone": "+33612345678", "email": "c@example.fr", "city": "Lyon", "postal_code": "69003"},
    "availability": {"type": "asap", "date": None, "window": None},
    "media": [{"media_id": "11111111-1111-1111-1111-111111111111"}],
    "consent": {"version": "2026-10", "at": "x", "categories": ["problem", "contact", "availability", "diagnostic_context", "equipment", "media"]},
}


def test_message_is_short_and_contains_only_consented_useful_data():
    text = build_message(PAYLOAD, "6F1F2D", 1, 0)
    for expected in ["Nouvelle demande Nalvium", "#REQ-6F1F2D", "Plomberie · Fuite sous évier sur le siphon", "Ville : Lyon 69003",
                     "Contact : Camille — +33612345678", "Disponibilité : Dès que possible", "Lave-vaisselle Bosch SMV4HVX31E",
                     "Diagnostic Nalvium", "Nalvium a constaté", "Eau près du siphon", "Hypothèse (non confirmée) : Joint usé",
                     "Sécurité :", "Eau et électricité", "Notice constructeur consultée (pages 43)", "Médias autorisés : 1 photo / 0 vidéo"]:
        assert expected in text, expected
    assert "Quatrième" not in text  # 3 observations au maximum
    for forbidden in ["SECRET", "11111111", "6f1f2d0c", "c@example.fr", "prompt", "reasoning", "confidence", "pdf"]:
        assert forbidden.lower() not in text.lower(), forbidden
    assert len(text) < 1200


def test_unconsented_categories_are_absent():
    p = {**PAYLOAD, "consent": {**PAYLOAD["consent"], "categories": ["problem", "contact", "availability"]}}
    text = build_message(p, "AAAAAA", 0, 0)
    for absent in ["Lave-vaisselle Bosch", "Nalvium a constaté", "Eau près du siphon", "Sécurité", "Joint usé", "Notice", "Équipement"]:
        assert absent not in text, absent
    assert "Médias autorisés : 0 photo / 0 vidéo" in text and "Ville : Lyon 69003" in text
