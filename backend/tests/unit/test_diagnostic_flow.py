"""Scénarios de la conversation guidée, avec un provider factice (les tests n'appellent pas d'IA)."""
import pytest

from app.domain.diagnosis import (
    Category,
    DiagnosticAnalysis,
    DiagnosticContext,
    Hypothesis,
    MediaRef,
    NextAction,
    NextActionType,
    RiskLevel,
    Urgency,
    VerificationOutcome,
)
from app.services.diagnostic_service import DiagnosticService


def analysis(action: NextActionType, message="msg", *, risk=RiskLevel.LOW, diy=True, **kw):
    return DiagnosticAnalysis(
        category=Category.PLUMBING,
        subcategory="fuite",
        risk_level=risk,
        urgency=Urgency.SOON,
        diy_allowed=diy,
        next_action=NextAction(type=action, message=message),
        **kw,
    )


class FakeProvider:
    name = "fake"

    def __init__(self, result: DiagnosticAnalysis):
        self.result = result
        self.calls: list[DiagnosticContext] = []

    async def analyze(self, context):
        self.calls.append(context)
        return self.result


def ctx(**kw):
    return DiagnosticContext(session_id="s1", **kw)


async def run(result, **kw):
    provider = FakeProvider(result)
    out = await DiagnosticService(provider).analyze(ctx(**kw))
    return out, provider


@pytest.mark.asyncio
async def test_photo_leads_to_question():
    out, p = await run(
        analysis(NextActionType.ASK_QUESTION, "D'où vient l'eau ?"),
        photos=[MediaRef(media_id="m1")],
    )
    assert out.next_action.type is NextActionType.ASK_QUESTION
    assert p.calls[0].photos[0].media_id == "m1"


@pytest.mark.asyncio
async def test_new_photo_is_passed_and_can_request_closer_photo():
    out, p = await run(
        analysis(NextActionType.REQUEST_PHOTO, "Montrez-moi cette connexion de plus près."),
        photos=[MediaRef(media_id="m1"), MediaRef(media_id="m2")],
    )
    assert out.next_action.type is NextActionType.REQUEST_PHOTO
    assert len(p.calls[0].photos) == 2


@pytest.mark.asyncio
async def test_instruction_one_step_at_a_time():
    out, _ = await run(
        analysis(NextActionType.INSTRUCTION, "Fermez l'arrivée d'eau.", required_items=["clé à molette"])
    )
    assert out.next_action.type is NextActionType.INSTRUCTION
    assert out.diy_allowed


@pytest.mark.asyncio
async def test_verification_receives_previous_outcomes():
    out, p = await run(
        analysis(NextActionType.VERIFICATION, "Le robinet fuit-il encore ?"),
        completed_actions=["water_off"],
        previous_outcomes=[VerificationOutcome.IMPROVED],
    )
    assert out.next_action.type is NextActionType.VERIFICATION
    assert p.calls[0].previous_outcomes == [VerificationOutcome.IMPROVED]


@pytest.mark.asyncio
async def test_resolved():
    out, _ = await run(analysis(NextActionType.RESOLVED, "Le problème semble résolu."))
    assert out.next_action.type is NextActionType.RESOLVED


@pytest.mark.asyncio
async def test_professional_recommendation():
    out, _ = await run(
        analysis(NextActionType.RECOMMEND_PROFESSIONAL, "Faites intervenir un professionnel.", diy=False)
    )
    assert out.next_action.type is NextActionType.RECOMMEND_PROFESSIONAL


@pytest.mark.asyncio
async def test_safety_stop_before_ai_is_never_called():
    out, p = await run(
        analysis(NextActionType.INSTRUCTION, "Ouvrez le tableau"),
        description="Ça sent le gaz",
    )
    assert out.next_action.type is NextActionType.SAFETY_STOP
    assert out.risk_level is RiskLevel.EMERGENCY
    assert not out.diy_allowed
    assert p.calls == []
    assert out.next_action.message.startswith("Arrêtez-vous ici.")


@pytest.mark.asyncio
async def test_ai_emergency_overrides_ai_instruction():
    out, _ = await run(
        analysis(NextActionType.INSTRUCTION, "Continuez", risk=RiskLevel.EMERGENCY, diy=True),
        description="Un problème",
    )
    assert out.next_action.type is NextActionType.SAFETY_STOP
    assert not out.diy_allowed
    assert out.required_items == []


@pytest.mark.asyncio
async def test_ai_cannot_override_stop_from_conversation():
    out, p = await run(
        analysis(NextActionType.RESOLVED, "Tout va bien"),
        description="Robinet qui goutte",
        conversation=["il y a des fils dénudés"],
    )
    assert out.next_action.type is NextActionType.SAFETY_STOP
    assert p.calls == []


def test_hypothesis_is_never_certain():
    with pytest.raises(ValueError):
        Hypothesis(label="joint usé", confidence=1.0)


@pytest.mark.asyncio
async def test_ai_instruction_toward_electrical_panel_is_replaced_by_stop():
    out, _ = await run(analysis(NextActionType.INSTRUCTION, "Ouvrez le tableau électrique et coupez le disjoncteur"))
    assert out.next_action.type is NextActionType.SAFETY_STOP
    assert not out.diy_allowed


@pytest.mark.asyncio
async def test_ai_safety_flag_forces_stop():
    out, _ = await run(analysis(NextActionType.INSTRUCTION, "Continuez", safety_flags=["gas"]))
    assert out.next_action.type is NextActionType.SAFETY_STOP


@pytest.mark.asyncio
async def test_ai_unknown_flag_is_treated_as_emergency():
    out, _ = await run(analysis(NextActionType.INSTRUCTION, "Continuez", safety_flags=["wat"]))
    assert out.next_action.type is NextActionType.SAFETY_STOP


@pytest.mark.asyncio
async def test_instruction_without_diy_becomes_professional_recommendation():
    out, _ = await run(analysis(NextActionType.INSTRUCTION, "Démontez le moteur", diy=False))
    assert out.next_action.type is NextActionType.RECOMMEND_PROFESSIONAL
    assert out.required_items == []


@pytest.mark.asyncio
async def test_ai_requested_stop_never_allows_diy():
    out, _ = await run(analysis(NextActionType.SAFETY_STOP, "Éloignez-vous.", risk=RiskLevel.LOW, diy=True))
    assert not out.diy_allowed
    assert out.risk_level.rank >= RiskLevel.HIGH.rank


@pytest.mark.asyncio
async def test_nalvium_own_previous_messages_never_trigger_stop():
    # `conversation` ne contient que des textes utilisateur : un ancien message de Nalvium
    # (history) qui mentionne un disjoncteur ne doit pas déclencher de STOP.
    out, p = await run(
        analysis(NextActionType.ASK_QUESTION, "Où se trouve l'eau ?"),
        description="Mon évier fuit",
        conversation=["Mon évier fuit"],
        history=["Nalvium (INSTRUCTION): Ne touchez pas au disjoncteur ni à la prise."],
    )
    assert out.next_action.type is NextActionType.ASK_QUESTION
    assert len(p.calls) == 1


@pytest.mark.asyncio
async def test_ai_requested_stop_keeps_its_own_explanation_but_is_enforced():
    out, _ = await run(
        analysis(NextActionType.SAFETY_STOP, "Ce câble est sous tension : ne le touchez pas et coupez rien.",
                 risk=RiskLevel.EMERGENCY, diy=True)
    )
    assert out.next_action.type is NextActionType.SAFETY_STOP
    assert out.next_action.message.startswith("Arrêtez-vous ici.")
    assert "câble est sous tension" in out.next_action.message
    assert not out.diy_allowed and out.risk_level is RiskLevel.EMERGENCY
    assert out.next_action.message.count("Cette situation présente") == 0


@pytest.mark.asyncio
async def test_keyword_stop_still_uses_engine_text_over_ai_text():
    out, p = await run(analysis(NextActionType.SAFETY_STOP, "Texte IA"), description="odeur de gaz")
    assert "gaz" in out.next_action.message.lower() and "Texte IA" not in out.next_action.message
    assert p.calls == []
