"""ServiceAreaPolicy : décide IN_ZONE / OUT_OF_ZONE à partir de la VILLE et du CODE POSTAL (jamais de GPS)."""
import math
import re
from dataclasses import dataclass

from app.service_area.config import ACTIVE_AREAS, EPSILON_KM, ServiceArea
from app.service_area.referential import Commune, Referential, load_referential, normalize_city

EARTH_RADIUS_KM = 6371.0088


class AreaError(Exception):
    """Ville / code postal inexploitables. `code` est stable : invalid_postal_code, unknown_postal_code,
    unknown_city, city_postal_mismatch."""

    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


@dataclass(frozen=True)
class AreaDecision:
    in_zone: bool
    commune: str
    area: str | None  # zone qui couvre la commune (None si hors zone)
    distance_km: float  # distance au centre de la zone la plus proche (usage interne, jamais exposée)


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    p1, p2 = math.radians(lat1), math.radians(lat2)
    a = math.sin((p2 - p1) / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(math.radians(lon2 - lon1) / 2) ** 2
    return 2 * EARTH_RADIUS_KM * math.asin(math.sqrt(a))


class ServiceAreaPolicy:
    def __init__(self, areas: tuple[ServiceArea, ...] = ACTIVE_AREAS, referential: Referential | None = None) -> None:
        self._areas = areas
        self._ref = referential or load_referential()

    @property
    def areas(self) -> tuple[ServiceArea, ...]:
        return self._areas

    def _match(self, city: str, postal_code: str) -> Commune:
        code = (postal_code or "").strip().replace(" ", "")
        if not re.fullmatch(r"\d{5}", code):
            raise AreaError("invalid_postal_code")
        if code not in self._ref.by_postal:
            raise AreaError("unknown_postal_code")
        key = normalize_city(city)
        named = self._ref.by_name.get(key)
        if not key or not named:
            raise AreaError("unknown_city")
        matches = [c for c in named if code in c.postal_codes]
        if not matches:
            raise AreaError("city_postal_mismatch")  # jamais d'association silencieuse
        return matches[0]

    def evaluate(self, city: str, postal_code: str) -> AreaDecision:
        commune = self._match(city, postal_code)
        best_area, best_distance = None, math.inf
        for area in self._areas:
            d = haversine_km(area.center_lat, area.center_lon, commune.lat, commune.lon)
            best_distance = min(best_distance, d)
            if d <= area.radius_km + EPSILON_KM and best_area is None:
                best_area = area
        return AreaDecision(best_area is not None, commune.name, best_area.name if best_area else None, best_distance)
