"""Moteur de session : le backend est la source de vérité de la conversation guidée."""
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime

from app.db.models import DiagnosticSession, MediaAsset, SessionMessage
from app.domain.diagnosis import (
    DiagnosticAnalysis,
    DiagnosticContext,
    MediaRef,
    NextActionType,
    VerificationOutcome,
)
from app.media.pipeline import ProcessedImage
from app.media.storage import MediaStorage
from app.repositories.sessions import (
    TERMINAL_STATUSES,
    MediaRepository,
    SessionRepository,
    UserRepository,
)
from app.services.diagnostic_service import DiagnosticService

ACTION_RESULT_TEXT = {
    "done": "J'ai fait cette étape.",
    "cannot": "Je n'y arrive pas.",
    "mismatch": "Ce n'est pas ce que je vois.",
}
ACTION_STATUS = {"done": "done", "cannot": "failed", "mismatch": "mismatch"}

STATUS_BY_ACTION = {
    NextActionType.SAFETY_STOP: "stopped",
    NextActionType.RESOLVED: "resolved",
    NextActionType.RECOMMEND_PROFESSIONAL: "referred",
}

MAX_TEXT = 2000


class NotFound(Exception):
    pass


class InvalidTurn(Exception):
    pass


@dataclass(frozen=True)
class TurnInput:
    kind: str  # description | answer | photo | action_result
    text: str | None = None
    choice: str | None = None  # done | cannot | mismatch (action_result)
    media_id: uuid.UUID | None = None


class SessionService:
    def __init__(
        self,
        users: UserRepository,
        sessions: SessionRepository,
        media: MediaRepository,
        storage: MediaStorage,
        diagnostics: DiagnosticService,
    ) -> None:
        self._users, self._sessions, self._media = users, sessions, media
        self._storage, self._diagnostics = storage, diagnostics

    # ---- création / lecture -------------------------------------------------
    def create(self, user_id: uuid.UUID) -> DiagnosticSession:
        self._users.ensure(user_id)
        return self._sessions.create(user_id)

    def get(self, user_id: uuid.UUID, session_id: uuid.UUID) -> DiagnosticSession:
        session = self._sessions.get_owned(session_id, user_id)
        if session is None:
            raise NotFound
        return session

    def list(self, user_id: uuid.UUID, *, active_only: bool) -> list[DiagnosticSession]:
        return self._sessions.list_for_user(user_id, active_only=active_only)

    # ---- médias -------------------------------------------------------------
    def add_photo(
        self, user_id: uuid.UUID, session_id: uuid.UUID, image: ProcessedImage
    ) -> MediaAsset:
        session = self.get(user_id, session_id)
        if session.status in TERMINAL_STATUSES:
            raise InvalidTurn("session_closed")
        media_id = uuid.uuid4()
        key = f"{user_id}/{media_id}.jpg"
        self._storage.put(key, image.data)
        asset = MediaAsset(
            id=media_id,
            user_id=user_id,
            session_id=session.id,
            kind="photo",
            storage_key=key,
            content_type=image.content_type,
            size_bytes=len(image.data),
            width=image.width,
            height=image.height,
            exif_stripped=True,
            visibility="private",
        )
        return self._media.add(asset)

    def read_media(self, user_id: uuid.UUID, media_id: uuid.UUID) -> tuple[bytes, str]:
        asset = self._media.get_owned(media_id, user_id)
        if asset is None:
            raise NotFound
        return self._storage.get(asset.storage_key), asset.content_type

    # ---- tour de conversation ----------------------------------------------
    async def turn(
        self, user_id: uuid.UUID, session_id: uuid.UUID, turn: TurnInput | None
    ) -> DiagnosticSession:
        """Enregistre l'entrée utilisateur (si fournie) puis analyse.

        `turn=None` relance l'analyse d'un message utilisateur resté sans réponse (retry).
        Une session terminée (dont SAFETY_STOP) n'appelle JAMAIS l'IA.
        """
        session = self.get(user_id, session_id)
        if session.status in TERMINAL_STATUSES:
            return session

        if turn is not None:
            self._store_user_turn(session, user_id, turn)
        elif not session.messages or session.messages[-1].role != "user":
            return session  # rien en attente

        self._sessions.commit()  # on ne garde pas de transaction ouverte pendant l'appel IA

        ctx = self._build_context(session)
        analysis = await self._diagnostics.analyze(ctx)
        self._store_analysis(session, analysis)
        self._sessions.commit()
        return self.get(user_id, session_id)

    # ---- internes -----------------------------------------------------------
    def _store_user_turn(self, session: DiagnosticSession, user_id: uuid.UUID, turn: TurnInput):
        text = (turn.text or "").strip()[:MAX_TEXT] or None
        if turn.kind == "description":
            if not text:
                raise InvalidTurn("empty_description")
            session.description = session.description or text
            self._sessions.add_message(session, role="user", kind="description", text=text)
        elif turn.kind == "answer":
            if not text:
                raise InvalidTurn("empty_answer")
            self._sessions.add_message(session, role="user", kind="answer", text=text)
        elif turn.kind == "photo":
            asset = turn.media_id and self._media.get_owned(turn.media_id, user_id)
            if not asset or asset.session_id != session.id:
                raise InvalidTurn("unknown_media")
            self._sessions.add_message(
                session, role="user", kind="photo", text=text, media_id=asset.id
            )
        elif turn.kind == "action_result":
            if turn.choice not in ACTION_RESULT_TEXT:
                raise InvalidTurn("unknown_choice")
            action = self._sessions.pending_action(session.id)
            if action:
                action.status = ACTION_STATUS[turn.choice]
                action.resolved_at = datetime.now(UTC)
            self._sessions.add_message(
                session, role="user", kind="action_result", text=ACTION_RESULT_TEXT[turn.choice]
            )
        else:
            raise InvalidTurn("unknown_kind")
        session.current_state = "awaiting_analysis"

    def _build_context(self, session: DiagnosticSession) -> DiagnosticContext:
        history: list[str] = []
        user_texts: list[str] = []
        for m in session.messages:
            if m.role == "user":
                label = {"photo": "[Photo ajoutée]", "action_result": "Réponse à l'étape"}.get(
                    m.kind, "Utilisateur"
                )
                line = f"{label}: {m.text}" if m.text else label
                history.append(line)
                if m.text:
                    user_texts.append(m.text)
            else:
                parts = [f"Nalvium ({m.action_type}): {m.text}"]
                if m.hypotheses:
                    parts.append(
                        "hypothèses: "
                        + "; ".join(f"{h.label} ({h.confidence:.2f})" for h in m.hypotheses)
                    )
                history.append(" | ".join(parts))

        photos: list[MediaRef] = []
        for asset in session.media:
            if asset.kind == "photo":
                photos.append(
                    MediaRef(
                        media_id=str(asset.id),
                        mime=asset.content_type,
                        data=self._storage.get(asset.storage_key),
                    )
                )
        done = [
            f"étape {a.step_number} ({a.status}): {a.instruction}"
            for a in self._sessions.completed_actions(session.id)
        ]
        outcomes = [VerificationOutcome(v.outcome) for v in self._sessions.verifications(session.id)]
        return DiagnosticContext(
            session_id=str(session.id),
            photos=photos,
            description=session.description,
            conversation=user_texts,
            history=history,
            completed_actions=done,
            previous_outcomes=outcomes,
        )

    def _store_analysis(self, session: DiagnosticSession, a: DiagnosticAnalysis) -> SessionMessage:
        action = a.next_action
        msg = self._sessions.add_message(
            session,
            role="nalvium",
            kind="analysis",
            text=action.message,
            action_type=action.type.value,
            choices=action.choices,
            required_items=a.required_items,
            missing_information=a.missing_information,
            risk_level=a.risk_level.value,
            urgency=a.urgency.value,
            diy_allowed=a.diy_allowed,
        )
        self._sessions.add_observations(msg, a.observations)
        self._sessions.add_hypotheses(msg, [(h.label, h.confidence) for h in a.hypotheses])
        if action.type is NextActionType.INSTRUCTION:
            self._sessions.add_action(session, msg, action.message)
        if a.verification_outcome is not None:
            self._sessions.add_verification(session, msg, a.verification_outcome.value)

        if a.title:
            session.title = a.title[:120]
        session.category = a.category.value
        session.subcategory = a.subcategory
        session.risk_level = a.risk_level.value
        session.current_state = action.type.value
        session.status = STATUS_BY_ACTION.get(action.type, "active")
        return msg

