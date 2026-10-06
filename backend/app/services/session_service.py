"""Moteur de session : le backend est la source de vérité de la conversation guidée."""
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime

from app.db.models import DiagnosticSession, MediaAsset, SessionMessage, VideoFrame
from app.domain.diagnosis import (
    DiagnosticAnalysis,
    DiagnosticContext,
    EquipmentContext,
    MediaRef,
    NextActionType,
    VerificationOutcome,
    VideoDiagnosticInput,
    VideoFrameInput,
)
from app.media.pipeline import ProcessedImage
from app.media.storage import MediaStorage
from app.media.video import ProcessedVideo
from app.repositories.equipment import EquipmentRepository
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
        equipment: EquipmentRepository,
        manuals=None,
    ) -> None:
        self._manuals = manuals  # ManualRetriever | None
        self._users, self._sessions, self._media = users, sessions, media
        self._storage, self._diagnostics, self._equipment = storage, diagnostics, equipment

    # ---- création / lecture -------------------------------------------------
    def create(self, user_id: uuid.UUID, equipment_id: uuid.UUID | None = None) -> DiagnosticSession:
        """Un diagnostic lancé depuis une fiche équipement est lié à cet équipement dès sa création."""
        self._users.ensure(user_id)
        if equipment_id is not None and self._equipment.get_owned(equipment_id, user_id) is None:
            raise NotFound
        return self._sessions.create(user_id, equipment_id)

    def link_equipment(
        self, user_id: uuid.UUID, session_id: uuid.UUID, equipment_id: uuid.UUID | None
    ) -> DiagnosticSession:
        """Rattache (ou détache avec None) APRÈS confirmation explicite de l'utilisateur côté app."""
        session = self.get(user_id, session_id)
        if equipment_id is None:
            session.equipment_id, session.equipment = None, None
        else:
            item = self._equipment.get_owned(equipment_id, user_id)
            if item is None:
                raise NotFound
            session.equipment_id, session.equipment = item.id, item
        self._sessions.commit()
        return self.get(user_id, session_id)

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

    def add_video(self, user_id: uuid.UUID, session_id: uuid.UUID, video: ProcessedVideo) -> MediaAsset:
        """Vidéo PRIVÉE (mp4 nettoyé) + images clés dérivées, rattachées à la session."""
        session = self.get(user_id, session_id)
        if session.status in TERMINAL_STATUSES:
            raise InvalidTurn("session_closed")
        media_id = uuid.uuid4()
        key = f"{user_id}/{media_id}.mp4"
        self._storage.put(key, video.data)
        asset = MediaAsset(
            id=media_id,
            user_id=user_id,
            session_id=session.id,
            kind="video",
            storage_key=key,
            content_type=video.content_type,
            size_bytes=len(video.data),
            width=video.width,
            height=video.height,
            duration_s=video.duration_s,
            has_audio=video.has_audio,
            exif_stripped=True,
            visibility="private",
        )
        for i, f in enumerate(video.frames):
            fkey = f"{user_id}/{media_id}_f{i}.jpg"
            self._storage.put(fkey, f.jpeg)
            asset.frames.append(VideoFrame(idx=i, t_seconds=f.t, storage_key=fkey))
        return self._media.add(asset)

    def read_thumbnail(self, user_id: uuid.UUID, media_id: uuid.UUID) -> tuple[bytes, str]:
        """Photo : l'image elle-même. Vidéo : une image représentative (jamais le fichier vidéo)."""
        asset = self._media.get_owned(media_id, user_id)
        if asset is None:
            raise NotFound
        if asset.kind == "video":
            if not asset.frames:
                raise NotFound
            mid = asset.frames[len(asset.frames) // 2]
            return self._storage.get(mid.storage_key), "image/jpeg"
        if asset.thumb_key:  # photo d'équipement : vignette légère plutôt que l'image complète
            return self._storage.get(asset.thumb_key), "image/jpeg"
        return self._storage.get(asset.storage_key), asset.content_type

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
        manual_doc = None
        if self._manuals is not None and session.equipment_id:
            # Recherche LOCALE automatique dans la notice de CET équipement (pas d'Internet, pas de clic).
            query = " ".join(filter(None, [session.description, *ctx.conversation[-4:]]))
            found = self._manuals.retrieve(session.equipment_id, query)
            if found:
                manual_doc, ctx.manual = found
        analysis = await self._diagnostics.analyze(ctx)
        provided = {e.page for e in ctx.manual.excerpts} if ctx.manual else set()
        # Provenance honnête : seulement les pages réellement fournies ET déclarées utilisées par la réponse.
        used = sorted(set(analysis.manual_pages_used) & provided)
        if analysis.next_action.type is NextActionType.SAFETY_STOP:
            used = []  # un arrêt de sécurité vient du Safety Engine Nalvium : jamais présenté comme « d'après la notice »
        self._store_analysis(session, analysis, manual_doc if used else None, used)
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
        elif turn.kind == "video":
            asset = turn.media_id and self._media.get_owned(turn.media_id, user_id)
            if not asset or asset.session_id != session.id or asset.kind != "video":
                raise InvalidTurn("unknown_media")
            self._sessions.add_message(session, role="user", kind="video", text=text, media_id=asset.id)
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
                label = {"photo": "[Photo ajoutée]", "video": "[Vidéo ajoutée]", "action_result": "Réponse à l'étape"}.get(
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
        videos: list[VideoDiagnosticInput] = []
        for asset in session.media:
            if asset.kind == "video" and asset.frames:
                videos.append(
                    VideoDiagnosticInput(
                        media_id=str(asset.id),
                        duration_s=asset.duration_s or 0.0,
                        has_audio=bool(asset.has_audio),
                        frames=[
                            VideoFrameInput(t=f.t_seconds, data=self._storage.get(f.storage_key)) for f in asset.frames
                        ],
                    )
                )
            elif asset.kind == "photo":
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
        eq = session.equipment
        return DiagnosticContext(
            session_id=str(session.id),
            equipment=(
                EquipmentContext(
                    type=eq.equipment_type, name=eq.display_name, brand=eq.brand, model=eq.model,
                    room=eq.room.name if eq.room else None,
                )
                if eq
                else None
            ),
            equipment_history=self._equipment_history(session) if eq else [],
            photos=photos,
            videos=videos,
            description=session.description,
            conversation=user_texts,
            history=history,
            completed_actions=done,
            previous_outcomes=outcomes,
        )

    def _equipment_history(self, session: DiagnosticSession) -> list[str]:
        """Au plus 3 antécédents RÉCENTS du même équipement : titre + issue, sans conversation."""
        outcome = {
            "resolved": "résolu",
            "referred": "professionnel recommandé",
            "stopped": "arrêté par sécurité",
            "active": "non terminé",
        }
        lines = []
        for old in self._equipment.sessions_for(session.equipment_id, exclude=session.id, limit=3):
            if old.title:
                lines.append(f"{old.title} ({outcome.get(old.status, old.status)}, {old.updated_at:%m/%Y})")
        return lines

    def _store_analysis(
        self, session: DiagnosticSession, a: DiagnosticAnalysis, manual_doc=None, manual_pages: list[int] | None = None
    ) -> SessionMessage:
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
            manual_document_id=manual_doc,
            manual_pages=manual_pages or None,
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

