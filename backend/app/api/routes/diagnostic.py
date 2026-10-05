from fastapi import APIRouter, Depends, HTTPException

from app.ai.provider import AIProviderNotConfigured
from app.ai.registry import build_provider
from app.config import get_settings
from app.domain.diagnosis import DiagnosticAnalysis, DiagnosticContext
from app.services.diagnostic_service import DiagnosticService

router = APIRouter(prefix="/v1/diagnostic", tags=["diagnostic"])


def get_service() -> DiagnosticService:
    return DiagnosticService(build_provider(get_settings()))


@router.post("/analyze", response_model=DiagnosticAnalysis)
async def analyze(ctx: DiagnosticContext, service: DiagnosticService = Depends(get_service)):
    try:
        return await service.analyze(ctx)
    except AIProviderNotConfigured as exc:
        # Pas de résultat simulé : l'app affiche un état d'indisponibilité honnête.
        raise HTTPException(status_code=503, detail="analysis_unavailable") from exc
