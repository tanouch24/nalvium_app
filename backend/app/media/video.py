"""Traitement d'une vidéo AVANT stockage (V1, ≤ 15 s).

• valide : flux vidéo présent, durée ≤ limite, au moins une image ;
• normalise : applique la rotation d'affichage aux pixels, redimensionne (≤ 1280×720), 30 i/s max ;
• ré-encode en H.264 + AAC dans un conteneur NEUF → aucune métadonnée d'origine (GPS, titre, appareil…) ;
• extrait un petit nombre d'images représentatives (ordre et horodatage conservés), les plus nettes possible.
Aucune analyse n'est simulée : seules des images réelles de la vidéo sont produites.
"""
import io
import tempfile
from dataclasses import dataclass, field
from fractions import Fraction
from pathlib import Path

import av
from PIL import Image, ImageFilter, ImageStat

MAX_SIDE_W, MAX_SIDE_H = 1280, 720
MAX_FPS = 30
FRAME_MAX_SIDE = 1024
FRAME_JPEG_QUALITY = 80
CANDIDATE_EVERY_S = 0.4


class InvalidVideoError(ValueError):
    """Fichier illisible, sans vidéo, vide ou format non supporté."""


class VideoTooLongError(ValueError):
    pass


@dataclass(frozen=True)
class ExtractedFrame:
    t: float
    jpeg: bytes


@dataclass
class ProcessedVideo:
    data: bytes
    duration_s: float
    width: int
    height: int
    has_audio: bool
    frames: list[ExtractedFrame] = field(default_factory=list)
    content_type: str = "video/mp4"


def frame_count_for(duration_s: float, max_frames: int = 6) -> int:
    """Nombre d'images à garder : environ une toutes les 2,5 s, entre 2 et [max_frames]."""
    return max(2, min(max_frames, round(duration_s / 2.5) + 1))


def target_times(duration_s: float, n: int) -> list[float]:
    """Instants cibles régulièrement répartis, de 0 à la fin (ex. 15 s, n=6 → 0, 3, 6, 9, 12, 15)."""
    if n <= 1:
        return [0.0]
    return [round(duration_s * i / (n - 1), 3) for i in range(n)]


def sharpness(img: Image.Image) -> float:
    """Variance des contours (indice de netteté) : plus haut = plus net."""
    small = img.convert("L").resize((256, int(256 * img.height / max(img.width, 1)) or 1))
    return ImageStat.Stat(small.filter(ImageFilter.FIND_EDGES)).var[0]


def pick_frames(candidates: list[tuple[float, Image.Image]], duration_s: float, n: int) -> list[tuple[float, Image.Image]]:
    """Pour chaque instant cible, retient la candidate la plus nette de son créneau ; ordre chronologique garanti."""
    if not candidates:
        return []
    n = min(n, len(candidates))
    times = target_times(duration_s, n)
    # créneaux centrés sur chaque instant cible ; chaque candidate ne sert qu'une fois
    half = (times[1] - times[0]) / 2 if n > 1 else duration_s
    chosen: list[tuple[float, Image.Image]] = []
    used: set[int] = set()
    for target in times:
        pool = [(i, c) for i, c in enumerate(candidates) if i not in used and abs(c[0] - target) <= max(half, CANDIDATE_EVERY_S)]
        if not pool:  # repli : la plus proche non utilisée
            pool = sorted(((i, c) for i, c in enumerate(candidates) if i not in used), key=lambda ic: abs(ic[1][0] - target))[:1]
        if not pool:
            break
        i, best = max(pool, key=lambda ic: sharpness(ic[1][1]))
        used.add(i)
        chosen.append(best)
    chosen.sort(key=lambda c: c[0])
    return chosen


def _to_jpeg(img: Image.Image) -> bytes:
    img = img.convert("RGB")
    img.thumbnail((FRAME_MAX_SIDE, FRAME_MAX_SIDE), Image.Resampling.LANCZOS)
    out = io.BytesIO()
    img.save(out, format="JPEG", quality=FRAME_JPEG_QUALITY, optimize=True)  # nouveau fichier : aucun EXIF
    return out.getvalue()


def _fit(w: int, h: int) -> tuple[int, int]:
    scale = min(1.0, MAX_SIDE_W / max(w, h) if w >= h else MAX_SIDE_H / max(w, h))
    # paysage ≤ 1280×720, portrait ≤ 720×1280 ; dimensions paires (H.264)
    limit_long, limit_short = MAX_SIDE_W, MAX_SIDE_H
    scale = min(1.0, limit_long / max(w, h), limit_short / min(w, h))
    return max(2, int(w * scale) // 2 * 2), max(2, int(h * scale) // 2 * 2)


def process_video(raw: bytes, *, max_seconds: float = 16.0, max_frames: int = 6) -> ProcessedVideo:
    if not raw:
        raise InvalidVideoError("empty")
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "in.bin"
        dst = Path(tmp) / "out.mp4"
        src.write_bytes(raw)
        try:
            return _process(src, dst, max_seconds, max_frames)
        except (VideoTooLongError, InvalidVideoError):
            raise
        except (av.error.FFmpegError, OSError, ValueError, StopIteration) as exc:
            raise InvalidVideoError(type(exc).__name__) from exc


def _process(src: Path, dst: Path, max_seconds: float, max_frames: int) -> ProcessedVideo:
    with av.open(str(src)) as inp:
        if not inp.streams.video:
            raise InvalidVideoError("no_video_stream")
        vin = inp.streams.video[0]
        declared = float(inp.duration / av.time_base) if inp.duration else None
        if declared is not None and declared > max_seconds:
            raise VideoTooLongError(f"{declared:.1f}s")
        ain = inp.streams.audio[0] if inp.streams.audio else None

        fps = int(min(MAX_FPS, round(float(vin.average_rate or 30)))) or 30
        out_w = out_h = None
        with av.open(str(dst), "w", format="mp4", options={"movflags": "+faststart"}) as out:
            vout = out.add_stream("libx264", rate=fps)
            vout.pix_fmt = "yuv420p"
            vout.options = {"crf": "28", "preset": "veryfast"}
            aout = resampler = None
            if ain is not None:
                aout = out.add_stream("aac", rate=44100)
                aout.layout = "stereo"
                resampler = av.AudioResampler(format="fltp", layout="stereo", rate=44100)

            last_idx = -1
            last_t = 0.0
            next_candidate = 0.0
            candidates: list[tuple[float, Image.Image]] = []
            streams = [vin] + ([ain] if ain is not None else [])
            for packet in inp.demux(*streams):
                if packet.dts is None and packet.size == 0:
                    continue
                for frame in packet.decode():
                    if isinstance(frame, av.VideoFrame):
                        if frame.pts is None:
                            continue
                        t = float(frame.pts * frame.time_base)
                        img = frame.to_image()
                        rot = frame.rotation or 0
                        if rot:
                            img = img.rotate(rot, expand=True)  # rotation d'affichage appliquée aux pixels
                        if out_w is None:
                            out_w, out_h = _fit(*img.size)
                            vout.width, vout.height = out_w, out_h
                        if img.size != (out_w, out_h):
                            img = img.resize((out_w, out_h), Image.Resampling.LANCZOS)
                        if t > max_seconds + 0.5:
                            raise VideoTooLongError(f"{t:.1f}s")
                        last_t = max(last_t, t)
                        if t >= next_candidate:
                            candidates.append((t, img.copy()))
                            next_candidate = t + CANDIDATE_EVERY_S
                        idx = round(t * fps)
                        if idx <= last_idx:
                            continue  # image en trop (fps plafonné)
                        last_idx = idx
                        vf = av.VideoFrame.from_image(img)
                        vf.pts = idx
                        vf.time_base = Fraction(1, fps)
                        for pkt in vout.encode(vf):
                            out.mux(pkt)
                    elif aout is not None and resampler is not None:
                        for rf in resampler.resample(frame):
                            for pkt in aout.encode(rf):
                                out.mux(pkt)
            if out_w is None:
                raise InvalidVideoError("no_frames")
            for pkt in vout.encode(None):
                out.mux(pkt)
            if aout is not None and resampler is not None:
                for rf in resampler.resample(None):
                    for pkt in aout.encode(rf):
                        out.mux(pkt)
                for pkt in aout.encode(None):
                    out.mux(pkt)

    duration = round(max(last_t, (last_idx + 1) / fps), 3) if last_idx >= 0 else 0.0
    if duration > max_seconds:
        raise VideoTooLongError(f"{duration:.1f}s")
    n = frame_count_for(duration, max_frames)
    picked = pick_frames(candidates, duration, n)
    frames = [ExtractedFrame(t=round(t, 2), jpeg=_to_jpeg(im)) for t, im in picked]
    return ProcessedVideo(
        data=dst.read_bytes(),
        duration_s=duration,
        width=out_w,
        height=out_h,
        has_audio=ain is not None,
        frames=frames,
    )
