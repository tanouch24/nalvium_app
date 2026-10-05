import io
import uuid

from PIL import Image

from app.domain.diagnosis import (
    Category,
    DiagnosticAnalysis,
    DiagnosticContext,
    Hypothesis,
    NextAction,
    NextActionType,
    RiskLevel,
    Urgency,
)


def jpeg_bytes(size=(320, 240), color=(40, 90, 200), exif: bytes | None = None) -> bytes:
    buf = io.BytesIO()
    img = Image.new("RGB", size, color)
    if exif:
        img.save(buf, format="JPEG", exif=exif)
    else:
        img.save(buf, format="JPEG")
    return buf.getvalue()


def make_analysis(action: NextActionType, message="Message", *, risk=RiskLevel.LOW, diy=True,
                  choices=None, title="Fuite sous l'évier", **kw) -> DiagnosticAnalysis:
    return DiagnosticAnalysis(
        title=title,
        category=Category.PLUMBING,
        subcategory="fuite",
        observations=["De l'eau près du siphon"],
        hypotheses=[Hypothesis(label="Joint usé", confidence=0.6)],
        missing_information=["Provenance exacte"],
        risk_level=risk,
        urgency=Urgency.SOON,
        diy_allowed=diy,
        next_action=NextAction(type=action, message=message, choices=choices or []),
        **kw,
    )


class ScriptedProvider:
    """Provider de TEST (jamais utilisé en prod) : renvoie des analyses prévues et enregistre les contextes."""

    name = "scripted"

    def __init__(self, *analyses: DiagnosticAnalysis):
        self.queue = list(analyses)
        self.contexts: list[DiagnosticContext] = []

    async def analyze(self, context):
        self.contexts.append(context)
        return self.queue.pop(0)


def new_install_id() -> str:
    return str(uuid.uuid4())
