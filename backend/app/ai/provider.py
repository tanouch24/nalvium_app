"""Abstraction provider IA. Les appels IA sont strictement server-side."""
from typing import Protocol

from app.domain.diagnosis import (
    DiagnosticAnalysis,
    DiagnosticContext,
    EquipmentIdentification,
    ManualCandidate,
)


class AIProviderError(Exception):
    pass


class AIProviderNotConfigured(AIProviderError):
    """Aucun provider configuré : on refuse plutôt que de simuler un résultat."""


class AIProvider(Protocol):
    name: str

    async def analyze(self, context: DiagnosticContext) -> DiagnosticAnalysis:
        """Retourne une analyse structurée. Ne doit jamais contourner le Safety Engine."""
        ...

    async def identify_equipment(self, image: bytes, mime: str) -> EquipmentIdentification:
        """Propose un type / une marque / un modèle pour un équipement photographié. Jamais un diagnostic."""
        ...

    async def find_manual(self, brand: str, model: str) -> list[ManualCandidate]:
        """Cherche des liens de notice. NE REÇOIT QUE la marque et la référence (aucune donnée utilisateur)."""
        ...
