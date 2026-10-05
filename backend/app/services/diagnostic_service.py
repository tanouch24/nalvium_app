"""Orchestration : Safety Engine AVANT l'IA, puis re-contrôle APRÈS. L'IA ne contourne jamais le STOP."""
from app.ai.provider import AIProvider
from app.domain.diagnosis import (
    Category,
    DiagnosticAnalysis,
    DiagnosticContext,
    NextAction,
    NextActionType,
    RiskLevel,
    Urgency,
)
from app.safety import SafetyDecision, SafetyInput, enforce, evaluate
from app.safety.engine import parse_flags


def _pre_input(ctx: DiagnosticContext) -> SafetyInput:
    # Uniquement les textes écrits par l'utilisateur (jamais ceux de Nalvium).
    return SafetyInput(description=ctx.description, conversation=tuple(ctx.conversation))


def _post_input(analysis: DiagnosticAnalysis) -> SafetyInput:
    action = analysis.next_action
    return SafetyInput(
        ai_risk_level=analysis.risk_level,
        ai_flags=parse_flags(analysis.safety_flags),
        ai_instruction=action.message if action.type is NextActionType.INSTRUCTION else None,
    )


def stop_analysis(decision: SafetyDecision) -> DiagnosticAnalysis:
    return DiagnosticAnalysis(
        category=Category.OTHER,
        risk_level=RiskLevel.EMERGENCY,
        urgency=Urgency.NOW,
        diy_allowed=False,
        title="Situation dangereuse",
        next_action=NextAction(
            type=NextActionType.SAFETY_STOP,
            message=f"{decision.title} {decision.explanation}",
        ),
    )


class DiagnosticService:
    def __init__(self, provider: AIProvider) -> None:
        self._provider = provider

    async def analyze(self, ctx: DiagnosticContext) -> DiagnosticAnalysis:
        pre = evaluate(_pre_input(ctx))
        if pre.stop:
            return stop_analysis(pre)  # l'IA n'est même pas appelée

        analysis = await self._provider.analyze(ctx)
        post = evaluate(_post_input(analysis))
        return enforce(analysis, post)
