import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from app.db.models import DiagnosticSession, SessionMessage


class TurnRequest(BaseModel):
    kind: Literal["description", "answer", "photo", "video", "action_result"]
    text: str | None = Field(default=None, max_length=2000)
    choice: Literal["done", "cannot", "mismatch"] | None = None
    media_id: uuid.UUID | None = None


class MediaOut(BaseModel):
    id: uuid.UUID
    width: int | None
    height: int | None
    media_type: str = "photo"  # photo | video
    duration_s: float | None = None
    has_audio: bool | None = None


class HypothesisOut(BaseModel):
    label: str
    confidence: float


class MessageOut(BaseModel):
    id: uuid.UUID
    role: str
    kind: str
    text: str | None
    media_id: uuid.UUID | None
    action_type: str | None = None
    created_at: datetime


class NextOut(BaseModel):
    """Dernière réponse Nalvium : c'est elle qui détermine l'écran affiché par l'app."""

    action_type: str
    message: str
    choices: list[str]
    required_items: list[str]
    missing_information: list[str]
    observations: list[str]
    hypotheses: list[HypothesisOut]
    risk_level: str | None
    urgency: str | None
    diy_allowed: bool | None
    step_number: int | None = None


class ActionOut(BaseModel):
    step_number: int
    instruction: str
    status: str  # pending | done | failed | mismatch


class SessionOut(BaseModel):
    id: uuid.UUID
    status: str
    current_state: str
    title: str | None
    category: str | None
    subcategory: str | None
    risk_level: str | None
    created_at: datetime
    updated_at: datetime
    # True si un message utilisateur attend encore une réponse (analyse échouée / interrompue).
    pending_analysis: bool
    latest_media_id: uuid.UUID | None
    media: list[MediaOut]
    messages: list[MessageOut]
    actions: list[ActionOut]
    next: NextOut | None


class SessionSummary(BaseModel):
    id: uuid.UUID
    status: str
    current_state: str
    title: str | None
    category: str | None
    risk_level: str | None
    updated_at: datetime
    first_media_id: uuid.UUID | None
    subcategory: str | None = None
    # Dernier message de Nalvium (pour la carte « À reprendre » / l'historique).
    last_message: str | None = None


def _next_out(msg: SessionMessage, step: int | None) -> NextOut:
    return NextOut(
        action_type=msg.action_type or "ASK_QUESTION",
        message=msg.text or "",
        choices=msg.choices or [],
        required_items=msg.required_items or [],
        missing_information=msg.missing_information or [],
        observations=[o.text for o in msg.observations],
        hypotheses=[HypothesisOut(label=h.label, confidence=h.confidence) for h in msg.hypotheses],
        risk_level=msg.risk_level,
        urgency=msg.urgency,
        diy_allowed=msg.diy_allowed,
        step_number=step,
    )


def session_out(session: DiagnosticSession) -> SessionOut:
    msgs = session.messages
    last = msgs[-1] if msgs else None
    last_nalvium = next((m for m in reversed(msgs) if m.role == "nalvium"), None)
    step = sum(1 for m in msgs if m.action_type == "INSTRUCTION") or None
    return SessionOut(
        id=session.id,
        status=session.status,
        current_state=session.current_state,
        title=session.title,
        category=session.category,
        subcategory=session.subcategory,
        risk_level=session.risk_level,
        created_at=session.created_at,
        updated_at=session.updated_at,
        pending_analysis=bool(last and last.role == "user" and session.status == "active"),
        latest_media_id=session.media[-1].id if session.media else None,
        media=[
            MediaOut(id=m.id, width=m.width, height=m.height, media_type=m.kind, duration_s=m.duration_s, has_audio=m.has_audio)
            for m in session.media
        ],
        messages=[
            MessageOut(
                id=m.id,
                role=m.role,
                kind=m.kind,
                text=m.text,
                media_id=m.media_id,
                action_type=m.action_type,
                created_at=m.created_at,
            )
            for m in msgs
        ],
        actions=[
            ActionOut(step_number=a.step_number, instruction=a.instruction, status=a.status)
            for a in session.actions
        ],
        next=_next_out(last_nalvium, step) if last_nalvium else None,
    )


def summary_out(session: DiagnosticSession) -> SessionSummary:
    last = next((m for m in reversed(session.messages) if m.role == "nalvium"), None)
    return SessionSummary(
        id=session.id,
        status=session.status,
        current_state=session.current_state,
        title=session.title,
        category=session.category,
        risk_level=session.risk_level,
        updated_at=session.updated_at,
        first_media_id=session.media[0].id if session.media else None,
        subcategory=session.subcategory,
        last_message=(last.text or None) if last else None,
    )
