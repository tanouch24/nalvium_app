"""Abstraction provider IA. Les appels IA sont strictement server-side."""
from typing import Protocol

from app.domain.diagnosis import DiagnosticAnalysis, DiagnosticContext


class AIProviderError(Exception):
    pass


class AIProviderNotConfigured(AIProviderError):
    """Aucun provider configuré : on refuse plutôt que de simuler un résultat."""


class AIProvider(Protocol):
    name: str

    async def analyze(self, context: DiagnosticContext) -> DiagnosticAnalysis:
        """Retourne une analyse structurée. Ne doit jamais contourner le Safety Engine."""
        ...
