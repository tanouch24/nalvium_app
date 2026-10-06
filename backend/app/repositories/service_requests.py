import uuid
from datetime import UTC, datetime

from sqlalchemy import select, update
from sqlalchemy.orm import Session, selectinload

from app.db.models import ServiceRequest, ServiceRequestMedia


class ServiceRequestRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    def add(self, req: ServiceRequest) -> ServiceRequest:
        self._db.add(req)
        self._db.flush()
        return req

    def get_owned(self, request_id: uuid.UUID, user_id: uuid.UUID) -> ServiceRequest | None:
        stmt = (
            select(ServiceRequest)
            .where(ServiceRequest.id == request_id, ServiceRequest.user_id == user_id)
            .options(selectinload(ServiceRequest.media))
        )
        return self._db.execute(stmt).scalar_one_or_none()

    def list_for_user(self, user_id: uuid.UUID, limit: int = 50) -> list[ServiceRequest]:
        stmt = (
            select(ServiceRequest)
            .where(ServiceRequest.user_id == user_id, ServiceRequest.status != "DRAFT")
            .options(selectinload(ServiceRequest.media))
            .order_by(ServiceRequest.created_at.desc())
            .limit(limit)
        )
        return list(self._db.execute(stmt).scalars())

    def draft_for_session(self, session_id: uuid.UUID, user_id: uuid.UUID) -> ServiceRequest | None:
        stmt = (
            select(ServiceRequest)
            .where(
                ServiceRequest.diagnostic_session_id == session_id,
                ServiceRequest.user_id == user_id,
                ServiceRequest.status == "DRAFT",
            )
            .options(selectinload(ServiceRequest.media))
            .limit(1)
        )
        return self._db.execute(stmt).scalar_one_or_none()

    def set_media(self, req: ServiceRequest, media_ids: list[uuid.UUID]) -> None:
        req.media.clear()
        self._db.flush()
        for mid in dict.fromkeys(media_ids):
            req.media.append(ServiceRequestMedia(media_asset_id=mid))
        self._db.flush()

    def claim_notification(self, request_id: uuid.UUID) -> bool:
        """Réservation ATOMIQUE de l'envoi : un seul appelant obtient True par demande (retry, double clic, concurrence)."""
        res = self._db.execute(
            update(ServiceRequest)
            .where(ServiceRequest.id == request_id, ServiceRequest.notification_status.is_(None))
            .values(notification_status="sending", notification_attempted_at=datetime.now(UTC))
        )
        self._db.commit()
        return res.rowcount == 1

    def record_notification(self, request_id: uuid.UUID, status: str, error: str | None) -> None:
        self._db.execute(
            update(ServiceRequest).where(ServiceRequest.id == request_id).values(
                notification_status=status, notification_error=error,
                notification_sent_at=datetime.now(UTC) if status == "sent" else None,
            )
        )
        self._db.commit()

    def commit(self) -> None:
        self._db.commit()
