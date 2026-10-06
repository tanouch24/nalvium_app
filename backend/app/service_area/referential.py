"""Référentiel local des communes françaises (nom, codes postaux, centre). Aucun appel réseau."""
import csv
import gzip
import re
import unicodedata
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

DATA = Path(__file__).parent / "data" / "communes_fr.csv.gz"

_ARRONDISSEMENT = re.compile(r"\s+\d{1,2}\s*(?:er|e|eme)?\s*(?:arrondissement|arr)?$|\s+arrondissement(?:\s+\d+)?$")
_CEDEX = re.compile(r"\s+cedex(?:\s+\d+)?$")


@dataclass(frozen=True)
class Commune:
    insee: str
    name: str
    postal_codes: tuple[str, ...]
    lat: float
    lon: float


def normalize_city(raw: str) -> str:
    """Casse, accents, tirets, apostrophes, « St » / « Ste », « Lyon 3e arrondissement », « CEDEX »."""
    text = unicodedata.normalize("NFKD", (raw or "").lower())
    text = "".join(c for c in text if not unicodedata.combining(c))
    text = re.sub(r"[’'`\-_.,/]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    text = _CEDEX.sub("", text)
    text = _ARRONDISSEMENT.sub("", text)
    words = ["saint" if w == "st" else "sainte" if w == "ste" else w for w in text.split()]
    return " ".join(words)


class Referential:
    def __init__(self, communes: list[Commune]) -> None:
        self.by_name: dict[str, list[Commune]] = {}
        self.by_postal: dict[str, list[Commune]] = {}
        for c in communes:
            self.by_name.setdefault(normalize_city(c.name), []).append(c)
            for cp in c.postal_codes:
                self.by_postal.setdefault(cp, []).append(c)
        self.size = len(communes)


@lru_cache
def load_referential() -> Referential:
    with gzip.open(DATA, "rt", encoding="utf-8", newline="") as fh:
        rows = [
            Commune(r["insee"], r["nom"], tuple(r["codes_postaux"].split()), float(r["lat"]), float(r["lon"]))
            for r in csv.DictReader(fh)
        ]
    return Referential(rows)
