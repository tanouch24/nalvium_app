import io

import av
import pytest
from PIL import Image

from app.media.video import (
    InvalidVideoError,
    VideoTooLongError,
    frame_count_for,
    pick_frames,
    process_video,
    sharpness,
    target_times,
)
from tests.helpers import make_video


def _container(data: bytes):
    return av.open(io.BytesIO(data))


def test_valid_video_is_normalised_and_keeps_audio():
    p = process_video(make_video(duration=3, audio=True))
    assert p.content_type == "video/mp4"
    assert (p.width, p.height) == (320, 240)
    assert 2.5 <= p.duration_s <= 3.2
    assert p.has_audio is True
    with _container(p.data) as c:
        assert len(c.streams.video) == 1 and len(c.streams.audio) == 1
        assert c.streams.video[0].codec_context.name == "h264"


def test_video_without_audio_is_reported_honestly():
    p = process_video(make_video(duration=2, audio=False))
    assert p.has_audio is False
    with _container(p.data) as c:
        assert len(c.streams.audio) == 0


def test_location_and_other_metadata_are_removed():
    raw = make_video(duration=2, metadata={"location": "+48.8566+002.3522/", "title": "Maison de Jean", "comment": "SecretPhone"})
    assert b"loci" in raw and b"Maison de Jean" in raw and b"SecretPhone" in raw  # la source contient bien une localisation
    p = process_video(raw)
    assert b"loci" not in p.data and b"Maison de Jean" not in p.data and b"SecretPhone" not in p.data
    with _container(p.data) as c:
        assert not ({"location", "location-eng", "title", "comment"} & set(c.metadata))


def test_large_video_is_downscaled_without_distortion():
    p = process_video(make_video(duration=1, size=(1920, 1080)))
    assert (p.width, p.height) == (1280, 720)  # 16:9 conservé
    p2 = process_video(make_video(duration=1, size=(1080, 1920)))
    assert (p2.width, p2.height) == (720, 1280)  # portrait conservé


def test_too_long_video_is_rejected():
    with pytest.raises(VideoTooLongError):
        process_video(make_video(duration=5), max_seconds=3)


@pytest.mark.parametrize("raw", [b"", b"not a video", b"\x00" * 2048, b"%PDF-1.4 " + b"x" * 500])
def test_garbage_is_rejected_as_invalid_video(raw):
    with pytest.raises(InvalidVideoError):
        process_video(raw)


def test_audio_only_file_is_not_a_video():
    import shutil
    import subprocess
    import tempfile

    if not shutil.which("ffmpeg"):
        pytest.skip("ffmpeg absent")
    with tempfile.NamedTemporaryFile(suffix=".m4a") as f:
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i", "sine=duration=1", "-c:a", "aac", f.name], check=True)
        with pytest.raises(InvalidVideoError), open(f.name, "rb") as fh:
            process_video(fh.read())


def test_frames_are_ordered_in_time_and_bounded():
    p = process_video(make_video(duration=10, fps=10), max_frames=6)
    ts = [f.t for f in p.frames]
    assert ts == sorted(ts) and len(set(ts)) == len(ts)
    assert 2 <= len(p.frames) <= 6
    assert ts[0] <= 1.5 and ts[-1] >= p.duration_s - 2.5
    for f in p.frames:
        img = Image.open(io.BytesIO(f.jpeg))
        assert img.format == "JPEG" and max(img.size) <= 1024 and len(img.getexif()) == 0


def test_frame_selection_strategy_documented_numbers():
    assert frame_count_for(15) == 6 and frame_count_for(4) == 3 and frame_count_for(1) == 2
    assert target_times(15, 6) == [0.0, 3.0, 6.0, 9.0, 12.0, 15.0]
    assert frame_count_for(100) == 6  # jamais des dizaines d'images


def test_pick_frames_prefers_sharp_frames_and_keeps_order():
    sharp = Image.new("RGB", (200, 200), "white")
    for x in range(0, 200, 8):
        for y in range(0, 200, 8):
            if (x // 8 + y // 8) % 2 == 0:
                sharp.paste((0, 0, 0), (x, y, x + 8, y + 8))
    blurry = Image.new("RGB", (200, 200), (128, 128, 128))
    assert sharpness(sharp) > sharpness(blurry)
    cands = [(0.0, blurry), (0.4, sharp), (5.0, blurry), (5.4, sharp), (10.0, blurry), (10.4, sharp)]
    picked = pick_frames(cands, 10.4, 3)
    assert [round(t, 1) for t, _ in picked] == [0.4, 5.4, 10.4]


def test_rotation_is_applied_to_pixels():
    import shutil
    import subprocess
    import tempfile

    if not shutil.which("ffmpeg"):
        pytest.skip("ffmpeg absent")
    raw = make_video(duration=1, size=(320, 180))
    with tempfile.TemporaryDirectory() as tmp:
        src, dst = f"{tmp}/a.mp4", f"{tmp}/b.mp4"
        with open(src, "wb") as fh:
            fh.write(raw)
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-display_rotation:v", "90", "-i", src, "-c", "copy", dst], check=True)
        with open(dst, "rb") as fh:
            p = process_video(fh.read())
    assert (p.width, p.height) == (180, 320)  # paysage tourné → portrait
