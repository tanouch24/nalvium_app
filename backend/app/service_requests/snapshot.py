"""Snapshot minimal et structuré du diagnostic, figé à l'envoi. Pas de transcript brut, pas de raisonnement interne,
pas de prompts : uniquement ce qui aide un professionnel (problème, appareil, déjà essayé, pourquoi une aide)."""
from datetime import datetime

from app.db.models import DiagnosticSession, Equipment
from app.equipment.catalog import label_for

HYPOTHESIS_NOTE = "hypothèse de Nalvium, non confirmée par un professionnel"
ACTION_STATUS_LABEL = {"done": "fait", "failed": "impossible", "mismatch": "ne correspondait pas", "pending": "proposé"}
OUTCOME_LABEL = {
    "resolved": "résolu", "improved": "amélioré", "unchanged": "inchangé",
    "worsened": "aggravé", "cannot_determine": "indéterminé",
}


def equipment_block(item: Equipment | None) -> dict | None:
    if item is None:
        return None
    return {
        "type": item.equipment_type, "label": label_for(item.equipment_type), "name": item.display_name,
        "brand": item.brand, "model": item.model, "room": item.room.name if item.room else None,
    }


def _iso(d: datetime | None) -> str | None:
    return d.isoformat() if d else None


def build_snapshot(session: DiagnosticSession | None, equipment: Equipment | None, verifications: list[str]) -> dict:
    snap: dict = {"version": 1, "source": "diagnostic" if session else "direct", "equipment": equipment_block(equipment)}
    if session is None:
        return snap
    nalvium = [m for m in session.messages if m.role == "nalvium"]
    last = nalvium[-1] if nalvium else None
    observations: list[str] = []
    for m in nalvium:
        for o in m.observations:
            if o.text not in observations:
                observations.append(o.text)
    hypotheses = []
    for m in reversed(nalvium):
        if m.hypotheses:
            hypotheses = [
                {"label": h.label, "note": HYPOTHESIS_NOTE}
                for h in sorted(m.hypotheses, key=lambda h: -h.confidence)[:3]
            ]
            break
    pages = sorted({p for m in nalvium for p in (m.manual_pages or [])})
    snap.update(
        category=session.category,
        title=session.title,
        description=session.description,
        diagnostic_status=session.status,
        observations=observations[:8],
        hypotheses=hypotheses,
        actions_tried=[
            {"instruction": a.instruction, "result": ACTION_STATUS_LABEL.get(a.status, a.status)} for a in session.actions
        ],
        verifications=[OUTCOME_LABEL.get(v, v) for v in verifications],
        safety_stop_reason=(last.text if last and session.status == "stopped" else None),
        professional_reason=(last.text if last and session.status == "referred" else None),
        manual=(
            {"consulted": True, "manufacturer": equipment.brand if equipment else None,
             "model": equipment.model if equipment else None, "pages": pages}
            if pages else None
        ),
        diagnosed_at=_iso(session.updated_at),
    )
    return snap
