from app.ai.provider import AIProvider, AIProviderNotConfigured
from app.config import Settings


class UnconfiguredProvider:
    """Provider indisponible : refuse explicitement. Aucun fallback mock."""

    name = "none"

    def __init__(self, reason: str = "Aucun provider IA configuré") -> None:
        self._reason = reason

    async def analyze(self, context):
        raise AIProviderNotConfigured(self._reason)


def build_provider(settings: Settings) -> AIProvider:
    if settings.ai_provider == "openai":
        if not settings.openai_api_key:
            return UnconfiguredProvider("OPENAI_API_KEY absente côté serveur")
        from app.ai.openai_provider import OpenAIProvider

        return OpenAIProvider(
            settings.openai_api_key, settings.openai_model,
            timeout_s=settings.openai_timeout_s,
            reasoning_effort=settings.openai_reasoning_effort,
        )
    return UnconfiguredProvider()
