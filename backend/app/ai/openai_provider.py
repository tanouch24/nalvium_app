"""Provider OpenAI multimodal (Responses API + Structured Outputs). Server-side uniquement."""
import base64
import logging
import time

import openai
from openai import AsyncOpenAI

from app.ai.prompts import EQUIPMENT_PROMPT, MANUAL_SEARCH_PROMPT, SYSTEM_PROMPT
from app.ai.provider import AIProviderError
from app.ai.wire import WireAnalysis, WireEquipmentIdentification, WireManualSearch
from app.domain.diagnosis import (
    Category,
    DiagnosticAnalysis,
    DiagnosticContext,
    EquipmentIdentification,
    Hypothesis,
    ManualCandidate,
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
    if ctx.manual and ctx.manual.excerpts:
        m = ctx.manual
        lines.append(
            "Notice constructeur : document EXACT de l'appareil de l'utilisateur (source officielle)."
            if m.exact
            else "Notice constructeur officielle de l'appareil, référence PROCHE confirmée par l'utilisateur "
            "(à utiliser avec prudence)."
        )
        lines.append(f"  fabricant: {m.manufacturer or 'inconnu'} | référence: {m.model or 'inconnue'}")
        lines.append("Extraits pertinents de la notice (à privilégier ; ne pas contredire silencieusement) :")
        for e in m.excerpts:
            where = f"page {e.page}" + (f" — {e.section}" if e.section else "")
            lines.append(f"  [{where}]")
            lines.extend("    " + t for t in e.text.splitlines() if t.strip())
    if ctx.equipment:
        eq = ctx.equipment
        lines.append("Équipement (enregistré par l'utilisateur dans sa maison) :")
        lines.append(f"  type: {eq.type}")
        lines.append(f"  nom: {eq.name}")
        lines.append(f"  marque: {eq.brand or 'inconnue'}")
        lines.append(f"  modèle: {eq.model or 'inconnu'}")
        if eq.room:
            lines.append(f"  pièce: {eq.room}")
        if ctx.equipment_history:
            lines.append(
                "Antécédents du même équipement (contexte seulement, ne prouvent PAS la cause actuelle) :"
            )
            lines.extend(f"  - {h}" for h in ctx.equipment_history)
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


def _norm_alnum(text: str) -> str:
    return "".join(c for c in text.lower() if c.isalnum())


def identification_to_domain(wire: WireEquipmentIdentification) -> EquipmentIdentification:
    """Garde-fous anti-hallucination : un modèle n'est conservé que s'il figure dans le texte lu sur l'image,
    et toute identification reste à confirmer."""
    visible = [clean_text(t) for t in wire.visible_text if t.strip()][:8]
    seen = _norm_alnum(" ".join(visible))
    model = clean_text(wire.model)
    if not model or len(_norm_alnum(model)) < 3 or _norm_alnum(model) not in seen:
        model = ""
    brand = clean_text(wire.brand)
    return EquipmentIdentification(
        equipment_type=wire.equipment_type,
        brand=brand[:60] or None,
        model=model[:80] or None,
        confidence=min(max(wire.confidence, 0.0), MAX_CONFIDENCE),
        visible_text=visible,
        needs_confirmation=True,
    )


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
        manual_pages_used=sorted({p for p in wire.manual_pages_used if p > 0}),
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

    async def identify_equipment(self, image: bytes, mime: str) -> EquipmentIdentification:
        started = time.monotonic()
        b64 = base64.b64encode(image).decode("ascii")
        try:
            response = await self._client.responses.parse(
                model=self.model,
                instructions=EQUIPMENT_PROMPT,
                input=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "input_text", "text": "Quel est cet équipement ?"},
                            {"type": "input_image", "image_url": f"data:{mime};base64,{b64}", "detail": "high"},
                        ],
                    }
                ],
                text_format=WireEquipmentIdentification,
                store=False,
                **({"reasoning": {"effort": self._reasoning_effort}} if self._reasoning_effort else {}),
            )
        except openai.OpenAIError as exc:
            log.warning(
                "openai equipment error type=%s duration=%.1fs", type(exc).__name__, time.monotonic() - started
            )
            raise AIProviderError(f"openai_{type(exc).__name__}") from exc
        parsed = response.output_parsed
        if parsed is None:
            raise AIProviderError("openai_empty_or_refused")
        result = identification_to_domain(parsed)
        log.info(
            "openai equipment ok model=%s type=%s has_brand=%s has_model=%s confidence=%.2f duration=%.1fs",
            self.model, result.equipment_type, bool(result.brand), bool(result.model), result.confidence,
            time.monotonic() - started,
        )
        return result

    async def find_manual(self, brand: str, model: str) -> list[ManualCandidate]:
        """Recherche web (outil du fournisseur). Seules la marque et la référence quittent le serveur."""
        started = time.monotonic()
        try:
            response = await self._client.responses.parse(
                model=self.model,
                instructions=MANUAL_SEARCH_PROMPT,
                input=f"Marque : {brand}\nRéférence : {model}",
                tools=[{"type": "web_search"}],
                text_format=WireManualSearch,
                store=False,
                **({"reasoning": {"effort": self._reasoning_effort}} if self._reasoning_effort else {}),
            )
        except openai.OpenAIError as exc:
            log.warning("openai manual search error type=%s duration=%.1fs", type(exc).__name__, time.monotonic() - started)
            raise AIProviderError(f"openai_{type(exc).__name__}") from exc
        parsed = response.output_parsed
        if parsed is None:
            raise AIProviderError("openai_empty_or_refused")
        found = [ManualCandidate(url=c.url.strip(), title=clean_text(c.title)) for c in parsed.candidates][:4]
        log.info("openai manual search ok candidates=%d duration=%.1fs", len(found), time.monotonic() - started)
        return found
