"""Modèles du domaine pour le diagnostic guidé (indépendants de tout provider IA)."""
from enum import StrEnum

from pydantic import BaseModel, Field


class RiskLevel(StrEnum):
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"
    EMERGENCY = "emergency"

    @property
    def rank(self) -> int:
        return list(RiskLevel).index(self)


class Urgency(StrEnum):
    CAN_WAIT = "can_wait"
    SOON = "soon"
    NOW = "now"


class Category(StrEnum):
    PLUMBING = "plumbing"
    APPLIANCE = "appliance"
    HANDYMAN = "handyman"
    ELECTRICAL = "electrical"
    OTHER = "other"


class NextActionType(StrEnum):
    ASK_QUESTION = "ASK_QUESTION"
    REQUEST_PHOTO = "REQUEST_PHOTO"
    INSTRUCTION = "INSTRUCTION"
    VERIFICATION = "VERIFICATION"
    SAFETY_STOP = "SAFETY_STOP"
    RECOMMEND_PROFESSIONAL = "RECOMMEND_PROFESSIONAL"
    RESOLVED = "RESOLVED"


class VerificationOutcome(StrEnum):
    RESOLVED = "resolved"
    IMPROVED = "improved"
    UNCHANGED = "unchanged"
    WORSENED = "worsened"
    CANNOT_DETERMINE = "cannot_determine"


class NextAction(BaseModel):
    """Une seule action à la fois, jamais une liste d'étapes."""

    type: NextActionType
    message: str = Field(min_length=1, description="Texte affiché à l'utilisateur, en français")
    # Réponses rapides proposées (ex. « C'est fait », « Je n'y arrive pas »).
    choices: list[str] = Field(default_factory=list)


class Hypothesis(BaseModel):
    """Une hypothèse n'est jamais une certitude : confidence est toujours < 1."""

    label: str
    confidence: float = Field(ge=0.0, lt=1.0)


class DiagnosticAnalysis(BaseModel):
    """Sortie structurée du moteur IA (contrat provider-agnostique)."""

    category: Category
    subcategory: str | None = None
    observations: list[str] = Field(default_factory=list)
    hypotheses: list[Hypothesis] = Field(default_factory=list)
    missing_information: list[str] = Field(default_factory=list)
    risk_level: RiskLevel
    urgency: Urgency
    diy_allowed: bool
    next_action: NextAction
    required_items: list[str] = Field(default_factory=list)
    title: str = ""
    # Dangers repérés par l'IA (ex. fils nus sur une photo) : ne servent qu'à durcir la décision.
    safety_flags: list[str] = Field(default_factory=list)
    # Évaluation par l'IA de la réponse de l'utilisateur à la dernière VERIFICATION.
    verification_outcome: VerificationOutcome | None = None


class MediaRef(BaseModel):
    media_id: str
    kind: str = "photo"
    mime: str = "image/jpeg"
    # Octets de l'image traitée (jamais sérialisés ni loggés).
    data: bytes | None = Field(default=None, exclude=True, repr=False)


class DiagnosticContext(BaseModel):
    """Ce que reçoit l'IA à chaque tour."""

    session_id: str
    photos: list[MediaRef] = Field(default_factory=list)
    description: str | None = None
    # Textes écrits PAR L'UTILISATEUR uniquement (base du Safety pre-check).
    conversation: list[str] = Field(default_factory=list)
    # Transcription complète (utilisateur + Nalvium) fournie à l'IA comme contexte.
    history: list[str] = Field(default_factory=list)
    equipment: str | None = None
    completed_actions: list[str] = Field(default_factory=list)
    previous_outcomes: list[VerificationOutcome] = Field(default_factory=list)
