"""Safety Engine déterministe.

Principe : la sécurité passe AVANT l'IA et l'IA ne peut jamais contourner une décision STOP.
Le moteur est volontairement conservateur : un faux positif (arrêt inutile) est acceptable,
un faux négatif (instruction DIY dans une situation dangereuse) ne l'est pas. Les négations
("pas de gaz") ne sont donc PAS interprétées.

Ce squelette couvre la détection par texte (description, conversation). La détection visuelle
(photo) sera branchée en phase ultérieure via `SafetyInput.ai_risk_level` / `ai_flags`.
"""
import re
import unicodedata
from dataclasses import dataclass, field
from enum import StrEnum

from app.domain.diagnosis import (
    DiagnosticAnalysis,
    NextAction,
    NextActionType,
    RiskLevel,
    Urgency,
)


class SafetyHazard(StrEnum):
    GAS = "gas"
    SMOKE_FIRE = "smoke_fire"
    ELECTRICAL = "electrical"
    WATER_ELECTRICITY = "water_electricity"
    STRUCTURAL = "structural"
    CHEMICAL = "chemical"
    PRESSURE = "pressure"
    MAJOR_LEAK = "major_leak"
    MANUFACTURER_WARNING = "manufacturer_warning"
    AI_EMERGENCY = "ai_emergency"


@dataclass(frozen=True)
class SafetyRule:
    hazard: SafetyHazard
    patterns: tuple[str, ...]
    reason: str  # explication simple, en français, affichée à l'utilisateur


# Expressions courantes qui contiennent un mot déclencheur sans être un danger.
# Liste explicite et testée, pas de NLP : on neutralise ces tournures avant les règles.
_BENIGN_PHRASES = re.compile(
    r"\bcourants? d air\b|\beau courante\b|\bprises? d eau\b|\barrivees? d eau\b"
    r"|\bcourant d eau\b|\bprises? de (tete|courant d air)\b"
)


def normalize(text: str) -> str:
    """minuscules, sans accents, apostrophes/ponctuation → espaces ; tournures bénignes retirées."""
    text = unicodedata.normalize("NFKD", text.lower())
    text = "".join(c for c in text if not unicodedata.combining(c))
    text = re.sub(r"[^a-z0-9]+", " ", text).strip()
    return _BENIGN_PHRASES.sub(" ", text)


RULES: tuple[SafetyRule, ...] = (
    SafetyRule(
        SafetyHazard.GAS,
        (r"\bgaz\b", r"odeur de gaz", r"\bgpl\b", r"\bbutane\b", r"\bpropane\b"),
        "Une fuite de gaz peut provoquer une explosion ou une intoxication. "
        "Aérez, n'actionnez aucun interrupteur, sortez, puis appelez le 112 ou votre fournisseur.",
    ),
    SafetyRule(
        SafetyHazard.SMOKE_FIRE,
        (r"\bfumee", r"\bincendie", r"\bfeu\b", r"\bflammes?\b", r"\bbrule", r"\bbrulure",
         r"\bcourt circuit", r"odeur de brule", r"\betincelles?\b"),
        "Fumée ou feu : le danger est immédiat. Sortez et appelez le 18 ou le 112.",
    ),
    SafetyRule(
        SafetyHazard.ELECTRICAL,
        (r"fils? (nus?|denudes?|apparents?|exposes?)", r"\bcables? (nus?|denudes?|apparents?)",
         r"tableau electrique", r"\bdisjoncteur", r"\bdifferentiel", r"\bfusible",
         r"sous tension",
         (r"\b(coupure|panne|couper|coupe|coupez|plus|manque|sous|haute|basse|fort|retablir|rallumer)"
          r"( de| du| le| la| l)* courant\b"),
         r"\bcourant electrique", r"\bprise (qui )?(chauffe|fond|noircie)",
         r"electrocut", r"\bdecharge electrique", r"\bphase\b.*\bneutre\b", r"\bcompteur electrique"),
        "Une installation électrique ne se manipule pas sans qualification. "
        "Le risque d'électrocution ou d'incendie est réel.",
    ),
    SafetyRule(
        SafetyHazard.WATER_ELECTRICITY,
        (r"\beau\b.*\b(prise|electri|tableau|multiprise|rallonge|disjoncteur)",
         r"\b(prise|electri|tableau|multiprise|rallonge|disjoncteur)\b.*\beau\b",
         r"\b(fuite|coule|degat des eaux|inonde)\b.*\b(prise|electri|tableau|multiprise)",
         r"\b(prise|tableau|multiprise)\b.*\b(mouille|humide|trempe)"),
        "L'eau et l'électricité ne font jamais bon ménage. Ne touchez à rien, "
        "coupez le courant au disjoncteur général seulement si vous pouvez l'atteindre sans toucher l'eau.",
    ),
    SafetyRule(
        SafetyHazard.STRUCTURAL,
        (r"\bfissure (large|importante|profonde)", r"mur (qui )?(bouge|penche|se fissure)",
         r"\bplafond (qui )?(s effondre|s affaisse|menace)", r"\beffondrement", r"\bporteur\b",
         r"\bmur porteur", r"\bpoutre (cassee|fissuree)", r"\bs effondre"),
        "Un problème de structure peut mettre le bâtiment en danger. Éloignez-vous de la zone "
        "et faites venir un professionnel.",
    ),
    SafetyRule(
        SafetyHazard.CHEMICAL,
        (r"\bamiante", r"\bmonoxyde", r"\bco\b.*\b(alarme|detecteur)", r"\bacide\b",
         r"melange (d )?(eau de javel|javel)", r"\bjavel\b.*\b(ammoniaque|acide|detartrant)",
         r"\bdecapant", r"\bsolvant", r"\bmoisissures? (noires? )?(etendues?|importantes?)"),
        "Certains produits ou gaz sont dangereux à respirer ou à toucher. Aérez et éloignez-vous.",
    ),
    SafetyRule(
        SafetyHazard.PRESSURE,
        (r"\bchaudiere.*\b(pression|explos|fuite)", r"\bcocotte minute.*\b(explos|bloquee)",
         r"\bsoupape.*\b(siffle|bloquee|fuit)", r"\bballon d eau chaude.*\b(fuite|siffle|explos)",
         r"\bcompresseur.*\bpression", r"\bbouteille de gaz"),
        "Un équipement sous pression peut provoquer des brûlures graves ou une explosion.",
    ),
    SafetyRule(
        SafetyHazard.MAJOR_LEAK,
        (r"\binondation", r"\binonde", r"\bgros jet", r"\bimpossible (de|d) arreter",
         r"\bne s arrete pas", r"\bcanalisation\b.*\b(eclate|casse|perce)", r"\btuyau\b.*\b(eclate|explose|perce|casse)",
         r"\b(arrive|arrivons|peux|peut|parviens|reussis)\w* pas (de |d |a )?(l )?(arreter|stopper|couper|fermer)",
         r"\bcoule de partout", r"\bdegat des eaux (important|majeur)", r"\bfuite (majeure|importante)",
         r"\bfuite (incontrolee|qu on ne peut pas arreter)"),
        "Une fuite importante peut abîmer le logement très vite. Coupez l'arrivée d'eau générale "
        "si vous le pouvez, puis faites venir un professionnel.",
    ),
    SafetyRule(
        SafetyHazard.MANUFACTURER_WARNING,
        (r"\bne pas ouvrir", r"\bdanger\b.*\bconstructeur", r"\binterdit (de )?demonter",
         r"\bintervention reservee", r"\bhaute tension", r"\bcondensateur"),
        "Le constructeur indique que cette intervention est réservée aux professionnels.",
    ),
)

_COMPILED = tuple(
    (rule, tuple(re.compile(p) for p in rule.patterns)) for rule in RULES
)


@dataclass(frozen=True)
class SafetyInput:
    description: str | None = None
    conversation: tuple[str, ...] = ()
    # Signaux venant de l'IA (jamais pour ASSOUPLIR une décision, seulement pour la durcir).
    ai_risk_level: RiskLevel | None = None
    ai_flags: tuple[SafetyHazard, ...] = ()
    # Texte d'une INSTRUCTION produite par l'IA : on refuse qu'elle guide vers un danger.
    ai_instruction: str | None = None

    def texts(self) -> list[str]:
        out = [self.description] if self.description else []
        out.extend(self.conversation)
        if self.ai_instruction:
            out.append(self.ai_instruction)
        return out


@dataclass(frozen=True)
class SafetyDecision:
    stop: bool
    hazards: tuple[SafetyHazard, ...] = ()
    title: str = ""
    explanation: str = ""
    matched_rules: tuple[str, ...] = field(default_factory=tuple)

    @classmethod
    def ok(cls) -> "SafetyDecision":
        return cls(stop=False)


STOP_TITLE = "Arrêtez-vous ici."


def evaluate(inp: SafetyInput) -> SafetyDecision:
    hazards: list[SafetyHazard] = []
    reasons: list[str] = []
    matched: list[str] = []

    corpus = [normalize(t) for t in inp.texts()]
    for rule, patterns in _COMPILED:
        if any(p.search(t) for p in patterns for t in corpus):
            hazards.append(rule.hazard)
            reasons.append(rule.reason)
            matched.append(rule.hazard.value)

    for flag in inp.ai_flags:
        if flag not in hazards:
            hazards.append(flag)
            matched.append(f"ai:{flag.value}")
            reasons.append("Cette situation présente un risque qui dépasse un dépannage simple.")

    if inp.ai_risk_level is RiskLevel.EMERGENCY and SafetyHazard.AI_EMERGENCY not in hazards:
        hazards.append(SafetyHazard.AI_EMERGENCY)
        matched.append("ai:emergency")
        if not any(m.startswith("ai:") for m in matched[:-1]):
            reasons.append("Cette situation présente un danger immédiat.")

    if not hazards:
        return SafetyDecision.ok()
    return SafetyDecision(
        stop=True,
        hazards=tuple(hazards),
        title=STOP_TITLE,
        explanation=" ".join(dict.fromkeys(reasons)),
        matched_rules=tuple(matched),
    )


def parse_flags(raw: list[str]) -> tuple[SafetyHazard, ...]:
    """Convertit les drapeaux texte de l'IA ; les valeurs inconnues sont traitées en prudence."""
    out: list[SafetyHazard] = []
    for item in raw:
        try:
            out.append(SafetyHazard(item))
        except ValueError:
            out.append(SafetyHazard.AI_EMERGENCY)
    return tuple(out)


def enforce(analysis: DiagnosticAnalysis, decision: SafetyDecision) -> DiagnosticAnalysis:
    """Applique la décision au résultat IA. Une décision STOP écrase toujours l'IA."""
    if decision.stop:
        # STOP déclenché UNIQUEMENT par l'IA qui a déjà choisi SAFETY_STOP : on garde son explication
        # (plus précise que le texte générique), tout en forçant les garde-fous.
        ai_only = all(m.startswith("ai:") for m in decision.matched_rules)
        ai_text = analysis.next_action.message.strip()
        if ai_only and analysis.next_action.type is NextActionType.SAFETY_STOP and ai_text:
            body = ai_text if ai_text.lower().startswith(decision.title.lower()) else f"{decision.title} {ai_text}"
            return analysis.model_copy(
                update={
                    "risk_level": RiskLevel.EMERGENCY,
                    "urgency": Urgency.NOW,
                    "diy_allowed": False,
                    "required_items": [],
                    "next_action": NextAction(type=NextActionType.SAFETY_STOP, message=body),
                }
            )
        return analysis.model_copy(
            update={
                "risk_level": RiskLevel.EMERGENCY,
                "urgency": Urgency.NOW,
                "diy_allowed": False,
                "required_items": [],
                "next_action": NextAction(
                    type=NextActionType.SAFETY_STOP,
                    message=f"{decision.title} {decision.explanation}",
                ),
            }
        )

    update: dict = {}
    action = analysis.next_action
    if action.type is NextActionType.SAFETY_STOP:
        # L'IA elle-même demande l'arrêt : jamais de DIY, jamais de risque faible.
        update["diy_allowed"] = False
        update["required_items"] = []
        if analysis.risk_level.rank < RiskLevel.HIGH.rank:
            update["risk_level"] = RiskLevel.HIGH
    elif not analysis.diy_allowed and action.type in (
        NextActionType.INSTRUCTION,
        NextActionType.VERIFICATION,
    ):
        # Pas de bricolage autorisé => on n'affiche pas d'instruction DIY.
        update["required_items"] = []
        update["next_action"] = NextAction(
            type=NextActionType.RECOMMEND_PROFESSIONAL,
            message="Cette intervention nécessite un professionnel.",
        )
    return analysis.model_copy(update=update) if update else analysis
