import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.models import (
    DiagnosticSession,
    MediaAsset,
    SessionAction,
    SessionHypothesis,
    SessionMessage,
    SessionObservation,
    SessionVerification,
    User,
)

TERMINAL_STATUSES = ("resolved", "stopped", "referred")


class UserRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    def ensure(self, user_id: uuid.UUID) -> User:
        user = self._db.get(User, user_id)
        if user is None:
            user = User(id=user_id)
            self._db.add(user)
            self._db.commit()
        return user


class MediaRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    def add(self, asset: MediaAsset) -> MediaAsset:
        self._db.add(asset)
        self._db.commit()
        return asset

    def get_owned(self, media_id: uuid.UUID, user_id: uuid.UUID) -> MediaAsset | None:
        asset = self._db.get(MediaAsset, media_id)
        return asset if asset and asset.user_id == user_id else None


class SessionRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    def create(self, user_id: uuid.UUID) -> DiagnosticSession:
        session = DiagnosticSession(user_id=user_id)
        self._db.add(session)
        self._db.commit()
        return session

    def get_owned(self, session_id: uuid.UUID, user_id: uuid.UUID) -> DiagnosticSession | None:
        stmt = (
            select(DiagnosticSession)
            .where(DiagnosticSession.id == session_id, DiagnosticSession.user_id == user_id)
            .options(
                selectinload(DiagnosticSession.messages).selectinload(SessionMessage.observations),
                selectinload(DiagnosticSession.messages).selectinload(SessionMessage.hypotheses),
                selectinload(DiagnosticSession.media),
            )
        )
        return self._db.execute(stmt).scalar_one_or_none()

    def list_for_user(
        self, user_id: uuid.UUID, *, active_only: bool = False, limit: int = 50
    ) -> list[DiagnosticSession]:
        stmt = (
            select(DiagnosticSession)
            .where(DiagnosticSession.user_id == user_id)
            .options(selectinload(DiagnosticSession.media))
            .order_by(DiagnosticSession.updated_at.desc())
            .limit(limit)
        )
        if active_only:
            stmt = stmt.where(DiagnosticSession.status == "active")
        # Une session sans aucun message n'a jamais démarré : on ne la montre pas.
        stmt = stmt.where(
            DiagnosticSession.id.in_(select(SessionMessage.session_id).distinct())
        )
        return list(self._db.execute(stmt).scalars())

    def next_seq(self, session: DiagnosticSession) -> int:
        return (max((m.seq for m in session.messages), default=0)) + 1

    def add_message(self, session: DiagnosticSession, **fields) -> SessionMessage:
        msg = SessionMessage(session_id=session.id, seq=self.next_seq(session), **fields)
        session.messages.append(msg)
        self._db.flush()
        return msg

    def add_observations(self, msg: SessionMessage, texts: list[str]) -> None:
        for t in texts:
            self._db.add(SessionObservation(message_id=msg.id, text=t))

    def add_hypotheses(self, msg: SessionMessage, items: list[tuple[str, float]]) -> None:
        for label, conf in items:
            self._db.add(SessionHypothesis(message_id=msg.id, label=label, confidence=conf))

    def pending_action(self, session_id: uuid.UUID) -> SessionAction | None:
        stmt = (
            select(SessionAction)
            .where(SessionAction.session_id == session_id, SessionAction.status == "pending")
            .order_by(SessionAction.step_number.desc())
            .limit(1)
        )
        return self._db.execute(stmt).scalar_one_or_none()

    def count_actions(self, session_id: uuid.UUID) -> int:
        return len(
            list(
                self._db.execute(
                    select(SessionAction.id).where(SessionAction.session_id == session_id)
                ).scalars()
            )
        )

    def add_action(self, session: DiagnosticSession, msg: SessionMessage, instruction: str):
        step = self.count_actions(session.id) + 1
        action = SessionAction(
            session_id=session.id, message_id=msg.id, step_number=step, instruction=instruction
        )
        self._db.add(action)
        return action

    def add_verification(self, session: DiagnosticSession, msg: SessionMessage, outcome: str):
        self._db.add(SessionVerification(session_id=session.id, message_id=msg.id, outcome=outcome))

    def completed_actions(self, session_id: uuid.UUID) -> list[SessionAction]:
        stmt = (
            select(SessionAction)
            .where(SessionAction.session_id == session_id, SessionAction.status != "pending")
            .order_by(SessionAction.step_number)
        )
        return list(self._db.execute(stmt).scalars())

    def verifications(self, session_id: uuid.UUID) -> list[SessionVerification]:
        stmt = (
            select(SessionVerification)
            .where(SessionVerification.session_id == session_id)
            .order_by(SessionVerification.created_at)
        )
        return list(self._db.execute(stmt).scalars())

    def commit(self) -> None:
        self._db.commit()
