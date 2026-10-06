"""Notification interne à chaque nouvelle demande d'intervention.

La base de données reste la source de vérité : une panne de notification n'empêche JAMAIS la soumission.
Rien de personnel dans les journaux (ni téléphone, ni e-mail, ni texte du message, ni jeton)."""
import logging
from dataclasses import dataclass
from typing import Protocol

import httpx

log = logging.getLogger("nalvium.notify")

# httpx journalise chaque requête avec son URL COMPLÈTE : pour Telegram elle contient le jeton. On coupe ce niveau.
logging.getLogger("httpx").setLevel(logging.WARNING)
logging.getLogger("httpcore").setLevel(logging.WARNING)

CATEGORY_LABELS = {
    "plumbing": "Plomberie", "appliance": "Électroménager", "handyman": "Bricolage",
    "electrical": "Électricité", "other": "Autre",
}
AVAILABILITY_LABELS = {
    "asap": "Dès que possible", "today": "Aujourd'hui", "tomorrow": "Demain", "this_week": "Cette semaine",
    "custom": "Créneau choisi",
}
WINDOW_LABELS = {"morning": "matin", "afternoon": "après-midi", "evening": "soir"}


@dataclass(frozen=True)
class NotifyResult:
    status: str  # sent | failed | not_configured
    error_code: str | None = None


class ServiceRequestNotifier(Protocol):
    """Contrat : ne lève jamais ; retourne le résultat."""

    configured: bool

    def notify(self, text: str) -> NotifyResult: ...


class NotConfiguredNotifier:
    configured = False

    def notify(self, text: str) -> NotifyResult:
        return NotifyResult("not_configured")


class TelegramServiceRequestNotifier:
    """Envoi d'un message texte via l'API Bot. Jeton et identifiant de conversation viennent UNIQUEMENT de
    l'environnement serveur. Aucun média n'est envoyé."""

    configured = True

    def __init__(self, token: str, chat_id: str, timeout_s: float = 5.0, transport: httpx.BaseTransport | None = None):
        self._token, self._chat_id, self._timeout = token, chat_id, timeout_s
        self._transport = transport

    def notify(self, text: str) -> NotifyResult:
        url = f"https://api.telegram.org/bot{self._token}/sendMessage"
        try:
            with httpx.Client(timeout=self._timeout, transport=self._transport) as client:
                resp = client.post(url, json={"chat_id": self._chat_id, "text": text, "disable_web_page_preview": True})
        except httpx.TimeoutException:
            return NotifyResult("failed", "timeout")
        except httpx.HTTPError as exc:
            # Jamais str(exc) : il peut contenir l'URL, donc le jeton.
            return NotifyResult("failed", f"network_{type(exc).__name__}")
        if resp.status_code != 200:
            return NotifyResult("failed", f"http_{resp.status_code}")
        return NotifyResult("sent")


def build_notifier(token: str | None, chat_id: str | None, timeout_s: float = 5.0) -> ServiceRequestNotifier:
    if token and chat_id:
        return TelegramServiceRequestNotifier(token, chat_id, timeout_s)
    return NotConfiguredNotifier()


def _first_name_phone(contact: dict) -> str:
    return " — ".join(x for x in (contact.get("first_name"), contact.get("phone")) if x)


def build_message(payload: dict, short_id: str, photos: int, videos: int) -> str:
    """Message court construit UNIQUEMENT à partir du handoff consenti (jamais de champ interne)."""
    ctx = payload.get("context") or {}
    consent = set((payload.get("consent") or {}).get("categories") or [])
    problem, contact, avail = payload["problem"], payload["contact"], payload["availability"]
    lines = ["Nouvelle demande Nalvium", "", f"#REQ-{short_id}"]
    head = " · ".join(x for x in (CATEGORY_LABELS.get(problem.get("category") or "", None), _one_line(problem.get("summary"), 80)) if x)
    lines.append(head)
    lines += ["", f"Ville : {contact.get('city')} {contact.get('postal_code')}", f"Contact : {_first_name_phone(contact)}"]
    when = AVAILABILITY_LABELS.get(avail.get("type") or "", "")
    if avail.get("type") == "custom":
        when = " ".join(x for x in (when, avail.get("date"), WINDOW_LABELS.get(avail.get("window") or "")) if x)
    lines.append(f"Disponibilité : {when}")
    eq = ctx.get("equipment") if "equipment" in consent else None
    if eq:
        lines += ["", "Équipement :", " ".join(x for x in (eq.get("label"), eq.get("brand"), eq.get("model")) if x)]
    lines += ["", "Origine :", "Diagnostic Nalvium" if ctx.get("source") == "diagnostic" else "Demande directe"]
    if "diagnostic_context" in consent:
        noticed = [_one_line(o, 90) for o in (ctx.get("observations") or [])[:3]]
        if ctx.get("hypotheses"):
            noticed.append("Hypothèse (non confirmée) : " + _one_line(ctx["hypotheses"][0].get("label"), 80))
        if noticed:
            lines += ["", "Nalvium a constaté :", *[f"- {n}" for n in noticed]]
        tried = ctx.get("actions_tried") or []
        if tried:
            lines.append(f"Déjà essayé : {len(tried)} action(s)")
        reason = ctx.get("safety_stop_reason") or ctx.get("professional_reason")
        if ctx.get("safety_stop_reason"):
            lines += ["", "Sécurité :", _one_line(reason, 220)]
        elif ctx.get("professional_reason"):
            lines += ["", "Intervention recommandée :", _one_line(reason, 220)]
        manual = ctx.get("manual")
        if manual:
            lines.append("Notice constructeur consultée" + (f" (pages {', '.join(map(str, manual.get('pages') or []))})" if manual.get("pages") else ""))
    lines += ["", f"Médias autorisés : {photos} photo / {videos} vidéo"]
    return "\n".join(lines)


def _one_line(text: str | None, limit: int) -> str:
    text = " ".join((text or "").split())
    return text if len(text) <= limit else text[: limit - 1] + "…"
