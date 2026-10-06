"""Extraction du texte NATIF du PDF (aucun OCR). Les numéros de page sont conservés ; titres/sections détectés
par heuristique prudente ; le texte reste du contenu inerte (jamais interprété ni exécuté)."""
import io
import re
from dataclasses import dataclass

from pypdf import PdfReader
from pypdf.errors import PyPdfError

MAX_PAGES = 600
MIN_TEXT_CHARS = 300
CHUNK_CHARS = 1100


class InvalidPdf(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


@dataclass(frozen=True)
class PageText:
    page: int  # 1-indexé, tel qu'imprimé dans le PDF (index physique)
    text: str


@dataclass(frozen=True)
class Chunk:
    idx: int
    page: int
    section: str | None
    text: str


def _clean(text: str) -> str:
    text = text.replace("\x00", "")
    text = re.sub(r"[ \t]+", " ", text)
    return re.sub(r"\n{3,}", "\n\n", text).strip()


def extract_pages(data: bytes) -> list[PageText]:
    try:
        reader = PdfReader(io.BytesIO(data))
        if reader.is_encrypted and not reader.decrypt(""):
            raise InvalidPdf("encrypted")
        pages = []
        for i, page in enumerate(reader.pages[:MAX_PAGES], 1):
            try:
                pages.append(PageText(i, _clean(page.extract_text() or "")))
            except Exception:  # noqa: BLE001  # une page illisible n'invalide pas toute la notice
                pages.append(PageText(i, ""))
    except InvalidPdf:
        raise
    except (PyPdfError, ValueError, OSError, RecursionError) as exc:
        raise InvalidPdf("invalid_pdf") from exc
    if sum(len(p.text) for p in pages) < MIN_TEXT_CHARS:
        raise InvalidPdf("no_text_layer")  # PDF scanné : l'OCR n'est pas fourni en V1
    return pages


def page_count(data: bytes) -> int:
    try:
        return len(PdfReader(io.BytesIO(data)).pages)
    except (PyPdfError, ValueError, OSError) as exc:
        raise InvalidPdf("invalid_pdf") from exc


_HEADING_RE = re.compile(r"^(?:\d+(?:\.\d+)*[.)]?\s+)?[A-ZÀ-ÖØ-Ý][^\n]{2,68}$")


def _is_heading(line: str) -> bool:
    line = line.strip()
    if not 3 <= len(line) <= 70 or line.endswith((".", ",", ";")):
        return False
    letters = [c for c in line if c.isalpha()]
    if not letters:
        return False
    upper_ratio = sum(c.isupper() for c in letters) / len(letters)
    return bool(_HEADING_RE.match(line)) and (upper_ratio > 0.7 or bool(re.match(r"^\d+(\.\d+)*[.)]?\s+\S", line)))


def chunk_pages(pages: list[PageText]) -> list[Chunk]:
    """Passages de ~1 100 caractères, jamais à cheval sur deux pages ; section = dernier titre rencontré."""
    chunks: list[Chunk] = []
    section: str | None = None
    for page in pages:
        if not page.text:
            continue
        buf: list[str] = []
        size = 0
        buf_section = section
        for line in page.text.splitlines():
            heading = _is_heading(line)
            if buf and (heading or size + len(line) > CHUNK_CHARS):
                chunks.append(Chunk(len(chunks), page.page, buf_section, "\n".join(buf).strip()))
                buf, size = [], 0
            if heading:
                section = line.strip()[:200]
            if not buf:
                buf_section = section
            buf.append(line)
            size += len(line) + 1
        if buf:
            chunks.append(Chunk(len(chunks), page.page, buf_section, "\n".join(buf).strip()))
    return chunks
