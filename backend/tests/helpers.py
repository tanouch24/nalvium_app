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
        self.manual_candidates: list = []  # liste de ManualCandidate, ou Exception
        self.find_manual_calls: list[tuple[str, str]] = []
        self.identifications: list = []  # EquipmentIdentification ou Exception, consommés dans l'ordre
        self.identify_calls = 0

    async def find_manual(self, brand, model):
        self.find_manual_calls.append((brand, model))
        result = self.manual_candidates
        if isinstance(result, Exception):
            raise result
        return list(result)

    async def identify_equipment(self, image, mime):
        self.identify_calls += 1
        result = self.identifications.pop(0)
        if isinstance(result, Exception):
            raise result
        return result

    async def analyze(self, context):
        self.contexts.append(context)
        return self.queue.pop(0)


def new_install_id() -> str:
    return str(uuid.uuid4())


def make_video(duration=3.0, size=(320, 240), fps=15, audio=True, metadata=None, codec="libx264") -> bytes:
    """Vidéo mp4 SYNTHÉTIQUE (images qui changent + bip) pour les tests. Aucun fichier tiers."""
    import math
    import tempfile
    from array import array
    from fractions import Fraction
    from pathlib import Path

    import av
    from PIL import Image, ImageDraw

    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "v.mp4"
        with av.open(str(path), "w") as out:
            for k, v in (metadata or {}).items():
                out.metadata[k] = v
            vs = out.add_stream(codec, rate=fps)
            vs.width, vs.height, vs.pix_fmt = size[0], size[1], "yuv420p"
            as_ = None
            if audio:
                as_ = out.add_stream("aac", rate=44100)
                as_.layout = "mono"
            for i in range(int(duration * fps)):
                img = Image.new("RGB", size, (30 + (i * 7) % 200, 90, 160))
                ImageDraw.Draw(img).rectangle((i * 3 % size[0], 20, i * 3 % size[0] + 40, 80), fill=(250, 250, 250))
                frame = av.VideoFrame.from_image(img)
                frame.pts, frame.time_base = i, Fraction(1, fps)
                for pkt in vs.encode(frame):
                    out.mux(pkt)
            for pkt in vs.encode(None):
                out.mux(pkt)
            if as_ is not None:
                n = int(duration * 44100)
                tone = array("h", (int(9000 * math.sin(2 * math.pi * 440 * i / 44100)) for i in range(n)))
                for off in range(0, n, 1024):
                    chunk = tone[off : off + 1024]
                    af = av.AudioFrame(format="s16", layout="mono", samples=len(chunk))
                    af.planes[0].update(chunk.tobytes().ljust(af.planes[0].buffer_size, b"\0"))
                    af.sample_rate, af.pts = 44100, off
                    for pkt in as_.encode(af):
                        out.mux(pkt)
                for pkt in as_.encode(None):
                    out.mux(pkt)
        return path.read_bytes()


def make_pdf(pages: list[str]) -> bytes:
    """PDF SYNTHÉTIQUE minimal (texte natif, une page par élément) pour les tests d'extraction. Jamais une vraie notice."""
    objs: list[bytes] = []

    def add(body: str | bytes) -> int:
        objs.append(body if isinstance(body, bytes) else body.encode("latin-1"))
        return len(objs)

    add("<< /Type /Catalog /Pages 2 0 R >>")
    add("PLACEHOLDER")  # pages
    font = add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>")
    kids = []
    for text in pages:
        lines = text.split("\n")
        stream = "BT /F1 11 Tf 50 780 Td 14 TL " + " ".join(
            "(" + ln.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)") + ") Tj T*" for ln in lines
        ) + " ET"
        content = add(f"<< /Length {len(stream.encode('latin-1', 'replace'))} >>\nstream\n{stream}\nendstream")
        page = add(
            f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents {content} 0 R "
            f"/Resources << /Font << /F1 {font} 0 R >> >> >>"
        )
        kids.append(page)
    objs[1] = f"<< /Type /Pages /Kids [{' '.join(f'{k} 0 R' for k in kids)}] /Count {len(kids)} >>".encode()
    out = bytearray(b"%PDF-1.4\n")
    offsets = []
    for i, body in enumerate(objs, 1):
        offsets.append(len(out))
        out += f"{i} 0 obj\n".encode() + body + b"\nendobj\n"
    xref = len(out)
    out += f"xref\n0 {len(objs) + 1}\n0000000000 65535 f \n".encode()
    for off in offsets:
        out += f"{off:010d} 00000 n \n".encode()
    out += f"trailer\n<< /Size {len(objs) + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF".encode()
    return bytes(out)
