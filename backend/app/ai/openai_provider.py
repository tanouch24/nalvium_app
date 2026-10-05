"""Provider OpenAI multimodal (Responses API + Structured Outputs). Server-side uniquement."""
import base64
import logging
import time

import openai
from openai import AsyncOpenAI

from app.ai.prompts import SYSTEM_PROMPT
from app.ai.provider import AIProviderError
from app.ai.wire import WireAnalysis
from app.domain.diagnosis import (
    Category,
    DiagnosticAnalysis,
    DiagnosticContext,
    Hypothesis,
    NextAction,
    NextActionType,
    RiskLevel,
    Urgency,
    VerificationOutcome,
)

log = logging.getLogger("nalvium.ai")

MAX_IMAGES = 4
MAX_CONFIDENCE = 0.9


# Caractères que GPT insère parfois et que les polices d'interface rendent mal (ex. « au‑dessus » → « au_dessus »).
_GLYPH_FIXES = str.maketrans(
    {
        "\u2010": "-", "\u2011": "-", "\u2012": "-", "\u2043": "-",  # traits d'union typographiques
        "\u202f": "\u00a0", "\u2009": " ", "\u200a": " ", "\u2002": " ", "\u2003": " ",  # espaces fines
        "\u200b": "", "\u2060": "", "\ufeff": "",  # invisibles
    }
)


def clean_text(text: str) -> str:
    return text.translate(_GLYPH_FIXES).strip()


def describe_video(video, n: int = 1) -> str:
    """Dit au modèle EXACTEMENT ce qu'il reçoit : des images ordonnées dans le temps, pas la vidéo ni le son."""
    times = ", ".join(f"{f.t:.1f} s" for f in video.frames)
    audio = (
        "Une piste audio existe mais tu ne peux PAS l'écouter : si le bruit compte pour le diagnostic "
        "(claquement, vibration, pompe…), demande à l'utilisateur de le décrire."
        if video.has_audio
        else "Cette vidéo n'a pas de son."
    )
    return (
        f"Vidéo n°{n} de l'utilisateur ({video.duration_s:.1f} s). Tu ne reçois pas la vidéo mais "
        f"{len(video.frames)} images extraites de CETTE MÊME vidéo, dans l'ordre chronologique (t = {times}). "
        f"Observe ce qui change d'une image à l'autre. {audio}"
    )


def build_input(ctx: DiagnosticContext) -> list[dict]:
    """Construit l'entrée multimodale. Aucun contenu n'est loggé."""
    lines: list[str] = []
    if ctx.equipment:
        lines.append(f"Équipement concerné : {ctx.equipment}")
    if ctx.description:
        lines.append(f"Description initiale de l'utilisateur : {ctx.description}")
    if ctx.history:
        lines.append("Historique de la session (ancien → récent) :")
        lines.extend(ctx.history)
    if ctx.completed_actions:
        lines.append("Actions déjà effectuées : " + " ; ".join(ctx.completed_actions))
    if ctx.previous_outcomes:
        lines.append("Résultats précédents : " + ", ".join(o.value for o in ctx.previous_outcomes))
    if not lines and not ctx.videos:
        lines.append("Aucun texte : analyse la photo.")

    videos = ctx.videos[-1:]  # une seule vidéo à la fois : on borne le nombre d'images envoyées
    for n, video in enumerate(videos, 1):
        lines.append(describe_video(video, n))

    content: list[dict] = [{"type": "input_text", "text": "\n".join(lines)}]
    for video in videos:
        for frame in video.frames:
            b64 = base64.b64encode(frame.data).decode("ascii")
            content.append({"type": "input_text", "text": f"Image extraite de la vidéo, à t = {frame.t:.1f} s :"})
            content.append({"type": "input_image", "image_url": f"data:{frame.mime};base64,{b64}", "detail": "auto"})
    photos = [p for p in ctx.photos if p.data][-MAX_IMAGES:]
    for photo in photos:
        b64 = base64.b64encode(photo.data).decode("ascii")  # type: ignore[arg-type]
        content.append(
            {"type": "input_image", "image_url": f"data:{photo.mime};base64,{b64}", "detail": "auto"}
        )
    return [{"role": "user", "content": content}]


def to_domain(wire: WireAnalysis) -> DiagnosticAnalysis:
    hypotheses = [
        Hypothesis(label=clean_text(h.label), confidence=min(max(h.confidence, 0.0), MAX_CONFIDENCE))
        for h in wire.hypotheses
    ]
    outcome = (
        None if wire.verification_outcome == "none" else VerificationOutcome(wire.verification_outcome)
    )
    return DiagnosticAnalysis(
        title=clean_text(wire.title),
        category=Category(wire.category),
        subcategory=clean_text(wire.subcategory) or None,
        observations=[clean_text(o) for o in wire.observations if o.strip()],
        hypotheses=hypotheses,
        missing_information=[clean_text(m) for m in wire.missing_information if m.strip()],
        risk_level=RiskLevel(wire.risk_level),
        urgency=Urgency(wire.urgency),
        diy_allowed=wire.diy_allowed,
        next_action=NextAction(
            type=NextActionType(wire.next_action.action_type),
            message=clean_text(wire.next_action.message),
            choices=[clean_text(c) for c in wire.next_action.choices if c.strip()],
        ),
        required_items=[clean_text(r) for r in wire.required_items if r.strip()],
        safety_flags=list(wire.safety_flags),
        verification_outcome=outcome,
    )


class OpenAIProvider:
    name = "openai"

    def __init__(
        self,
        api_key: str,
        model: str,
        timeout_s: float = 60.0,
        client: AsyncOpenAI | None = None,
        reasoning_effort: str | None = None,
    ) -> None:
        self.model = model
        self._reasoning_effort = reasoning_effort
        self._client = client or AsyncOpenAI(api_key=api_key, timeout=timeout_s, max_retries=1)

    async def analyze(self, ctx: DiagnosticContext) -> DiagnosticAnalysis:
        started = time.monotonic()
        try:
            response = await self._client.responses.parse(
                model=self.model,
                instructions=SYSTEM_PROMPT,
                input=build_input(ctx),
                text_format=WireAnalysis,
                store=False,  # on ne demande pas à OpenAI de conserver la conversation
                **({"reasoning": {"effort": self._reasoning_effort}} if self._reasoning_effort else {}),
            )
        except openai.OpenAIError as exc:
            log.warning("openai error type=%s duration=%.1fs", type(exc).__name__, time.monotonic() - started)
            raise AIProviderError(f"openai_{type(exc).__name__}") from exc
        parsed = response.output_parsed
        if parsed is None:
            raise AIProviderError("openai_empty_or_refused")
        log.info(
            "openai ok model=%s reasoning_effort=%s images=%d video_frames=%d action_type=%s risk=%s duration=%.1fs",
            self.model,
            self._reasoning_effort or "default",
            sum(1 for p in ctx.photos if p.data),
            len(ctx.videos[-1].frames) if ctx.videos else 0,
            parsed.next_action.action_type,
            parsed.risk_level,
            time.monotonic() - started,
        )
        return to_domain(parsed)
