"""Vérification RÉELLE de l'identification d'équipement sur photo (GPT-5, Structured Output).

Usage : cd backend && .venv/bin/python tools/check_equipment_identification.py image1.jpg [image2.jpg …]
Les images passent d'abord par le pipeline média (EXIF retiré, redimensionnement), comme en production.
N'affiche jamais la clé. Utiliser des images NON sensibles (ex. Wikimedia Commons).
"""
import asyncio
import io
import sys
import time
from pathlib import Path

from PIL import Image, ImageDraw

from app.ai.registry import build_provider
from app.config import get_settings
from app.media.pipeline import process_photo


def blank_image() -> bytes:
    """Image sans aucun équipement : l'attendu est « unknown », sans marque ni modèle."""
    img = Image.new("RGB", (800, 600), (200, 210, 200))
    ImageDraw.Draw(img).ellipse((250, 150, 550, 450), fill=(90, 150, 90))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


async def main(paths: list[str]) -> int:
    settings = get_settings()
    print(f"modèle : {settings.openai_model}  | clé présente : {'oui' if settings.openai_api_key else 'NON'}")
    if not settings.openai_api_key:
        return 2
    provider = build_provider(settings)
    samples = [(p, Path(p).read_bytes()) for p in paths] + [("(image sans équipement)", blank_image())]
    for label, raw in samples:
        image = process_photo(raw)
        started = time.monotonic()
        result = await provider.identify_equipment(image.data, image.content_type)
        print(f"\n[{label}] {time.monotonic() - started:.1f}s")
        print(f"  type={result.equipment_type} brand={result.brand!r} model={result.model!r} "
              f"confidence={result.confidence:.2f} needs_confirmation={result.needs_confirmation}")
        print(f"  texte lu : {result.visible_text}")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main(sys.argv[1:])))
