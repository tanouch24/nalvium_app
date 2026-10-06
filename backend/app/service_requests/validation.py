"""Validation des champs d'une demande : messages stables (codes), jamais le contenu saisi."""
import re
from datetime import UTC, date, datetime

AVAILABILITY_TYPES = ("asap", "today", "tomorrow", "this_week", "custom")
TIME_WINDOWS = ("morning", "afternoon", "evening")
CATEGORIES = ("plumbing", "appliance", "handyman", "electrical", "other")
CONSENT_VERSION = "2026-10"
STATUSES = ("DRAFT", "SUBMITTED", "CONTACT_PENDING", "CONTACTED", "CLOSED", "CANCELLED")
CANCELLABLE = ("DRAFT", "SUBMITTED", "CONTACT_PENDING")


class InvalidField(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


def clean_text(value: str | None, limit: int) -> str | None:
    value = " ".join((value or "").split())
    return value[:limit] or None


def normalize_phone(raw: str) -> str:
    """Numéro français (06 12 34 56 78, +33 6 12 34 56 78, 0033…) ou international E.164. Retourne E.164."""
    digits = re.sub(r"[\s.\-()]", "", raw or "")
    if digits.startswith("0033"):
        digits = "+33" + digits[4:]
    if digits.startswith("+"):
        if not re.fullmatch(r"\+[1-9]\d{7,14}", digits):
            raise InvalidField("invalid_phone")
        if digits.startswith("+33") and not re.fullmatch(r"\+33[1-9]\d{8}", digits):
            raise InvalidField("invalid_phone")
        return digits
    if re.fullmatch(r"0[1-9]\d{8}", digits):
        return "+33" + digits[1:]
    raise InvalidField("invalid_phone")


def validate_postal_code(raw: str) -> str:
    code = (raw or "").strip()
    if not re.fullmatch(r"\d{5}", code) or not ("01" <= code[:2] <= "95" or code[:2] in ("97", "98")):
        raise InvalidField("invalid_postal_code")
    return code


def validate_email(raw: str | None) -> str | None:
    raw = (raw or "").strip()
    if not raw:
        return None
    if len(raw) > 120 or not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]{2,}", raw):
        raise InvalidField("invalid_email")
    return raw.lower()


def validate_availability(kind: str | None, preferred: date | None, window: str | None) -> tuple[str, datetime | None, str | None]:
    if kind not in AVAILABILITY_TYPES:
        raise InvalidField("invalid_availability")
    if kind != "custom":
        return kind, None, None
    if preferred is None or window not in TIME_WINDOWS:
        raise InvalidField("invalid_availability")
    if preferred < datetime.now(UTC).date():
        raise InvalidField("availability_in_the_past")
    return kind, datetime(preferred.year, preferred.month, preferred.day, tzinfo=UTC), window
