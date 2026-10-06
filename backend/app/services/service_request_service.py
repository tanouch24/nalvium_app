"""Demandes d'intervention : brouillon, contexte du diagnostic, médias CHOISIS, consentement, envoi, annulation.

V1 sans réseau de professionnels : l'envoi enregistre un lead qualifié (rien n'est transmis, aucun SMS/e-mail).
Un diagnostic n'est jamais modifié par une demande ; le Safety Engine n'est jamais contourné."""
from __future__ import annotations

import logging
import uuid
from datetime import UTC, date, datetime

from app.db.models import DiagnosticSession, ServiceRequest
from app.notifications.service_requests import (
    NotConfiguredNotifier,
    ServiceRequestNotifier,
    build_message,
)
from app.repositories.equipment import EquipmentRepository
from app.repositories.service_requests import ServiceRequestRepository
from app.repositories.sessions import MediaRepository, SessionRepository, UserRepository
from app.service_area.policy import AreaError, ServiceAreaPolicy
from app.service_requests.handoff import handoff_payload
from app.service_requests.snapshot import build_snapshot
from app.service_requests.validation import (
    CANCELLABLE,
    CATEGORIES,
    CONSENT_VERSION,
    InvalidField,
    clean_text,
    normalize_phone,
    validate_availability,
    validate_email,
    validate_postal_code,
)
from app.services.session_service import NotFound

log = logging.getLogger("nalvium.requests")


class InvalidState(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


class ServiceRequestService:
    def __init__(
        self,
        users: UserRepository,
        requests: ServiceRequestRepository,
        sessions: SessionRepository,
        equipment: EquipmentRepository,
        media: MediaRepository,
        notifier: ServiceRequestNotifier | None = None,
        area: ServiceAreaPolicy | None = None,
    ) -> None:
        self._area = area or ServiceAreaPolicy()
        self._notifier = notifier or NotConfiguredNotifier()
        self._users, self._requests, self._sessions = users, requests, sessions
        self._equipment, self._media = equipment, media

    # ---- création -----------------------------------------------------------
    def create(
        self, user_id: uuid.UUID, *, session_id: uuid.UUID | None = None, equipment_id: uuid.UUID | None = None,
        summary: str | None = None, category: str | None = None,
    ) -> ServiceRequest:
        self._users.ensure(user_id)
        session = None
        if session_id is not None:
            session = self._sessions.get_owned(session_id, user_id)
            if session is None:
                raise NotFound
            existing = self._requests.draft_for_session(session_id, user_id)
            if existing is not None:
                return existing  # un seul brouillon par diagnostic : on le reprend
            equipment_id = equipment_id or session.equipment_id
        if equipment_id is not None and self._equipment.get_owned(equipment_id, user_id) is None:
            raise NotFound
        if category is not None and category not in CATEGORIES:
            raise InvalidField("invalid_category")
        req = ServiceRequest(
            user_id=user_id, diagnostic_session_id=session_id, equipment_id=equipment_id, status="DRAFT",
            problem_category=category or (session.category if session else None),
            problem_summary=clean_text(summary, 1000) or (self._default_summary(session) if session else None),
        )
        self._requests.add(req)
        self._requests.commit()
        return req

    @staticmethod
    def _default_summary(session: DiagnosticSession) -> str | None:
        parts = [session.title, session.description]
        text = ". ".join(p.strip().rstrip(".") for p in parts if p and p.strip())
        return clean_text(text, 1000)

    # ---- lecture ------------------------------------------------------------
    def get(self, user_id: uuid.UUID, request_id: uuid.UUID) -> ServiceRequest:
        req = self._requests.get_owned(request_id, user_id)
        if req is None:
            raise NotFound
        return req

    def list(self, user_id: uuid.UUID) -> list[ServiceRequest]:
        return self._requests.list_for_user(user_id)

    def context(self, user_id: uuid.UUID, req: ServiceRequest) -> dict:
        """Brouillon : aperçu calculé à la volée ; envoyé : le snapshot FIGÉ."""
        if req.status != "DRAFT" and req.structured_context is not None:
            return req.structured_context
        return self._snapshot(user_id, req)

    def _snapshot(self, user_id: uuid.UUID, req: ServiceRequest) -> dict:
        session = self._sessions.get_owned(req.diagnostic_session_id, user_id) if req.diagnostic_session_id else None
        item = self._equipment.get_owned(req.equipment_id, user_id) if req.equipment_id else None
        outcomes = [v.outcome for v in self._sessions.verifications(session.id)] if session else []
        return build_snapshot(session, item, outcomes)

    # ---- brouillon ----------------------------------------------------------
    def update(self, user_id: uuid.UUID, request_id: uuid.UUID, fields: dict) -> ServiceRequest:
        """`fields` : seulement les clés fournies. Modifiable uniquement en DRAFT."""
        req = self.get(user_id, request_id)
        if req.status != "DRAFT":
            raise InvalidState("not_editable")
        if "problem_summary" in fields:
            req.problem_summary = clean_text(fields["problem_summary"], 1000)
        if "category" in fields:
            if fields["category"] is not None and fields["category"] not in CATEGORIES:
                raise InvalidField("invalid_category")
            req.problem_category = fields["category"]
        if "equipment_id" in fields:
            eid = fields["equipment_id"]
            if eid is not None and self._equipment.get_owned(eid, user_id) is None:
                raise NotFound
            req.equipment_id = eid
        if "first_name" in fields:
            req.first_name = clean_text(fields["first_name"], 60)
        if "phone" in fields:
            req.phone = normalize_phone(fields["phone"]) if fields["phone"] else None
        if "email" in fields:
            req.email = validate_email(fields["email"])
        if "city" in fields:
            req.city = clean_text(fields["city"], 80)
        if "postal_code" in fields:
            req.postal_code = validate_postal_code(fields["postal_code"]) if fields["postal_code"] else None
        if {"availability_type", "preferred_date", "preferred_time_window"} & fields.keys():
            kind = fields.get("availability_type", req.availability_type)
            pdate: date | None = fields.get("preferred_date", req.preferred_date.date() if req.preferred_date else None)
            window = fields.get("preferred_time_window", req.preferred_time_window)
            req.availability_type, req.preferred_date, req.preferred_time_window = validate_availability(kind, pdate, window)
        self._requests.commit()
        return req

    def select_media(self, user_id: uuid.UUID, request_id: uuid.UUID, media_ids: list[uuid.UUID]) -> ServiceRequest:
        """L'utilisateur CHOISIT les médias joints ; tout média non listé reste privé."""
        req = self.get(user_id, request_id)
        if req.status != "DRAFT":
            raise InvalidState("not_editable")
        for mid in media_ids:
            asset = self._media.get_owned(mid, user_id)
            ok = asset is not None and asset.kind in ("photo", "video") and (
                asset.session_id is None or asset.session_id == req.diagnostic_session_id
            )
            if not ok:
                raise InvalidField("unknown_media")
        self._requests.set_media(req, media_ids)
        self._requests.commit()
        return req

    # ---- envoi / annulation -------------------------------------------------
    def submit(self, user_id: uuid.UUID, request_id: uuid.UUID, *, consent: bool, consent_version: str) -> ServiceRequest:
        req = self.get(user_id, request_id)
        if req.status != "DRAFT":
            raise InvalidState("already_submitted")
        if not consent:
            raise InvalidField("consent_required")
        if consent_version != CONSENT_VERSION:
            raise InvalidField("consent_version_mismatch")
        if not (req.problem_summary or "").strip():
            raise InvalidField("problem_required")
        for value, code in ((req.first_name, "first_name_required"), (req.phone, "phone_required"),
                            (req.city, "city_required"), (req.postal_code, "postal_code_required"),
                            (req.availability_type, "availability_required")):
            if not value:
                raise InvalidField(code)
        # CONTRÔLE SERVEUR DÉFINITIF de la zone de service (ville + code postal, jamais de GPS). Hors zone ou
        # référentiel inexploitable : la demande reste DRAFT, n'est jamais SUBMITTED et ne notifie rien.
        try:
            decision = self._area.evaluate(req.city or "", req.postal_code or "")
        except AreaError as exc:
            raise InvalidField(exc.code) from exc
        if not decision.in_zone:
            raise InvalidField("out_of_zone")
        now = datetime.now(UTC)
        snapshot = self._snapshot(user_id, req)  # figé : le diagnostic peut évoluer ensuite
        req.structured_context = snapshot
        cats = ["problem", "contact", "availability"]
        if snapshot.get("source") == "diagnostic":
            cats.append("diagnostic_context")
        if req.equipment_id:
            cats.append("equipment")
        if req.media:
            cats.append("media")
        req.consent_version, req.consented_at, req.consented_categories = consent_version, now, cats
        for m in req.media:
            m.consented_at = now
        req.status, req.submitted_at = "SUBMITTED", now
        self._requests.commit()  # la demande est enregistrée : source de vérité
        self._notify_submitted(req)
        return req

    def _notify_submitted(self, req: ServiceRequest) -> None:
        """Notification interne APRÈS la transaction. Ne lève jamais ; une seule tentative par demande (claim atomique)."""
        try:
            if not self._requests.claim_notification(req.id):
                return  # déjà réservée/envoyée : jamais deux notifications pour la même transition
            if not self._notifier.configured:
                self._requests.record_notification(req.id, "not_configured", None)
                log.info("request %s notification not configured", req.id)
                return
            photos = videos = 0
            for m in req.media:  # seulement les médias CONSENTIS (références sélectionnées)
                asset = self._media.get_any(m.media_asset_id)
                photos += int(asset is not None and asset.kind == "photo")
                videos += int(asset is not None and asset.kind == "video")
            text = build_message(handoff_payload(req), str(req.id).replace("-", "")[:6].upper(), photos, videos)
            result = self._notifier.notify(text)
            self._requests.record_notification(req.id, result.status, result.error_code)
            log.info("request %s notification %s%s", req.id, result.status, f" ({result.error_code})" if result.error_code else "")
        except Exception as exc:  # noqa: BLE001 — la soumission ne doit JAMAIS échouer à cause de la notification
            log.warning("request %s notification error type=%s", req.id, type(exc).__name__)
            try:
                self._requests.record_notification(req.id, "failed", f"internal_{type(exc).__name__}"[:48])
            except Exception:  # noqa: BLE001
                log.warning("request %s notification state not recorded", req.id)

    def cancel(self, user_id: uuid.UUID, request_id: uuid.UUID) -> ServiceRequest:
        req = self.get(user_id, request_id)
        if req.status not in CANCELLABLE:
            raise InvalidState("not_cancellable")
        req.status = "CANCELLED"
        self._requests.commit()
        return req

    @staticmethod
    def handoff(req: ServiceRequest) -> dict:
        if req.status in ("DRAFT", "CANCELLED") or req.consented_at is None:
            raise InvalidState("no_consent")
        return handoff_payload(req)
