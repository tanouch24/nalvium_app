"""Règles déterministes de la Communauté (aucune IA). Réutilise le Safety Engine sans le modifier."""
import re

from app.safety import SafetyInput, evaluate

CATEGORIES = ("plumbing", "appliance", "handyman", "other")
REPORT_REASONS = ("dangerous", "spam", "inappropriate", "personal_info", "other")
COMMUNITY_CONSENT_VERSION = "2026-10-community"
TITLE_MIN, TITLE_MAX = 3, 120
SOLUTION_MIN, SOLUTION_MAX = 10, 2000
MATERIALS_MAX = 200
COMMENT_MAX = 500
PAGE_DEFAULT, PAGE_MAX = 20, 50


class InvalidContent(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


def clean(text: str | None, limit: int) -> str | None:
    text = re.sub(r"[ \t]+", " ", (text or "").replace("\x00", "")).strip()
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text[:limit] or None


def check_safety(*texts: str | None) -> None:
    """Refuse une publication qui touche à un danger évident (gaz, électricité sous tension, produits…)."""
    decision = evaluate(SafetyInput(description=" . ".join(t for t in texts if t)))
    if decision.stop:
        raise InvalidContent("unsafe_content")


def validate_post(title: str | None, solution: str | None, category: str | None, materials: str | None) -> dict:
    t, s = clean(title, TITLE_MAX + 50), clean(solution, SOLUTION_MAX + 500)
    if not t or len(t) < TITLE_MIN:
        raise InvalidContent("title_required")
    if len(t) > TITLE_MAX:
        raise InvalidContent("title_too_long")
    if not s or len(s) < SOLUTION_MIN:
        raise InvalidContent("solution_required")
    if len(s) > SOLUTION_MAX:
        raise InvalidContent("solution_too_long")
    if category is not None and category not in CATEGORIES:
        raise InvalidContent("invalid_category")
    m = clean(materials, MATERIALS_MAX + 50)
    if m and len(m) > MATERIALS_MAX:
        raise InvalidContent("materials_too_long")
    check_safety(t, s, m)
    return {"title": t, "solution": s, "category": category, "materials": m}
