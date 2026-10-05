"""Provider OpenAI testé avec un faux client SDK (aucun appel réseau, aucune clé)."""
from types import SimpleNamespace

import openai
import pytest

from app.ai.openai_provider import MAX_CONFIDENCE, OpenAIProvider, build_input, to_domain
from app.ai.provider import AIProviderError, AIProviderNotConfigured
from app.ai.registry import build_provider
from app.ai.wire import WireAnalysis, WireHypothesis, WireNextAction
from app.config import Settings
from app.domain.diagnosis import DiagnosticContext, MediaRef, NextActionType, VerificationOutcome


def wire(**over) -> WireAnalysis:
    base = dict(  # noqa: C408
        title="Fuite sous l'évier",
        category="plumbing",
        subcategory="siphon",
        observations=["Eau autour du siphon"],
        hypotheses=[WireHypothesis(label="Joint usé", confidence=1.0)],
        missing_information=[],
        risk_level="low",
        urgency="soon",
        diy_allowed=True,
        next_action=WireNextAction(action_type="REQUEST_PHOTO", message="Montrez-moi la connexion.", choices=[]),
        required_items=[],
        safety_flags=[],
        verification_outcome="none",
    )
    base.update(over)
    return WireAnalysis(**base)


class FakeResponses:
    def __init__(self, result=None, error=None):
        self.result, self.error, self.kwargs = result, error, None

    async def parse(self, **kwargs):
        self.kwargs = kwargs
        if self.error:
            raise self.error
        return SimpleNamespace(output_parsed=self.result)


def provider(result=None, error=None):
    responses = FakeResponses(result, error)
    client = SimpleNamespace(responses=responses)
    return OpenAIProvider("sk-test", "model-x", client=client), responses


@pytest.mark.asyncio
async def test_structured_output_is_requested_and_mapped():
    prov, responses = provider(wire())
    ctx = DiagnosticContext(
        session_id="s",
        description="Ça fuit",
        photos=[MediaRef(media_id="1", data=b"\xff\xd8abc")],
    )
    out = await prov.analyze(ctx)
    assert responses.kwargs["model"] == "model-x"
    assert responses.kwargs["text_format"] is WireAnalysis
    assert responses.kwargs["store"] is False
    assert out.next_action.type is NextActionType.REQUEST_PHOTO
    assert out.title == "Fuite sous l'évier"


def test_hypothesis_confidence_is_capped_never_certain():
    out = to_domain(wire(hypotheses=[WireHypothesis(label="x", confidence=1.0),
                                      WireHypothesis(label="y", confidence=-3)]))
    assert out.hypotheses[0].confidence == MAX_CONFIDENCE
    assert out.hypotheses[1].confidence == 0.0


def test_verification_outcome_none_maps_to_none():
    assert to_domain(wire()).verification_outcome is None
    assert to_domain(wire(verification_outcome="improved")).verification_outcome is VerificationOutcome.IMPROVED


def test_images_are_sent_as_data_urls_latest_four_only():
    photos = [MediaRef(media_id=str(i), data=bytes([i])) for i in range(6)]
    content = build_input(DiagnosticContext(session_id="s", photos=photos, history=["Utilisateur: bonjour"]))[0]["content"]
    images = [c for c in content if c["type"] == "input_image"]
    assert len(images) == 4
    assert all(i["image_url"].startswith("data:image/jpeg;base64,") for i in images)
    assert "Utilisateur: bonjour" in content[0]["text"]


def test_photo_without_bytes_is_skipped():
    content = build_input(DiagnosticContext(session_id="s", photos=[MediaRef(media_id="1")]))[0]["content"]
    assert [c["type"] for c in content] == ["input_text"]


@pytest.mark.asyncio
async def test_sdk_errors_become_provider_errors():
    prov, _ = provider(error=openai.APIConnectionError(request=SimpleNamespace()))
    with pytest.raises(AIProviderError):
        await prov.analyze(DiagnosticContext(session_id="s"))


@pytest.mark.asyncio
async def test_refusal_or_empty_output_is_an_error():
    prov, _ = provider(result=None)
    with pytest.raises(AIProviderError):
        await prov.analyze(DiagnosticContext(session_id="s"))


@pytest.mark.asyncio
async def test_no_key_means_unavailable_never_a_mock():
    prov = build_provider(Settings(ai_provider="openai", openai_api_key=None, _env_file=None))
    with pytest.raises(AIProviderNotConfigured):
        await prov.analyze(DiagnosticContext(session_id="s"))


def test_key_present_builds_real_provider():
    prov = build_provider(Settings(ai_provider="openai", openai_api_key="sk-test", _env_file=None))
    assert prov.name == "openai"
