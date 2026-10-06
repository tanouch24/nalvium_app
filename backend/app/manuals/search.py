"""Recherche documentaire LOCALE (PostgreSQL plein texte, configuration française). Aucun réseau, aucun vecteur :
simple et robuste en V1 ; l'interface permet de brancher plus tard un autre moteur (embeddings)."""
import re
import uuid
from dataclasses import dataclass

from sqlalchemy import case, func, select
from sqlalchemy.orm import Session

from app.db.models import DocumentChunk
from app.equipment.catalog import normalize

_STOP = {"le", "la", "les", "un", "une", "des", "de", "du", "d", "l", "et", "ou", "en", "au", "aux", "a", "à", "y", "il", "elle", "on", "ne", "pas", "plus", "ce", "se", "sa", "son", "ses", "mon", "ma", "mes", "que", "qui", "quoi", "dans", "sur", "sous", "avec", "sans", "pour", "par", "est", "sont", "ai", "as", "ont", "fait", "mais", "si", "ça", "ca", "cela", "j", "je", "tu", "nous", "vous", "ils", "elles", "ton", "votre", "notre", "leur", "lave", "vaisselle", "appareil", "machine"}
CODE_RE = re.compile(r"^[a-z]{1,2}-?\d{1,3}$")


@dataclass(frozen=True)
class Passage:
    page: int
    section: str | None
    text: str
    score: float


def tokens(query: str) -> list[str]:
    seen: list[str] = []
    for raw in re.findall(r"[a-z0-9]+(?:-[a-z0-9]+)?", normalize(query)):
        t = raw.replace("-", "") if CODE_RE.match(raw) else raw
        if len(t) >= 2 and t not in _STOP and t not in seen:
            seen.append(t)
    return seen[:24]


def search_passages(db: Session, document_id: uuid.UUID, query: str, limit: int = 4) -> list[Passage]:
    """Passages les plus pertinents d'UNE notice. Un code erreur (E15, F21…) trouvé à l'identique est favorisé."""
    toks = tokens(query)
    if not toks:
        return []
    ts = func.to_tsquery("french", " | ".join(toks))
    rank = func.ts_rank_cd(DocumentChunk.tsv, ts)
    codes = [t for t in toks if CODE_RE.match(t)]
    boost = 0
    for code in codes:
        pattern = r"\m" + re.sub(r"(\d)", r"-?\1", code, count=1) + r"\M"
        boost = boost + case((DocumentChunk.text.op("~*")(pattern), 1.0), else_=0.0)
    score = (rank + boost).label("score")
    stmt = (
        select(DocumentChunk.page, DocumentChunk.section, DocumentChunk.text, score)
        .where(DocumentChunk.document_id == document_id, DocumentChunk.tsv.op("@@")(ts))
        .order_by(score.desc(), DocumentChunk.page)
        .limit(limit)
    )
    return [Passage(p, s, t, float(sc)) for p, s, t, sc in db.execute(stmt).all()]
