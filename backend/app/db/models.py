"""Tables : identité anonyme, sessions de diagnostic structurées, médias privés."""
import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    Computed,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import ARRAY, TSVECTOR, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


def _uuid_pk() -> Mapped[uuid.UUID]:
    return mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)


def _now() -> Mapped[datetime]:
    return mapped_column(DateTime(timezone=True), server_default=func.now())


class User(Base):
    """Identité anonyme par installation (UUID aléatoire généré par l'app).
    `account_id` est réservé pour rattacher plus tard cet utilisateur à un compte."""

    __tablename__ = "users"
    id: Mapped[uuid.UUID] = _uuid_pk()
    created_at: Mapped[datetime] = _now()
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    account_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), index=True)


class DiagnosticSession(Base):
    __tablename__ = "diagnostic_sessions"
    id: Mapped[uuid.UUID] = _uuid_pk()
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    status: Mapped[str] = mapped_column(String(16), default="active")  # active|resolved|stopped|referred
    current_state: Mapped[str] = mapped_column(String(32), default="awaiting_analysis")
    title: Mapped[str | None] = mapped_column(String(120))
    category: Mapped[str | None] = mapped_column(String(32))
    subcategory: Mapped[str | None] = mapped_column(String(120))
    risk_level: Mapped[str | None] = mapped_column(String(16))
    description: Mapped[str | None] = mapped_column(Text)
    # Équipement de la Maison concerné. Détaché (NULL) si l'équipement est supprimé : le diagnostic reste.
    equipment_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("equipment.id", ondelete="SET NULL"), index=True
    )
    created_at: Mapped[datetime] = _now()
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    equipment: Mapped["Equipment | None"] = relationship(lazy="joined")
    media: Mapped[list["MediaAsset"]] = relationship(
        back_populates="session", order_by="MediaAsset.created_at"
    )
    messages: Mapped[list["SessionMessage"]] = relationship(
        back_populates="session", order_by="SessionMessage.seq", cascade="all, delete-orphan"
    )
    actions: Mapped[list["SessionAction"]] = relationship(order_by="SessionAction.step_number")


class MediaAsset(Base):
    """Média PRIVÉ. Jamais public automatiquement ; copie dérivée pour la communauté après consentement."""

    __tablename__ = "media_assets"
    id: Mapped[uuid.UUID] = _uuid_pk()
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    session_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("diagnostic_sessions.id", ondelete="SET NULL"), index=True
    )
    kind: Mapped[str] = mapped_column(String(16))  # photo | video | audio
    storage_key: Mapped[str] = mapped_column(String(512), unique=True)
    content_type: Mapped[str] = mapped_column(String(64))
    size_bytes: Mapped[int] = mapped_column(Integer)
    width: Mapped[int | None] = mapped_column(Integer)
    height: Mapped[int | None] = mapped_column(Integer)
    exif_stripped: Mapped[bool] = mapped_column(Boolean, default=True)
    # Vidéo uniquement (kind = 'video')
    duration_s: Mapped[float | None] = mapped_column(Float)
    has_audio: Mapped[bool | None] = mapped_column(Boolean)
    visibility: Mapped[str] = mapped_column(String(16), default="private")
    # Version réduite (liste Maison) : on ne charge jamais l'image complète pour une vignette.
    thumb_key: Mapped[str | None] = mapped_column(String(512))
    created_at: Mapped[datetime] = _now()
    session: Mapped[DiagnosticSession | None] = relationship(back_populates="media")
    frames: Mapped[list["VideoFrame"]] = relationship(order_by="VideoFrame.idx", cascade="all, delete-orphan")


class SessionMessage(Base):
    """Un tour de la session : entrée utilisateur OU réponse Nalvium (avec son action_type)."""

    __tablename__ = "session_messages"
    id: Mapped[uuid.UUID] = _uuid_pk()
    session_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("diagnostic_sessions.id", ondelete="CASCADE"), index=True
    )
    seq: Mapped[int] = mapped_column(Integer)
    role: Mapped[str] = mapped_column(String(8))  # user | nalvium
    kind: Mapped[str] = mapped_column(String(24))  # description|answer|photo|action_result|analysis
    text: Mapped[str | None] = mapped_column(Text)
    media_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("media_assets.id", ondelete="SET NULL")
    )
    # Champs propres aux réponses Nalvium
    action_type: Mapped[str | None] = mapped_column(String(32))
    choices: Mapped[list[str] | None] = mapped_column(ARRAY(Text))
    required_items: Mapped[list[str] | None] = mapped_column(ARRAY(Text))
    missing_information: Mapped[list[str] | None] = mapped_column(ARRAY(Text))
    risk_level: Mapped[str | None] = mapped_column(String(16))
    urgency: Mapped[str | None] = mapped_column(String(16))
    diy_allowed: Mapped[bool | None] = mapped_column(Boolean)
    # Provenance : pages de la notice constructeur RÉELLEMENT utilisées pour cette réponse (vide = aucune).
    manual_document_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("equipment_documents.id", ondelete="SET NULL")
    )
    manual_pages: Mapped[list[int] | None] = mapped_column(ARRAY(Integer))
    created_at: Mapped[datetime] = _now()

    session: Mapped[DiagnosticSession] = relationship(back_populates="messages")
    observations: Mapped[list["SessionObservation"]] = relationship(cascade="all, delete-orphan")
    hypotheses: Mapped[list["SessionHypothesis"]] = relationship(cascade="all, delete-orphan")


class SessionObservation(Base):
    __tablename__ = "session_observations"
    id: Mapped[uuid.UUID] = _uuid_pk()
    message_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("session_messages.id", ondelete="CASCADE"), index=True
    )
    text: Mapped[str] = mapped_column(Text)


class SessionHypothesis(Base):
    __tablename__ = "session_hypotheses"
    id: Mapped[uuid.UUID] = _uuid_pk()
    message_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("session_messages.id", ondelete="CASCADE"), index=True
    )
    label: Mapped[str] = mapped_column(Text)
    confidence: Mapped[float] = mapped_column(Float)


class SessionAction(Base):
    """Une instruction donnée à l'utilisateur et ce qu'il en a fait."""

    __tablename__ = "session_actions"
    id: Mapped[uuid.UUID] = _uuid_pk()
    session_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("diagnostic_sessions.id", ondelete="CASCADE"), index=True
    )
    message_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("session_messages.id", ondelete="CASCADE"))
    step_number: Mapped[int] = mapped_column(Integer)
    instruction: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(16), default="pending")  # pending|done|failed|mismatch
    created_at: Mapped[datetime] = _now()
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class SessionVerification(Base):
    __tablename__ = "session_verifications"
    id: Mapped[uuid.UUID] = _uuid_pk()
    session_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("diagnostic_sessions.id", ondelete="CASCADE"), index=True
    )
    message_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("session_messages.id", ondelete="CASCADE"))
    outcome: Mapped[str] = mapped_column(String(24))
    created_at: Mapped[datetime] = _now()


class VideoFrame(Base):
    """Image représentative dérivée d'une vidéo privée (ordre + horodatage conservés)."""

    __tablename__ = "video_frames"
    id: Mapped[uuid.UUID] = _uuid_pk()
    media_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("media_assets.id", ondelete="CASCADE"), index=True)
    idx: Mapped[int] = mapped_column(Integer)
    t_seconds: Mapped[float] = mapped_column(Float)
    storage_key: Mapped[str] = mapped_column(String(512), unique=True)


class Home(Base):
    """Maison d'un utilisateur. V1 : une seule (par défaut) ; le modèle autorise plusieurs logements plus tard."""

    __tablename__ = "homes"
    id: Mapped[uuid.UUID] = _uuid_pk()
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    is_default: Mapped[bool] = mapped_column(Boolean, default=True, server_default=text("true"))
    created_at: Mapped[datetime] = _now()
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class Room(Base):
    """Pièce par son NOM (« Cuisine ») : aucune localisation physique."""

    __tablename__ = "rooms"
    id: Mapped[uuid.UUID] = _uuid_pk()
    home_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("homes.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(60))
    normalized_type: Mapped[str] = mapped_column(String(24))
    created_at: Mapped[datetime] = _now()


class Equipment(Base):
    __tablename__ = "equipment"
    id: Mapped[uuid.UUID] = _uuid_pk()
    home_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("homes.id", ondelete="CASCADE"), index=True)
    room_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("rooms.id", ondelete="SET NULL"))
    equipment_type: Mapped[str] = mapped_column(String(32))
    display_name: Mapped[str] = mapped_column(String(80))
    brand: Mapped[str | None] = mapped_column(String(60))
    model: Mapped[str | None] = mapped_column(String(80))
    primary_media_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("media_assets.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = _now()
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    room: Mapped[Room | None] = relationship(lazy="joined")
    home: Mapped[Home] = relationship(lazy="joined")


class EquipmentDocument(Base):
    """Document documentaire lié à un équipement (V1 : MANUAL). PDF conservé PRIVÉ côté serveur, jamais public."""

    __tablename__ = "equipment_documents"
    id: Mapped[uuid.UUID] = _uuid_pk()
    equipment_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("equipment.id", ondelete="CASCADE"), index=True
    )
    document_type: Mapped[str] = mapped_column(String(16), default="MANUAL")
    # available | needs_confirmation (correspondance approximative) | not_found | error
    status: Mapped[str] = mapped_column(String(24), default="not_found")
    error_code: Mapped[str | None] = mapped_column(String(48))
    title: Mapped[str | None] = mapped_column(String(300))
    manufacturer: Mapped[str | None] = mapped_column(String(60))
    model_reference: Mapped[str | None] = mapped_column(String(80))
    source_url: Mapped[str | None] = mapped_column(Text)
    source_domain: Mapped[str | None] = mapped_column(String(120))
    source_is_official: Mapped[bool] = mapped_column(Boolean, default=False)
    storage_key: Mapped[str | None] = mapped_column(String(512))
    mime_type: Mapped[str | None] = mapped_column(String(64))
    file_size: Mapped[int | None] = mapped_column(Integer)
    checksum: Mapped[str | None] = mapped_column(String(64))
    page_count: Mapped[int | None] = mapped_column(Integer)
    language: Mapped[str | None] = mapped_column(String(8))
    match_level: Mapped[str | None] = mapped_column(String(16))  # exact | approximate
    retrieved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = _now()
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class DocumentChunk(Base):
    """Passage indexé (recherche plein texte PostgreSQL). La page d'origine est toujours conservée."""

    __tablename__ = "document_chunks"
    id: Mapped[uuid.UUID] = _uuid_pk()
    document_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("equipment_documents.id", ondelete="CASCADE"), index=True
    )
    idx: Mapped[int] = mapped_column(Integer)
    page: Mapped[int] = mapped_column(Integer)
    section: Mapped[str | None] = mapped_column(String(200))
    text: Mapped[str] = mapped_column(Text)
    tsv: Mapped[str] = mapped_column(
        TSVECTOR, Computed("to_tsvector('french', text)", persisted=True)
    )
