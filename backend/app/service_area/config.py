"""Configuration CENTRALISÉE de la zone pilote : le seul endroit où figurent « Lyon » et « 50 km ».

Pour élargir plus tard (Lyon 100 km, plusieurs métropoles, région, France entière) : modifier ou compléter
`ACTIVE_AREAS` — rien d'autre n'est à changer dans le code."""
from dataclasses import dataclass


@dataclass(frozen=True)
class ServiceArea:
    name: str
    center_lat: float  # centre de la commune de Lyon (référentiel géographique, pas une position d'utilisateur)
    center_lon: float
    radius_km: float


PILOT_AREA = ServiceArea(name="Lyon", center_lat=45.7580, center_lon=4.8351, radius_km=50.0)

ACTIVE_AREAS: tuple[ServiceArea, ...] = (PILOT_AREA,)

# Tolérance numérique UNIQUEMENT (arrondis des coordonnées du référentiel) : 50 km ne devient jamais 60 km.
EPSILON_KM = 1e-6
