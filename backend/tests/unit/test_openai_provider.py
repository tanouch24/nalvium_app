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


def test_typographic_glyphs_the_ui_font_cannot_render_are_normalised():
    out = to_domain(
        wire(
            title="Fuite sous l‑évier",
            next_action=WireNextAction(
                action_type="INSTRUCTION",
                message="Tenez le téléphone au‑dessus, centré sur cette zone.\u200b",
                choices=["C’est fait"],
            ),
            required_items=["Gants‐ménagers"],
        )
    )
    assert out.title == "Fuite sous l-évier"
    assert "‑" not in out.next_action.message and "au-dessus" in out.next_action.message
    assert " " not in out.next_action.message and "\u200b" not in out.next_action.message
    assert out.required_items == ["Gants-ménagers"]
    assert out.next_action.choices == ["C’est fait"]  # l'apostrophe typographique reste (la police la contient)


# ───────────────────────────── VIDÉO ─────────────────────────────
from app.domain.diagnosis import VideoDiagnosticInput, VideoFrameInput


def _video(has_audio=True, times=(0.0, 3.0, 6.0, 9.0)):
    return VideoDiagnosticInput(
        media_id="v1", duration_s=9.0, has_audio=has_audio,
        frames=[VideoFrameInput(t=t, data=bytes([int(t)])) for t in times],
    )


def test_video_is_sent_as_ordered_timestamped_frames_not_as_a_video_file():
    content = build_input(DiagnosticContext(session_id="s", videos=[_video()]))[0]["content"]
    types = [c["type"] for c in content]
    assert set(types) == {"input_text", "input_image"}  # aucune entrée « vidéo » ou « audio » native
    assert types.count("input_image") == 4
    header = content[0]["text"]
    assert "4 images extraites de CETTE MÊME vidéo" in header and "ordre chronologique" in header
    assert "0.0 s, 3.0 s, 6.0 s, 9.0 s" in header
    labels = [c["text"] for c in content if c["type"] == "input_text"][1:]
    assert labels == [f"Image extraite de la vidéo, à t = {t:.1f} s :" for t in (0.0, 3.0, 6.0, 9.0)]
    # chaque libellé précède immédiatement son image, dans l'ordre
    idx = [i for i, c in enumerate(content) if c["type"] == "input_image"]
    assert all(content[i - 1]["type"] == "input_text" for i in idx)


def test_audio_is_never_claimed_to_be_analysed():
    with_audio = build_input(DiagnosticContext(session_id="s", videos=[_video(True)]))[0]["content"][0]["text"]
    assert "PAS l'écouter" in with_audio and "demande à l'utilisateur de le décrire" in with_audio
    without = build_input(DiagnosticContext(session_id="s", videos=[_video(False)]))[0]["content"][0]["text"]
    assert "pas de son" in without
    from app.ai.prompts import SYSTEM_PROMPT

    assert "ne prétends" in SYSTEM_PROMPT and "Tu ne peux pas écouter le son" in SYSTEM_PROMPT


def test_only_the_latest_video_is_sent_to_bound_the_images():
    older, newer = _video(times=(0.0, 5.0)), _video(times=(1.0, 2.0, 3.0))
    content = build_input(DiagnosticContext(session_id="s", videos=[older, newer]))[0]["content"]
    assert sum(1 for c in content if c["type"] == "input_image") == 3


def test_video_and_photos_can_coexist_with_bounded_total():
    photos = [MediaRef(media_id=str(i), data=bytes([i])) for i in range(6)]
    content = build_input(DiagnosticContext(session_id="s", videos=[_video()], photos=photos))[0]["content"]
    assert sum(1 for c in content if c["type"] == "input_image") == 4 + 4  # 4 images vidéo + 4 photos max


@pytest.mark.asyncio
async def test_video_context_is_passed_through_the_provider_call():
    prov, responses = provider(wire())
    await prov.analyze(DiagnosticContext(session_id="s", videos=[_video()]))
    sent = responses.kwargs["input"][0]["content"]
    assert sum(1 for c in sent if c["type"] == "input_image") == 4
