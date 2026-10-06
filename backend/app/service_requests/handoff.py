"""Représentation « professional handoff » : UNIQUEMENT les données consenties, prête pour une transmission future
(webhook, CRM, tableau de bord). Rien n'est envoyé nulle part en V1."""
from app.db.models import ServiceRequest

_INTERNAL_KEYS = {"prompt", "system", "reasoning", "confidence", "user_id", "install_id"}


def handoff_payload(req: ServiceRequest) -> dict:
    ctx = {k: v for k, v in (req.structured_context or {}).items() if k not in _INTERNAL_KEYS}
    return {
        "request_id": str(req.id),
        "submitted_at": req.submitted_at.isoformat() if req.submitted_at else None,
        "problem": {"category": req.problem_category, "summary": req.problem_summary},
        "context": ctx,
        "contact": {
            "first_name": req.first_name, "phone": req.phone, "email": req.email,
            "city": req.city, "postal_code": req.postal_code,
        },
        "availability": {
            "type": req.availability_type,
            "date": req.preferred_date.date().isoformat() if req.preferred_date else None,
            "window": req.preferred_time_window,
        },
        # Seulement les médias que l'utilisateur a explicitement sélectionnés ; jamais le PDF de la notice.
        "media": [{"media_id": str(m.media_asset_id)} for m in req.media],
        "consent": {
            "version": req.consent_version,
            "at": req.consented_at.isoformat() if req.consented_at else None,
            "categories": list(req.consented_categories or []),
        },
    }
