import io

import pytest
from PIL import Image

from app.media.pipeline import MAX_SIDE, InvalidImageError, process_photo
from tests.helpers import jpeg_bytes


def _exif_with_gps_and_orientation(orientation: int) -> bytes:
    exif = Image.Exif()
    exif[0x0112] = orientation
    exif[0x010F] = "SecretPhoneMaker"
    gps = exif.get_ifd(0x8825)
    gps[1] = "N"
    gps[2] = (48.0, 51.0, 24.0)
    gps[3] = "E"
    gps[4] = (2.0, 21.0, 8.0)
    return exif.tobytes()


def test_exif_and_gps_are_removed():
    raw = jpeg_bytes(exif=_exif_with_gps_and_orientation(1))
    assert b"SecretPhoneMaker" in raw  # le test d'entrée contient bien des métadonnées
    out = process_photo(raw)
    img = Image.open(io.BytesIO(out.data))
    assert len(img.getexif()) == 0
    assert not img.getexif().get_ifd(0x8825)
    assert b"SecretPhoneMaker" not in out.data
    assert b"Exif" not in out.data[:64]


def test_orientation_is_applied_to_pixels():
    # Orientation 6 = rotation 90° : une image 300x100 doit devenir 100x300.
    raw = jpeg_bytes(size=(300, 100), exif=_exif_with_gps_and_orientation(6))
    out = process_photo(raw)
    assert (out.width, out.height) == (100, 300)


def test_large_image_is_resized_and_compressed():
    raw = jpeg_bytes(size=(4000, 3000))
    out = process_photo(raw)
    assert max(out.width, out.height) == MAX_SIDE
    assert out.content_type == "image/jpeg"
    assert len(out.data) < len(raw)


def test_small_image_is_not_upscaled():
    out = process_photo(jpeg_bytes(size=(200, 100)))
    assert (out.width, out.height) == (200, 100)


def test_png_is_converted_to_jpeg():
    buf = io.BytesIO()
    Image.new("RGBA", (50, 50), (255, 0, 0, 128)).save(buf, format="PNG")
    out = process_photo(buf.getvalue())
    assert Image.open(io.BytesIO(out.data)).format == "JPEG"


@pytest.mark.parametrize("raw", [b"", b"not an image", b"%PDF-1.4 hello"])
def test_non_images_are_rejected(raw):
    with pytest.raises(InvalidImageError):
        process_photo(raw)
