from datetime import UTC, datetime, timedelta

import pytest

from app.service_requests.validation import (
    InvalidField,
    normalize_phone,
    validate_availability,
    validate_email,
    validate_postal_code,
)


@pytest.mark.parametrize("raw,expected", [
    ("06 12 34 56 78", "+33612345678"), ("0612345678", "+33612345678"), ("06.12.34.56.78", "+33612345678"),
    ("+33 6 12 34 56 78", "+33612345678"), ("0033612345678", "+33612345678"), ("+41 79 123 45 67", "+41791234567"),
])
def test_valid_phones_are_normalized(raw, expected):
    assert normalize_phone(raw) == expected


@pytest.mark.parametrize("raw", ["", "123", "0012345678", "06 12 34 56", "abcdefghij", "+33 0 12 34 56 78", "06123456789"])
def test_invalid_phones_are_refused(raw):
    with pytest.raises(InvalidField) as e:
        normalize_phone(raw)
    assert e.value.code == "invalid_phone"


@pytest.mark.parametrize("raw", ["75011", "13001", "01000", "97400", "95000"])
def test_valid_postal_codes(raw):
    assert validate_postal_code(raw) == raw


@pytest.mark.parametrize("raw", ["", "7501", "750111", "ABCDE", "00100", "96000", "99999"])
def test_invalid_postal_codes(raw):
    with pytest.raises(InvalidField):
        validate_postal_code(raw)


def test_email_is_optional_but_validated():
    assert validate_email("") is None and validate_email(None) is None
    assert validate_email(" Jean@Example.FR ") == "jean@example.fr"
    with pytest.raises(InvalidField):
        validate_email("pas-un-mail")


def test_availability_rules():
    assert validate_availability("asap", None, None) == ("asap", None, None)
    assert validate_availability("this_week", None, None)[0] == "this_week"
    tomorrow = (datetime.now(UTC) + timedelta(days=1)).date()
    kind, d, w = validate_availability("custom", tomorrow, "morning")
    assert kind == "custom" and d.date() == tomorrow and w == "morning"
    for bad in [("custom", None, "morning"), ("custom", tomorrow, None), ("custom", tomorrow, "night"), ("never", None, None), (None, None, None)]:
        with pytest.raises(InvalidField):
            validate_availability(*bad)
    with pytest.raises(InvalidField) as e:
        validate_availability("custom", (datetime.now(UTC) - timedelta(days=2)).date(), "morning")
    assert e.value.code == "availability_in_the_past"
