"""Schéma strict envoyé à OpenAI (Structured Outputs). Distinct du domaine : pas de contraintes
numériques non supportées, tout est requis ; le mapping vers le domaine valide et borne les valeurs."""
from typing import Literal

from pydantic import BaseModel

ActionType = Literal[
    "ASK_QUESTION",
    "REQUEST_PHOTO",
    "INSTRUCTION",
    "VERIFICATION",
    "SAFETY_STOP",
    "RECOMMEND_PROFESSIONAL",
    "RESOLVED",
]


class WireHypothesis(BaseModel):
    label: str
    confidence: float  # 0.0 à 0.9 ; jamais 1


class WireNextAction(BaseModel):
    action_type: ActionType
    message: str
    choices: list[str]


class WirePart(BaseModel):
    name: str  # pièce ou consommable générique, avec la dimension standard si utile (« joint fibre 15×21 »)
    approx_eur: int  # prix indicatif TTC en France ; 0 si inconnu


class WireEstimate(BaseModel):
    """Estimation indicative. available = false tant qu'aucune hypothèse plausible n'existe (ou en cas de danger)."""

    available: bool
    diy_feasibility: int  # 0 (impossible soi-même) à 10 (très simple)
    difficulty: Literal["easy", "medium", "hard"]
    duration_minutes: int  # durée estimée de la réparation soi-même ; 0 si inconnue
    diy_cost_min: int  # coût total soi-même en euros TTC (pièces + petit matériel)
    diy_cost_max: int
    pro_cost_min: int  # coût d'un artisan en euros TTC (déplacement + main-d'œuvre + pièces)
    pro_cost_max: int
    parts: list[WirePart]


class WireAnalysis(BaseModel):
    title: str
    category: Literal["plumbing", "appliance", "handyman", "electrical", "other"]
    subcategory: str
    observations: list[str]
    hypotheses: list[WireHypothesis]
    missing_information: list[str]
    risk_level: Literal["low", "moderate", "high", "emergency"]
    urgency: Literal["can_wait", "soon", "now"]
    diy_allowed: bool
    next_action: WireNextAction
    required_items: list[str]
    safety_flags: list[
        Literal[
            "gas",
            "smoke_fire",
            "electrical",
            "water_electricity",
            "structural",
            "chemical",
            "pressure",
            "major_leak",
            "manufacturer_warning",
        ]
    ]
    verification_outcome: Literal[
        "none", "resolved", "improved", "unchanged", "worsened", "cannot_determine"
    ]
    # Numéros des pages d'extraits de la notice constructeur sur lesquelles la réponse s'appuie VRAIMENT ([] sinon).
    manual_pages_used: list[int]
    estimate: WireEstimate


EquipmentTypeWire = Literal[
    "dishwasher", "washing_machine", "fridge", "oven", "hob", "boiler", "water_heater", "radiator",
    "air_conditioner", "sink", "washbasin", "shower", "toilet", "tap", "vmc", "electrical_panel",
    "socket", "light", "door", "window", "shutter", "other", "unknown",
]


class WireEquipmentIdentification(BaseModel):
    """Identification d'équipement. Chaîne vide = inconnu (tout est requis en Structured Outputs)."""

    equipment_type: EquipmentTypeWire
    brand: str  # "" si aucune marque n'est visible ou reconnaissable
    model: str  # "" si la référence n'est pas LISIBLE sur l'image
    confidence: float  # 0.0 à 0.9 ; jamais 1
    visible_text: list[str]  # textes réellement lisibles (marque, référence, étiquette)


class WireManualCandidate(BaseModel):
    url: str
    title: str


class WireManualSearch(BaseModel):
    """Résultat de recherche web de notice. Liste vide si aucune notice officielle exacte n'est trouvée."""

    candidates: list[WireManualCandidate]
