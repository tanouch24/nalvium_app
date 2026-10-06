"""Zone pilote Lyon + 50 km : référentiel local, distance de Haversine, cohérence ville + code postal."""
import pytest

from app.service_area.config import ACTIVE_AREAS, PILOT_AREA, ServiceArea
from app.service_area.policy import AreaError, ServiceAreaPolicy, haversine_km
from app.service_area.referential import Commune, Referential, load_referential, normalize_city

policy = ServiceAreaPolicy()


@pytest.mark.parametrize("city,cp", [
    ("Lyon", "69003"), ("Lyon", "69001"), ("Lyon", "69009"),  # A
    ("Villeurbanne", "69100"),  # B
    ("Meyzieu", "69330"), ("Vienne", "38200"), ("Villefranche-sur-Saône", "69400"), ("Bourgoin-Jallieu", "38300"),  # C
    ("Ambérieu-en-Bugey", "01500"),  # D : ~47 km, en limite intérieure
])
def test_communes_inside_the_radius_are_accepted(city, cp):
    d = policy.evaluate(city, cp)
    assert d.in_zone and d.area == "Lyon" and d.distance_km <= 50.0


def test_communes_outside_the_rhone_department_are_inside_the_radius():
    assert not policy.evaluate("Vienne", "38200").commune.startswith("69")
    for city, cp in [("Vienne", "38200"), ("Ambérieu-en-Bugey", "01500")]:
        assert not cp.startswith("69") and policy.evaluate(city, cp).in_zone


@pytest.mark.parametrize("city,cp", [
    ("Saint-Étienne", "42000"),  # E : ~52 km, juste au-delà de la limite
    ("Bourg-en-Bresse", "01000"), ("Mâcon", "71000"), ("Roanne", "42300"),
    ("Grenoble", "38000"), ("Annecy", "74000"), ("Paris", "75001"), ("Marseille", "13001"), ("Valence", "26000"),  # F
])
def test_communes_outside_the_radius_are_refused(city, cp):
    d = policy.evaluate(city, cp)
    assert not d.in_zone and d.area is None and d.distance_km > 50.0


def test_just_beyond_the_limit_is_out_and_the_limit_is_not_stretched_to_60_km():
    st_etienne = policy.evaluate("Saint-Étienne", "42000")
    assert 50.0 < st_etienne.distance_km < 55.0 and not st_etienne.in_zone
    ref = load_referential()
    inside = [c for cs in ref.by_name.values() for c in cs if 49.0 <= haversine_km(PILOT_AREA.center_lat, PILOT_AREA.center_lon, c.lat, c.lon) <= 50.0]
    beyond = [c for cs in ref.by_name.values() for c in cs if 50.0 < haversine_km(PILOT_AREA.center_lat, PILOT_AREA.center_lon, c.lat, c.lon) <= 52.0]
    assert inside and beyond  # le référentiel contient des communes de part et d'autre de la limite
    for c in inside[:30]:
        assert policy.evaluate(c.name, c.postal_codes[0]).in_zone
    for c in beyond[:30]:
        assert not policy.evaluate(c.name, c.postal_codes[0]).in_zone


def test_every_commune_decision_matches_the_distance_rule():
    ref = load_referential()
    for cs in list(ref.by_name.values())[::40]:
        c = cs[0]
        d = haversine_km(PILOT_AREA.center_lat, PILOT_AREA.center_lon, c.lat, c.lon)
        assert policy.evaluate(c.name, c.postal_codes[0]).in_zone == (d <= 50.0 + 1e-6)


def test_numeric_tolerance_is_negligible():
    ref = Referential([
        Commune("1", "Pile", ("69999",), 45.7580 + 50.0 / 111.19493, 4.8351),  # ~50,0 km pile au nord
        Commune("2", "Loin", ("69998",), 45.7580 + 50.5 / 111.19493, 4.8351),
    ])
    p = ServiceAreaPolicy(referential=ref)
    assert p.evaluate("Loin", "69998").in_zone is False
    assert abs(p.evaluate("Pile", "69999").distance_km - 50.0) < 0.01


@pytest.mark.parametrize("city,cp,code", [
    ("Lyon", "75001", "city_postal_mismatch"), ("Villeurbanne", "13001", "city_postal_mismatch"), ("Paris", "69003", "city_postal_mismatch"),  # H
    ("Lyon", "99999", "unknown_postal_code"), ("Lyon", "00000", "unknown_postal_code"),  # I
    ("Lyon", "6900", "invalid_postal_code"), ("Lyon", "abcde", "invalid_postal_code"), ("Lyon", "", "invalid_postal_code"),
    ("Zzyzx-les-Bains", "69100", "unknown_city"), ("", "69100", "unknown_city"), ("   ", "69003", "unknown_city"),  # J
])
def test_inconsistent_or_unknown_input_is_refused_cleanly(city, cp, code):
    with pytest.raises(AreaError) as exc:
        policy.evaluate(city, cp)
    assert exc.value.code == code


@pytest.mark.parametrize("city,cp", [
    ("LYON", "69003"), ("lyon", "69003"), ("  Lyon  ", "69003"), ("Lyon 3e", "69003"), ("Lyon 3eme", "69003"), ("Lyon 3ème arrondissement", "69003"),
    ("villeurbanne", "69100"), ("VILLEURBANNE", "69100"), ("Villeurbanne", " 69 100 "),
    ("Villefranche sur Saone", "69400"), ("villefranche-sur-saône", "69400"), ("VILLEFRANCHE-SUR-SAONE", "69400"),
    ("St Priest", "69800"), ("Saint-Priest", "69800"), ("saint priest", "69800"),
    ("Amberieu en Bugey", "01500"), ("Ambérieu-en-Bugey", "01500"), ("Lyon CEDEX 03", "69003"),
])
def test_case_accents_hyphens_and_reasonable_variants_are_normalized(city, cp):
    assert policy.evaluate(city, cp).in_zone


def test_normalization_function():
    assert normalize_city("L'Arbresle") == "l arbresle" == normalize_city("l’arbresle")
    assert normalize_city("Ste-Foy-lès-Lyon") == "sainte foy les lyon"
    assert normalize_city("Marseille 8e Arrondissement") == "marseille"


def test_the_pilot_area_lives_in_one_place_and_other_scenarios_need_no_code():
    assert ACTIVE_AREAS == (PILOT_AREA,) and PILOT_AREA.name == "Lyon" and PILOT_AREA.radius_km == 50.0
    wide = ServiceAreaPolicy(areas=(ServiceArea("Lyon", PILOT_AREA.center_lat, PILOT_AREA.center_lon, 100.0),))
    assert wide.evaluate("Grenoble", "38000").in_zone and not wide.evaluate("Paris", "75001").in_zone
    multi = ServiceAreaPolicy(areas=(PILOT_AREA, ServiceArea("Marseille", 43.2965, 5.3698, 30.0)))
    assert multi.evaluate("Marseille", "13001").area == "Marseille" and multi.evaluate("Lyon", "69003").area == "Lyon"


def test_referential_is_local_complete_and_documented():
    ref = load_referential()
    assert ref.size > 34000
    from app.service_area.referential import DATA

    assert DATA.exists() and (DATA.parent / "README.md").read_text().lower().count("licence") >= 1
