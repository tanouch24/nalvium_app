"""Vérification RÉELLE et isolée du provider OpenAI (texte, image, Structured Output).

Usage : cd backend && .venv/bin/python tools/check_openai.py
Lit OPENAI_API_KEY / OPENAI_MODEL dans l'environnement ou backend/.env. N'affiche jamais la clé.
"""
import asyncio
import io
import sys
import time

from PIL import Image, ImageDraw

from app.ai.registry import build_provider
from app.config import get_settings
from app.domain.diagnosis import DiagnosticContext, MediaRef


def test_image() -> bytes:
    img = Image.new("RGB", (640, 480), (225, 225, 220))
    d = ImageDraw.Draw(img)
    d.rectangle((200, 100, 440, 380), fill=(240, 240, 245), outline=(90, 90, 90), width=4)  # meuble
    d.ellipse((290, 330, 350, 380), fill=(70, 120, 200))  # flaque
    d.text((20, 20), "photo de test", fill=(0, 0, 0))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


async def main() -> int:
    s = get_settings()
    print(f"provider configuré : {s.ai_provider}")
    print(f"modèle            : {s.openai_model}")
    print(f"clé présente      : {'oui' if s.openai_api_key else 'NON'}")
    if not s.openai_api_key:
        print("→ Ajoutez OPENAI_API_KEY dans backend/.env puis relancez.")
        return 2
    provider = build_provider(s)
    assert provider.name == "openai"

    for label, ctx in [
        ("TEXTE", DiagnosticContext(session_id="check", description="Mon robinet de cuisine goutte en continu.",
                                    conversation=["Mon robinet de cuisine goutte en continu."])),
        ("IMAGE", DiagnosticContext(session_id="check", photos=[MediaRef(media_id="t", data=test_image())],
                                    description="Il y a de l'eau par terre devant ce meuble.")),
    ]:
        t = time.monotonic()
        a = await provider.analyze(ctx)
        print(f"\n[{label}] {time.monotonic() - t:.1f}s  action={a.next_action.type.value} "
              f"risk={a.risk_level.value} diy={a.diy_allowed} title={a.title!r}")
        print(f"  message : {a.next_action.message}")
        print(f"  hypothèses: {[(h.label, h.confidence) for h in a.hypotheses]}")
        assert all(h.confidence < 1 for h in a.hypotheses)
    print("\nOK : Structured Output valide (texte + image).")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
