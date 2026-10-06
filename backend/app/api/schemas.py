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


class ManualRef(BaseModel):
    """Provenance : la réponse s'appuie réellement sur ces pages de la notice constructeur."""

    manufacturer: str | None
    pages: list[int]


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
    manual: ManualRef | None = None


class EquipmentRef(BaseModel):
    """Équipement lié à une session (affiché dans le diagnostic et le récapitulatif)."""

    id: uuid.UUID
    equipment_type: str
    display_name: str
    brand: str | None
    model: str | None
    room_type: str | None
    room_name: str | None


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
    equipment: EquipmentRef | None = None


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
    equipment_id: uuid.UUID | None = None


def equipment_ref(item) -> EquipmentRef | None:
    if item is None:
        return None
    return EquipmentRef(
        id=item.id, equipment_type=item.equipment_type, display_name=item.display_name, brand=item.brand,
        model=item.model, room_type=item.room.normalized_type if item.room else None,
        room_name=item.room.name if item.room else None,
    )


def _next_out(msg: SessionMessage, step: int | None, brand: str | None = None) -> NextOut:
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
        manual=ManualRef(manufacturer=brand, pages=list(msg.manual_pages)) if msg.manual_pages else None,
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
        next=_next_out(last_nalvium, step, session.equipment.brand if session.equipment else None) if last_nalvium else None,
        equipment=equipment_ref(session.equipment),
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
        equipment_id=session.equipment_id,
    )


class CreateSessionRequest(BaseModel):
    equipment_id: uuid.UUID | None = None


class LinkEquipmentRequest(BaseModel):
    equipment_id: uuid.UUID | None = None  # null = détacher


# ---- Maison ------------------------------------------------------------------
class RoomOut(BaseModel):
    id: uuid.UUID
    name: str
    room_type: str


class EquipmentSummary(BaseModel):
    id: uuid.UUID
    equipment_type: str
    display_name: str
    brand: str | None
    model: str | None
    room_id: uuid.UUID | None
    room_type: str | None
    room_name: str | None
    photo_media_id: uuid.UUID | None  # se charge via /v1/media/{id}/thumbnail (vignette)
    diagnostics_count: int
    updated_at: datetime


class HomeOut(BaseModel):
    id: uuid.UUID
    rooms: list[RoomOut]
    equipment: list[EquipmentSummary]


class EquipmentDiagnostic(BaseModel):
    id: uuid.UUID
    title: str | None
    status: str
    risk_level: str | None
    updated_at: datetime


class EquipmentDetail(EquipmentSummary):
    diagnostics: list[EquipmentDiagnostic]
    manual: "ManualOut | None" = None


class EquipmentCreate(BaseModel):
    equipment_type: str = Field(default="other", max_length=32)
    display_name: str | None = Field(default=None, max_length=80)
    room_type: str | None = Field(default=None, max_length=24)
    brand: str | None = Field(default=None, max_length=60)
    model: str | None = Field(default=None, max_length=80)
    primary_media_id: uuid.UUID | None = None


class EquipmentUpdate(BaseModel):
    """Seuls les champs présents sont modifiés ; null/vide efface marque, modèle, pièce ou photo."""

    equipment_type: str | None = Field(default=None, max_length=32)
    display_name: str | None = Field(default=None, max_length=80)
    room_type: str | None = Field(default=None, max_length=24)
    brand: str | None = Field(default=None, max_length=60)
    model: str | None = Field(default=None, max_length=80)
    primary_media_id: uuid.UUID | None = None


class IdentifyRequest(BaseModel):
    media_id: uuid.UUID


class IdentificationOut(BaseModel):
    equipment_type: str  # slug, ou "unknown"
    brand: str | None
    model: str | None
    confidence: float
    visible_text: list[str]
    needs_confirmation: bool


class EquipmentSuggestionsOut(BaseModel):
    detected_type: str | None
    matches: list[EquipmentSummary]


def equipment_summary(item, diagnostics: int = 0) -> EquipmentSummary:
    return EquipmentSummary(
        id=item.id, equipment_type=item.equipment_type, display_name=item.display_name, brand=item.brand,
        model=item.model, room_id=item.room_id,
        room_type=item.room.normalized_type if item.room else None,
        room_name=item.room.name if item.room else None,
        photo_media_id=item.primary_media_id, diagnostics_count=diagnostics, updated_at=item.updated_at,
    )


class ManualOut(BaseModel):
    status: str  # available | needs_confirmation | not_found | error
    error_code: str | None
    title: str | None
    manufacturer: str | None
    model_reference: str | None
    source_url: str | None
    source_domain: str | None
    source_is_official: bool
    page_count: int | None
    file_size: int | None
    match_level: str | None
    retrieved_at: datetime | None


class ManualSearchOut(BaseModel):
    outcome: str  # found | needs_confirmation | up_to_date | kept | not_found | error
    manual: ManualOut


class ManualPageOut(BaseModel):
    page: int
    page_count: int
    text: str


def manual_out(doc) -> ManualOut | None:
    if doc is None:
        return None
    return ManualOut(
        status=doc.status, error_code=doc.error_code, title=doc.title, manufacturer=doc.manufacturer,
        model_reference=doc.model_reference, source_url=doc.source_url, source_domain=doc.source_domain,
        source_is_official=doc.source_is_official, page_count=doc.page_count, file_size=doc.file_size,
        match_level=doc.match_level, retrieved_at=doc.retrieved_at,
    )
