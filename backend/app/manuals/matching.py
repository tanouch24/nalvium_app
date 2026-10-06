"""La notice correspond-elle EXACTEMENT à la référence ? Jamais d'association d'un modèle voisin sans accord."""
import re
from enum import StrEnum

from app.equipment.catalog import normalize
from app.manuals.extract import PageText


class MatchLevel(StrEnum):
    EXACT = "exact"
    APPROXIMATE = "approximate"
    NONE = "none"


def alnum(text: str) -> str:
    return re.sub(r"[^A-Z0-9]", "", normalize(text).upper())


def _covered_by_family_pattern(ref: str, text: str) -> bool:
    """Certaines notices couvrent une FAMILLE : « WW9*T******(*) / WW8*T******(*) ». L'étoile remplace un caractère ;
    la référence doit avoir exactement la longueur du motif et ses caractères fixes."""
    for chunk in re.split(r"\s*/\s*|\s{2,}", text):
        for token in re.findall(r"[A-Za-z0-9*]{5,}(?:\(\*\))?", chunk):
            core = re.sub(r"\(\*\)$", "", token).upper()
            if "*" not in core or sum(c != "*" for c in core) < 3:
                continue
            if len(core) == len(ref) and re.fullmatch(core.replace("*", "."), ref):
                return True
    return False


def evaluate_match(model: str, pages: list[PageText], scan_pages: int = 8) -> MatchLevel:
    """Seul le CONTENU du PDF fait foi (le titre et l'URL, fournis par une recherche web, ne prouvent rien).
    EXACT : la référence complète (lettres/chiffres, sans espaces ni tirets) figure dans les premières pages. APPROXIMATE : une référence très proche (même préfixe, ≤ 3 caractères de différence) figure dans
    le document. NONE sinon."""
    ref = alnum(model)
    if len(ref) < 4:
        return MatchLevel.NONE
    haystack = alnum(" ".join(p.text for p in pages[:scan_pages]))
    if ref in haystack:
        return MatchLevel.EXACT
    if any(_covered_by_family_pattern(ref, p.text) for p in pages[:scan_pages]):
        return MatchLevel.EXACT  # la notice déclare explicitement couvrir cette famille de modèles
    # candidats « ressemblants » : jetons (ou 2-4 jetons collés : « SMS 46 GI 01 ») de longueur voisine qui
    # partagent un long préfixe avec la référence
    prefix = ref[: max(5, len(ref) - 3)]
    words = re.findall(r"[A-Za-z0-9][A-Za-z0-9/\-]*", " ".join(p.text for p in pages[:scan_pages]))
    for i in range(len(words)):
        joined = ""
        for w in words[i : i + 4]:
            joined += alnum(w)
            if joined.startswith(prefix) and abs(len(joined) - len(ref)) <= 3:
                return MatchLevel.APPROXIMATE
    return MatchLevel.NONE
