"""Tables : identité anonyme, sessions de diagnostic structurées, médias privés."""
import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import ARRAY, UUID
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
    created_at: Mapped[datetime] = _now()
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    media: Mapped[list["MediaAsset"]] = relationship(
        back_populates="session", order_by="MediaAsset.created_at"
    )
    messages: Mapped[list["SessionMessage"]] = relationship(
        back_populates="session", order_by="SessionMessage.seq", cascade="all, delete-orphan"
    )


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
    visibility: Mapped[str] = mapped_column(String(16), default="private")
    created_at: Mapped[datetime] = _now()
    session: Mapped[DiagnosticSession | None] = relationship(back_populates="media")


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
