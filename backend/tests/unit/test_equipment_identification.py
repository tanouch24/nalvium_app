"""Identification d'équipement : schéma structuré, garde-fous anti-hallucination, catalogue (sans réseau)."""
from types import SimpleNamespace

import openai
import pytest

from app.ai.openai_provider import MAX_CONFIDENCE, OpenAIProvider, identification_to_domain
from app.ai.provider import AIProviderError
from app.ai.registry import UnconfiguredProvider
from app.ai.wire import WireEquipmentIdentification
from app.equipment.catalog import EQUIPMENT_TYPES, detect_type


def wire(**over) -> WireEquipmentIdentification:
    base = dict(equipment_type="dishwasher", brand="Bosch", model="", confidence=0.6, visible_text=[])  # noqa: C408
    base.update(over)
    return WireEquipmentIdentification(**base)


def test_unreadable_model_is_dropped_even_if_the_ai_invents_one():
    out = identification_to_domain(wire(model="SMS46AI01E", visible_text=["Bosch"]))
    assert out.model is None  # « SMS46AI01E » n'est pas dans le texte lu : jamais présenté
    assert out.brand == "Bosch"


def test_model_kept_only_when_present_in_visible_text():
    out = identification_to_domain(wire(model="SMS 46 AI", visible_text=["BOSCH", "SMS46AI"]))
    assert out.model == "SMS 46 AI"


def test_empty_values_become_none_and_confirmation_is_always_required():
    out = identification_to_domain(wire(equipment_type="unknown", brand="", model="", confidence=0.1))
    assert out.brand is None and out.model is None and out.needs_confirmation is True


def test_confidence_is_capped_below_certainty():
    assert identification_to_domain(wire(confidence=1.0)).confidence == MAX_CONFIDENCE
    assert identification_to_domain(wire(confidence=-2)).confidence == 0.0


def test_wire_types_match_catalog():
    from typing import get_args

    wire_types = set(get_args(WireEquipmentIdentification.model_fields["equipment_type"].annotation))
    assert wire_types == set(EQUIPMENT_TYPES) | {"unknown"}


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
    return OpenAIProvider("sk-test", "model-x", client=SimpleNamespace(responses=responses)), responses


@pytest.mark.asyncio
async def test_provider_requests_structured_output_without_storing():
    prov, responses = provider(wire(visible_text=["Bosch"]))
    out = await prov.identify_equipment(b"\xff\xd8jpeg", "image/jpeg")
    assert responses.kwargs["text_format"] is WireEquipmentIdentification
    assert responses.kwargs["store"] is False
    assert "PAS un diagnostic" in responses.kwargs["instructions"]
    assert out.equipment_type == "dishwasher" and out.needs_confirmation


@pytest.mark.asyncio
async def test_provider_errors_are_typed():
    prov, _ = provider(error=openai.APIConnectionError(request=None))
    with pytest.raises(AIProviderError):
        await prov.identify_equipment(b"x", "image/jpeg")
    prov, _ = provider(result=None)
    with pytest.raises(AIProviderError):
        await prov.identify_equipment(b"x", "image/jpeg")


@pytest.mark.asyncio
async def test_unconfigured_provider_refuses_instead_of_inventing():
    from app.ai.provider import AIProviderNotConfigured

    with pytest.raises(AIProviderNotConfigured):
        await UnconfiguredProvider().identify_equipment(b"x", "image/jpeg")


def test_detect_type_from_french_text():
    assert detect_type("Lave-vaisselle qui ne vidange plus") == "dishwasher"
    assert detect_type("Fuite sous l'évier") == "sink"
    assert detect_type("Mon chauffe-eau fait du bruit") == "water_heater"
    assert detect_type("Quelque chose bizarre", None) is None
