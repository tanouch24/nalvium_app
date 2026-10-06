"""Maison : équipements, pièces, photos privées et identification sur photo (hors diagnostic)."""
import uuid
from dataclasses import dataclass

from app.ai.provider import AIProvider
from app.db.models import DiagnosticSession, Equipment, Home, MediaAsset, Room
from app.domain.diagnosis import EquipmentIdentification
from app.equipment.catalog import (
    ROOM_TYPES,
    SLUG_RE,
    detect_type,
    label_for,
)
from app.media.pipeline import ProcessedImage, make_thumbnail
from app.media.storage import MediaStorage
from app.repositories.equipment import EquipmentRepository, HomeRepository
from app.repositories.sessions import MediaRepository, UserRepository
from app.services.session_service import NotFound

MAX_NAME, MAX_BRAND, MAX_MODEL = 80, 60, 80


class InvalidEquipment(Exception):
    pass


@dataclass(frozen=True)
class EquipmentInput:
    """Champs de création (un PATCH passe un dict des seules clés fournies)."""

    equipment_type: str | None = None
    display_name: str | None = None
    room_type: str | None = None
    brand: str | None = None
    model: str | None = None
    primary_media_id: uuid.UUID | None = None


@dataclass(frozen=True)
class EquipmentRow:
    equipment: Equipment
    diagnostics: int


@dataclass(frozen=True)
class HomeView:
    home: Home
    rooms: list[Room]
    items: list[EquipmentRow]


@dataclass(frozen=True)
class EquipmentSuggestions:
    detected_type: str | None
    matches: list[Equipment]


def _clean(value: str | None, limit: int) -> str | None:
    value = " ".join((value or "").split())
    return value[:limit] or None


class EquipmentService:
    def __init__(
        self,
        users: UserRepository,
        homes: HomeRepository,
        equipment: EquipmentRepository,
        media: MediaRepository,
        storage: MediaStorage,
        provider: AIProvider,
        documents=None,
    ) -> None:
        self._documents = documents  # DocumentRepository | None
        self._users, self._homes, self._equipment = users, homes, equipment
        self._media, self._storage, self._provider = media, storage, provider

    # ---- Maison -------------------------------------------------------------
    def _home(self, user_id: uuid.UUID) -> Home:
        self._users.ensure(user_id)
        return self._homes.default_home(user_id)

    def home(self, user_id: uuid.UUID) -> HomeView:
        home = self._home(user_id)
        counts = self._equipment.diagnostic_counts(home.id)
        items = [EquipmentRow(e, counts.get(e.id, 0)) for e in self._equipment.list_for_home(home.id)]
        return HomeView(home, self._homes.rooms(home.id), items)

    # ---- équipements --------------------------------------------------------
    def create(self, user_id: uuid.UUID, data: EquipmentInput) -> Equipment:
        home = self._home(user_id)
        etype = self._valid_type(data.equipment_type)
        item = Equipment(
            home_id=home.id,
            equipment_type=etype,
            display_name=_clean(data.display_name, MAX_NAME) or label_for(etype),
            brand=_clean(data.brand, MAX_BRAND),
            model=_clean(data.model, MAX_MODEL),
        )
        if data.room_type:
            item.room = self._homes.room_for(home.id, self._valid_room(data.room_type))
        if data.primary_media_id:
            item.primary_media_id = self._photo_for_equipment(user_id, data.primary_media_id).id
        self._equipment.add(item)
        self._equipment.commit()
        return item

    def get(self, user_id: uuid.UUID, equipment_id: uuid.UUID) -> Equipment:
        item = self._equipment.get_owned(equipment_id, user_id)
        if item is None:
            raise NotFound
        return item

    def diagnostics(self, user_id: uuid.UUID, equipment_id: uuid.UUID) -> list[DiagnosticSession]:
        self.get(user_id, equipment_id)
        return self._equipment.sessions_for(equipment_id)

    def update(self, user_id: uuid.UUID, equipment_id: uuid.UUID, fields: dict) -> Equipment:
        """`fields` ne contient QUE les clés fournies par le client ; une valeur vide efface (marque/modèle/pièce)."""
        item = self.get(user_id, equipment_id)
        if fields.get("equipment_type"):
            item.equipment_type = self._valid_type(fields["equipment_type"])
        if "display_name" in fields:
            name = _clean(fields["display_name"], MAX_NAME)
            if not name:
                raise InvalidEquipment("empty_name")
            item.display_name = name
        old_ref = (item.brand, item.model)
        if "brand" in fields:
            item.brand = _clean(fields["brand"], MAX_BRAND)
        if "model" in fields:
            item.model = _clean(fields["model"], MAX_MODEL)
        if (item.brand, item.model) != old_ref:
            self._drop_manual(item.id)  # la notice ne correspond plus à l'appareil : on ne la garde pas
        if "room_type" in fields:
            room_type = fields["room_type"]
            item.room = self._homes.room_for(item.home_id, self._valid_room(room_type)) if room_type else None
        if "primary_media_id" in fields:
            self._set_primary(user_id, item, fields["primary_media_id"])
        self._equipment.commit()
        return self.get(user_id, equipment_id)

    def delete(self, user_id: uuid.UUID, equipment_id: uuid.UUID) -> None:
        """Supprime l'équipement ET sa photo ; les diagnostics sont conservés, simplement détachés."""
        item = self.get(user_id, equipment_id)
        photo_id = item.primary_media_id
        self._drop_manual(item.id)
        self._equipment.detach_sessions(item.id)
        self._equipment.delete(item)
        if photo_id:
            self._drop_media(user_id, photo_id)
        self._equipment.commit()

    def _drop_manual(self, equipment_id: uuid.UUID) -> None:
        if self._documents is None:
            return
        for key in self._documents.storage_keys(equipment_id):
            self._storage.delete(key)
        self._documents.delete_for_equipment(equipment_id)

    # ---- photos -------------------------------------------------------------
    def add_photo(self, user_id: uuid.UUID, image: ProcessedImage) -> MediaAsset:
        """Photo d'équipement PRIVÉE (EXIF déjà retiré), sans session, avec vignette."""
        self._users.ensure(user_id)
        media_id = uuid.uuid4()
        key, thumb_key = f"{user_id}/{media_id}.jpg", f"{user_id}/{media_id}_t.jpg"
        self._storage.put(key, image.data)
        self._storage.put(thumb_key, make_thumbnail(image))
        asset = MediaAsset(
            id=media_id, user_id=user_id, session_id=None, kind="photo", storage_key=key,
            thumb_key=thumb_key, content_type=image.content_type, size_bytes=len(image.data),
            width=image.width, height=image.height, exif_stripped=True, visibility="private",
        )
        return self._media.add(asset)

    def discard_photo(self, user_id: uuid.UUID, media_id: uuid.UUID) -> None:
        """Abandon explicite : supprime immédiatement une photo d'équipement TEMPORAIRE (jamais celle d'un équipement,
        jamais un média de session)."""
        asset = self._photo_for_equipment_or_404(user_id, media_id)
        if self._equipment.photo_in_use(asset.id):
            raise NotFound
        self._drop_media(user_id, asset.id)
        self._equipment.commit()

    def _photo_for_equipment(self, user_id: uuid.UUID, media_id: uuid.UUID) -> MediaAsset:
        asset = self._media.get_owned(media_id, user_id)
        if asset is None or asset.kind != "photo" or asset.session_id is not None:
            raise InvalidEquipment("unknown_media")
        return asset

    def _set_primary(self, user_id: uuid.UUID, item: Equipment, media_id: uuid.UUID | None) -> None:
        previous = item.primary_media_id
        if media_id is None:
            item.primary_media_id = None
        elif media_id != previous:
            item.primary_media_id = self._photo_for_equipment(user_id, media_id).id
        else:
            return
        self._equipment.commit()  # détache la référence avant de supprimer l'ancien fichier
        if previous and previous != item.primary_media_id:
            self._drop_media(user_id, previous)

    def _drop_media(self, user_id: uuid.UUID, media_id: uuid.UUID) -> None:
        asset = self._media.get_owned(media_id, user_id)
        if asset is None or asset.session_id is not None:
            return
        for key in (asset.storage_key, asset.thumb_key):
            if key:
                self._storage.delete(key)
        self._media.delete(asset)

    # ---- identification (PAS un diagnostic : aucune session) -----------------
    async def identify(self, user_id: uuid.UUID, media_id: uuid.UUID) -> EquipmentIdentification:
        asset = self._photo_for_equipment_or_404(user_id, media_id)
        result = await self._provider.identify_equipment(
            self._storage.get(asset.storage_key), asset.content_type
        )
        # Un type hors catalogue devient « unknown » : l'app propose alors de choisir.
        if result.equipment_type != "unknown" and not SLUG_RE.match(result.equipment_type):
            result = result.model_copy(update={"equipment_type": "unknown"})
        return result

    def _photo_for_equipment_or_404(self, user_id: uuid.UUID, media_id: uuid.UUID) -> MediaAsset:
        try:
            return self._photo_for_equipment(user_id, media_id)
        except InvalidEquipment as exc:
            raise NotFound from exc

    # ---- suggestions de rattachement ----------------------------------------
    def suggestions(self, user_id: uuid.UUID, session: DiagnosticSession) -> EquipmentSuggestions:
        """Propose (jamais ne lie) : type probable d'après le titre/la description + équipements existants."""
        detected = detect_type(session.title, session.subcategory, session.description)
        if detected is None:
            return EquipmentSuggestions(None, [])
        home = self._home(user_id)
        matches = [e for e in self._equipment.list_for_home(home.id) if e.equipment_type == detected]
        return EquipmentSuggestions(detected, matches)

    @staticmethod
    def _valid_type(value: str | None) -> str:
        value = (value or "other").strip().lower()
        if not SLUG_RE.match(value):
            raise InvalidEquipment("invalid_type")
        return value

    @staticmethod
    def _valid_room(value: str) -> str:
        value = value.strip().lower()
        if value not in ROOM_TYPES:
            raise InvalidEquipment("invalid_room")
        return value
