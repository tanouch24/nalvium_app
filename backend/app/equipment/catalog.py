"""Catalogues courts et extensibles : types d'équipements et pièces.

Volontairement petit. Un type inconnu reste accepté (slug libre) : l'app affiche alors « Autre »."""
import re
import unicodedata

# slug -> libellé affiché
EQUIPMENT_TYPES: dict[str, str] = {
    "dishwasher": "Lave-vaisselle",
    "washing_machine": "Lave-linge",
    "fridge": "Réfrigérateur",
    "oven": "Four",
    "hob": "Plaque",
    "boiler": "Chaudière",
    "water_heater": "Chauffe-eau",
    "radiator": "Radiateur",
    "air_conditioner": "Climatisation",
    "sink": "Évier",
    "washbasin": "Lavabo",
    "shower": "Douche",
    "toilet": "WC",
    "tap": "Robinet",
    "vmc": "VMC",
    "electrical_panel": "Tableau électrique",
    "socket": "Prise",
    "light": "Luminaire",
    "door": "Porte",
    "window": "Fenêtre",
    "shutter": "Volet",
    "other": "Autre",
}

# normalized_type -> libellé
ROOM_TYPES: dict[str, str] = {
    "kitchen": "Cuisine",
    "bathroom": "Salle de bain",
    "living": "Salon",
    "bedroom": "Chambre",
    "laundry": "Buanderie",
    "garage": "Garage",
    "outdoor": "Extérieur",
    "other": "Autre",
}

SLUG_RE = re.compile(r"^[a-z][a-z0-9_]{0,31}$")

# mots-clés (sans accents, minuscules) -> type ; sert à PROPOSER un type, jamais à lier seul
_KEYWORDS: list[tuple[str, tuple[str, ...]]] = [
    ("dishwasher", ("lave-vaisselle", "lave vaisselle", "lavevaisselle")),
    ("washing_machine", ("lave-linge", "lave linge", "machine a laver")),
    ("fridge", ("refrigerateur", "frigo", "congelateur")),
    ("oven", ("four ",)),
    ("hob", ("plaque", "cuisiniere")),
    ("boiler", ("chaudiere",)),
    ("water_heater", ("chauffe-eau", "chauffe eau", "cumulus", "ballon d'eau")),
    ("radiator", ("radiateur",)),
    ("air_conditioner", ("climatisation", "climatiseur", "clim ")),
    ("sink", ("evier", "siphon")),
    ("washbasin", ("lavabo", "vasque")),
    ("shower", ("douche",)),
    ("toilet", ("wc", "toilette", "chasse d'eau", "chasse-d'eau", "cuvette")),
    ("tap", ("robinet", "mitigeur")),
    ("vmc", ("vmc", "ventilation")),
    ("electrical_panel", ("tableau electrique", "disjoncteur")),
    ("socket", ("prise",)),
    ("light", ("luminaire", "lampe", "ampoule", "plafonnier")),
    ("door", ("porte",)),
    ("window", ("fenetre",)),
    ("shutter", ("volet",)),
]


def normalize(text: str) -> str:
    folded = unicodedata.normalize("NFKD", text.lower())
    return "".join(c for c in folded if not unicodedata.combining(c))


def label_for(equipment_type: str) -> str:
    return EQUIPMENT_TYPES.get(equipment_type, EQUIPMENT_TYPES["other"])


def room_label(room_type: str) -> str:
    return ROOM_TYPES.get(room_type, ROOM_TYPES["other"])


def detect_type(*texts: str | None) -> str | None:
    """Type d'équipement probablement évoqué par ces textes (titre, sous-catégorie, description)."""
    haystack = " " + normalize(" ".join(t for t in texts if t)) + " "
    for slug, words in _KEYWORDS:
        if any(w in haystack for w in words):
            return slug
    return None
