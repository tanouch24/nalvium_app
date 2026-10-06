"""Traitement d'une photo AVANT stockage : orientation, resize, compression, EXIF/GPS supprimés."""
import io
from dataclasses import dataclass

from PIL import Image, ImageOps, UnidentifiedImageError

MAX_SIDE = 1600
JPEG_QUALITY = 82
MAX_PIXELS = 60_000_000  # protège contre les images « bombes »

Image.MAX_IMAGE_PIXELS = MAX_PIXELS


class InvalidImageError(ValueError):
    pass


@dataclass(frozen=True)
class ProcessedImage:
    data: bytes
    width: int
    height: int
    content_type: str = "image/jpeg"


def process_photo(raw: bytes) -> ProcessedImage:
    try:
        with Image.open(io.BytesIO(raw)) as img:
            img.load()
            # Applique l'orientation EXIF aux pixels, puis on repart d'une image SANS métadonnées.
            img = ImageOps.exif_transpose(img)
            rgb = img.convert("RGB")
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as exc:
        raise InvalidImageError("not_an_image") from exc

    rgb.thumbnail((MAX_SIDE, MAX_SIDE), Image.Resampling.LANCZOS)
    clean = Image.new("RGB", rgb.size)
    clean.paste(rgb)  # nouvelle image : aucun EXIF/GPS/ICC hérité
    out = io.BytesIO()
    clean.save(out, format="JPEG", quality=JPEG_QUALITY, optimize=True)
    return ProcessedImage(data=out.getvalue(), width=clean.width, height=clean.height)


THUMB_SIDE = 480
THUMB_QUALITY = 78


def make_thumbnail(image: ProcessedImage) -> bytes:
    """Vignette (côté ≤ 480 px) dérivée d'une image DÉJÀ nettoyée : listes légères, aucune métadonnée."""
    with Image.open(io.BytesIO(image.data)) as img:
        thumb = img.convert("RGB")
        thumb.thumbnail((THUMB_SIDE, THUMB_SIDE), Image.Resampling.LANCZOS)
        out = io.BytesIO()
        thumb.save(out, format="JPEG", quality=THUMB_QUALITY, optimize=True)
        return out.getvalue()
