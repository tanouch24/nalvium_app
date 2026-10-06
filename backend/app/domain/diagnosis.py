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
    # Pages de la notice constructeur réellement utilisées pour cette réponse (sous-ensemble des extraits fournis).
    manual_pages_used: list[int] = Field(default_factory=list)


class MediaRef(BaseModel):
    media_id: str
    kind: str = "photo"
    mime: str = "image/jpeg"
    # Octets de l'image traitée (jamais sérialisés ni loggés).
    data: bytes | None = Field(default=None, exclude=True, repr=False)


class VideoFrameInput(BaseModel):
    """Image représentative extraite d'une vidéo, avec son horodatage approximatif (secondes)."""

    t: float
    data: bytes = Field(exclude=True, repr=False)
    mime: str = "image/jpeg"


class VideoDiagnosticInput(BaseModel):
    """Contexte vidéo fourni au moteur. Le fournisseur n'accepte pas la vidéo native : il reçoit des images
    ordonnées dans le temps. L'audio n'est PAS analysé (seule sa présence est indiquée)."""

    media_id: str
    duration_s: float
    has_audio: bool
    frames: list[VideoFrameInput] = Field(default_factory=list)


class EquipmentContext(BaseModel):
    """Équipement de la Maison auquel se rattache le diagnostic (déclaré ou confirmé par l'utilisateur)."""

    type: str
    name: str
    brand: str | None = None
    model: str | None = None
    room: str | None = None


class ManualCandidate(BaseModel):
    """Lien proposé par la recherche web. Rien n'est fiable tant que la source n'est pas validée (domaine officiel,
    PDF, correspondance exacte de la référence)."""

    url: str
    title: str = ""


class ManualExcerpt(BaseModel):
    page: int
    section: str | None = None
    text: str


class ManualContext(BaseModel):
    """Extraits de LA notice constructeur liée à l'équipement (document exact), sélectionnés pour ce tour."""

    manufacturer: str | None = None
    model: str | None = None
    exact: bool = True  # False : référence proche, notice confirmée par l'utilisateur
    excerpts: list[ManualExcerpt] = Field(default_factory=list)


class EquipmentIdentification(BaseModel):
    """Proposition d'identification d'un équipement sur photo. Ce n'est PAS un diagnostic et ce n'est jamais
    une certitude : l'utilisateur confirme toujours (needs_confirmation reste vrai)."""

    equipment_type: str  # slug du catalogue, ou "unknown"
    brand: str | None = None
    model: str | None = None  # uniquement si lisible sur l'image
    confidence: float = Field(ge=0.0, lt=1.0)
    visible_text: list[str] = Field(default_factory=list)
    needs_confirmation: bool = True


class DiagnosticContext(BaseModel):
    """Ce que reçoit l'IA à chaque tour."""

    session_id: str
    photos: list[MediaRef] = Field(default_factory=list)
    videos: list[VideoDiagnosticInput] = Field(default_factory=list)
    description: str | None = None
    # Textes écrits PAR L'UTILISATEUR uniquement (base du Safety pre-check).
    conversation: list[str] = Field(default_factory=list)
    # Transcription complète (utilisateur + Nalvium) fournie à l'IA comme contexte.
    history: list[str] = Field(default_factory=list)
    equipment: EquipmentContext | None = None
    # Antécédents LIMITÉS du même équipement : contexte seulement, jamais une preuve de la cause actuelle.
    equipment_history: list[str] = Field(default_factory=list)
    manual: ManualContext | None = None
    completed_actions: list[str] = Field(default_factory=list)
    previous_outcomes: list[VerificationOutcome] = Field(default_factory=list)
