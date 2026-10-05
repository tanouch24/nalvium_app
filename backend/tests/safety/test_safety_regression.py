"""Non-régression : ces situations doivent TOUJOURS déclencher un STOP."""
import pytest

from app.safety import SafetyHazard, SafetyInput, evaluate
from app.safety.engine import STOP_TITLE

DANGEROUS = [
    ("Ça sent le gaz dans la cuisine", SafetyHazard.GAS),
    ("j'ai une odeur de gaz près de la chaudière", SafetyHazard.GAS),
    ("il y a de la fumée qui sort du four", SafetyHazard.SMOKE_FIRE),
    ("Un début d'incendie dans la prise", SafetyHazard.SMOKE_FIRE),
    ("Ça brûle près du radiateur", SafetyHazard.SMOKE_FIRE),
    ("je vois des fils dénudés derrière la plinthe", SafetyHazard.ELECTRICAL),
    ("des fils nus sortent du mur", SafetyHazard.ELECTRICAL),
    ("je veux ouvrir le tableau électrique", SafetyHazard.ELECTRICAL),
    ("le disjoncteur saute sans arrêt", SafetyHazard.ELECTRICAL),
    ("je veux changer la prise sous tension", SafetyHazard.ELECTRICAL),
    ("la prise chauffe et a noirci", SafetyHazard.ELECTRICAL),
    ("de l'eau coule sur la multiprise", SafetyHazard.WATER_ELECTRICITY),
    ("la fuite touche la prise de la salle de bain", SafetyHazard.WATER_ELECTRICITY),
    ("il y a une fissure large dans le mur porteur", SafetyHazard.STRUCTURAL),
    ("le plafond s'affaisse", SafetyHazard.STRUCTURAL),
    ("j'ai mélangé de l'eau de javel et un détartrant", SafetyHazard.CHEMICAL),
    ("je pense qu'il y a de l'amiante", SafetyHazard.CHEMICAL),
    ("la soupape du ballon d'eau chaude siffle", SafetyHazard.PRESSURE),
    ("la chaudière perd de la pression et fuit", SafetyHazard.PRESSURE),
    ("c'est une inondation, ça coule de partout", SafetyHazard.MAJOR_LEAK),
    ("le tuyau a éclaté et je n'arrive pas à l'arrêter", SafetyHazard.MAJOR_LEAK),
    ("la notice dit ne pas ouvrir cet appareil", SafetyHazard.MANUFACTURER_WARNING),
    ("il y a un condensateur à l'intérieur", SafetyHazard.MANUFACTURER_WARNING),
]


@pytest.mark.parametrize(("text", "hazard"), DANGEROUS)
def test_dangerous_description_triggers_stop(text, hazard):
    decision = evaluate(SafetyInput(description=text))
    assert decision.stop, text
    assert hazard in decision.hazards, (text, decision.hazards)
    assert decision.title == STOP_TITLE
    assert decision.explanation


def test_danger_in_later_conversation_turn_triggers_stop():
    decision = evaluate(
        SafetyInput(description="Mon robinet goutte", conversation=("Et ça sent le gaz maintenant",))
    )
    assert decision.stop


def test_accents_case_and_punctuation_are_ignored():
    assert evaluate(SafetyInput(description="FUMÉE!!! dans la pièce")).stop


@pytest.mark.parametrize(
    "text",
    [
        "Mon robinet de cuisine goutte",
        "Le siphon sous l'évier fuit un peu",
        "La chasse d'eau coule en continu",
        "Mon lave-linge ne vidange plus",
        "Une étagère se décroche du mur",
    ],
)
def test_benign_problems_do_not_stop(text):
    assert not evaluate(SafetyInput(description=text)).stop


def test_ai_emergency_signal_triggers_stop():
    from app.domain.diagnosis import RiskLevel

    decision = evaluate(SafetyInput(description="rien", ai_risk_level=RiskLevel.EMERGENCY))
    assert decision.stop
    assert SafetyHazard.AI_EMERGENCY in decision.hazards


def test_ai_flag_triggers_stop():
    decision = evaluate(SafetyInput(description="rien", ai_flags=(SafetyHazard.GAS,)))
    assert decision.stop


@pytest.mark.parametrize(
    "text",
    [
        "Il y a un courant d'air froid sous la porte",
        "J'ai du courant d'air près de la fenêtre",
        "La prise d'eau du lave-linge goutte",
        "L'arrivée d'eau du lave-vaisselle fuit",
        "Il y a de l'eau courante dans la cuisine mais pas dans la salle de bain",
    ],
)
def test_ambiguous_words_in_benign_context_do_not_stop(text):
    assert not evaluate(SafetyInput(description=text)).stop, text


@pytest.mark.parametrize(
    "text",
    [
        "Il y a une coupure de courant dans la cuisine",
        "Je veux couper le courant pour changer la prise",
        "il n'y a plus de courant dans la pièce",
        "le courant électrique passe encore",
    ],
)
def test_real_electrical_context_still_stops(text):
    assert evaluate(SafetyInput(description=text)).stop, text


def test_ai_instruction_leading_to_hazard_is_blocked():
    decision = evaluate(SafetyInput(ai_instruction="Ouvrez le tableau électrique et coupez le disjoncteur"))
    assert decision.stop
    assert not evaluate(SafetyInput(ai_instruction="Fermez le robinet d'arrêt sous le lavabo")).stop
