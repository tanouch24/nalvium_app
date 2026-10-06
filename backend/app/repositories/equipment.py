import uuid

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db.models import DiagnosticSession, Equipment, Home, Room, SessionMessage
from app.equipment.catalog import room_label


class HomeRepository:
    """Toutes les lectures passent par la Maison de l'utilisateur : c'est le contrôle de propriété."""

    def __init__(self, db: Session) -> None:
        self._db = db

    def default_home(self, user_id: uuid.UUID) -> Home:
        stmt = select(Home).where(Home.user_id == user_id, Home.is_default.is_(True))
        home = self._db.execute(stmt).scalar_one_or_none()
        if home is not None:
            return home
        home = Home(user_id=user_id)
        self._db.add(home)
        try:
            self._db.commit()
        except IntegrityError:  # deux requêtes simultanées : l'index unique garantit une seule Maison
            self._db.rollback()
            return self._db.execute(stmt).scalar_one()
        return home

    def rooms(self, home_id: uuid.UUID) -> list[Room]:
        stmt = select(Room).where(Room.home_id == home_id).order_by(Room.created_at)
        return list(self._db.execute(stmt).scalars())

    def room_for(self, home_id: uuid.UUID, room_type: str) -> Room:
        stmt = select(Room).where(Room.home_id == home_id, Room.normalized_type == room_type)
        room = self._db.execute(stmt).scalars().first()
        if room is None:
            room = Room(home_id=home_id, normalized_type=room_type, name=room_label(room_type))
            self._db.add(room)
            self._db.flush()
        return room


class EquipmentRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    def add(self, item: Equipment) -> Equipment:
        self._db.add(item)
        self._db.flush()
        return item

    def get_owned(self, equipment_id: uuid.UUID, user_id: uuid.UUID) -> Equipment | None:
        stmt = (
            select(Equipment)
            .join(Home, Equipment.home_id == Home.id)
            .where(Equipment.id == equipment_id, Home.user_id == user_id)
        )
        return self._db.execute(stmt).unique().scalar_one_or_none()

    def list_for_home(self, home_id: uuid.UUID) -> list[Equipment]:
        stmt = select(Equipment).where(Equipment.home_id == home_id).order_by(Equipment.created_at)
        return list(self._db.execute(stmt).unique().scalars())

    def diagnostic_counts(self, home_id: uuid.UUID) -> dict[uuid.UUID, int]:
        """Une seule requête groupée (pas de N+1). Seules les sessions réellement démarrées comptent."""
        stmt = (
            select(DiagnosticSession.equipment_id, func.count(DiagnosticSession.id))
            .join(Equipment, Equipment.id == DiagnosticSession.equipment_id)
            .where(
                Equipment.home_id == home_id,
                DiagnosticSession.id.in_(select(SessionMessage.session_id).distinct()),
            )
            .group_by(DiagnosticSession.equipment_id)
        )
        return {eid: n for eid, n in self._db.execute(stmt).all()}

    def sessions_for(self, equipment_id: uuid.UUID, *, exclude: uuid.UUID | None = None,
                     limit: int = 50) -> list[DiagnosticSession]:
        stmt = (
            select(DiagnosticSession)
            .where(
                DiagnosticSession.equipment_id == equipment_id,
                DiagnosticSession.id.in_(select(SessionMessage.session_id).distinct()),
            )
            .order_by(DiagnosticSession.updated_at.desc())
            .limit(limit)
        )
        if exclude:
            stmt = stmt.where(DiagnosticSession.id != exclude)
        return list(self._db.execute(stmt).unique().scalars())

    def photo_in_use(self, media_id: uuid.UUID) -> bool:
        return self._db.execute(
            select(Equipment.id).where(Equipment.primary_media_id == media_id).limit(1)
        ).first() is not None

    def detach_sessions(self, equipment_id: uuid.UUID) -> None:
        for s in self._db.execute(
            select(DiagnosticSession).where(DiagnosticSession.equipment_id == equipment_id)
        ).unique().scalars():
            s.equipment_id = None
            s.equipment = None

    def delete(self, item: Equipment) -> None:
        self._db.delete(item)
        self._db.flush()

    def commit(self) -> None:
        self._db.commit()
