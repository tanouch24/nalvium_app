"""Notices : sources officielles, téléchargement sûr, extraction, correspondance (sans réseau, PDF synthétiques)."""
import httpx
import pytest

from app.manuals import fetcher as fetcher_mod
from app.manuals.extract import InvalidPdf, chunk_pages, extract_pages
from app.manuals.fetcher import FetchError, HttpxPdfFetcher
from app.manuals.matching import MatchLevel, evaluate_match
from app.manuals.search import tokens
from app.manuals.sources import brand_key, is_official_url
from tests.helpers import make_pdf

BODY = "Texte de la notice d'utilisation de l'appareil. " * 12


def manual_pdf(model="SMS46GI01E"):
    return make_pdf([
        f"NOTICE D'UTILISATION\nLave-vaisselle Bosch {model}\n{BODY}",
        f"SECURITE\nLisez attentivement les consignes. {BODY}",
        f"CODES ERREUR\nE15 : fuite detectee, fermez le robinet d'arrivee d'eau.\nE24 : vidange impossible. {BODY}",
    ])


# ---- sources officielles -------------------------------------------------------
def test_official_requires_https_known_domain_and_matching_brand():
    assert is_official_url("https://www.bosch-home.com/manual.pdf", "Bosch")
    assert is_official_url("https://media3.bsh-group.com/x.pdf", "BOSCH")
    assert not is_official_url("http://www.bosch-home.com/manual.pdf", "Bosch")  # pas HTTPS
    assert not is_official_url("https://manuals-for-all.example/bosch.pdf", "Bosch")  # site tiers
    assert not is_official_url("https://bosch-home.com.evil.example/x.pdf", "Bosch")  # faux sous-domaine
    assert not is_official_url("https://user:pw@bosch-home.com/x.pdf", "Bosch")
    assert not is_official_url("https://www.samsung.com/x.pdf", "Bosch")  # domaine d'une autre marque
    assert not is_official_url("https://www.unknownbrand.com/x.pdf", "MarqueInconnue")


def test_brand_key_normalizes():
    assert brand_key("  BOSCH ") == "bosch" and brand_key("Saunier-Duval") == "saunier duval"


# ---- extraction ------------------------------------------------------------------
def test_extraction_keeps_page_numbers_codes_and_sections():
    pages = extract_pages(manual_pdf())
    assert [p.page for p in pages] == [1, 2, 3]
    assert "E15" in pages[2].text and "fermez le robinet" in pages[2].text
    chunks = chunk_pages(pages)
    e15 = next(c for c in chunks if "E15" in c.text)
    assert e15.page == 3 and e15.section == "CODES ERREUR"
    assert all(len(c.text) <= 1400 for c in chunks)
    # un passage ne chevauche jamais deux pages
    assert {c.page for c in chunks} == {1, 2, 3}


def test_invalid_and_textless_pdfs_are_refused():
    with pytest.raises(InvalidPdf):
        extract_pages(b"%PDF-1.4 pas vraiment un pdf")
    with pytest.raises(InvalidPdf) as exc:
        extract_pages(make_pdf(["", ""]))  # aucun texte natif : pas d'OCR en V1
    assert exc.value.code == "no_text_layer"


# ---- correspondance exacte -------------------------------------------------------
def test_exact_reference_in_the_document_is_an_exact_match():
    pages = extract_pages(manual_pdf("SMS46GI01E"))
    assert evaluate_match("SMS 46 GI 01 E", pages) is MatchLevel.EXACT
    assert evaluate_match("sms46gi01e", pages) is MatchLevel.EXACT


def test_neighbouring_model_is_approximate_never_exact():
    pages = extract_pages(manual_pdf("SMS46GI01"))  # le document parle d'un modèle voisin
    assert evaluate_match("SMS46GI01E", pages) is MatchLevel.APPROXIMATE


def test_other_appliance_is_rejected():
    pages = extract_pages(manual_pdf("WAT28400FF"))
    assert evaluate_match("SMS46GI01E", pages) is MatchLevel.NONE
    assert evaluate_match("AB", pages) is MatchLevel.NONE  # référence trop courte


# ---- téléchargement sûr ----------------------------------------------------------
@pytest.fixture(autouse=True)
def public_dns(monkeypatch):
    monkeypatch.setattr(fetcher_mod, "_assert_public_host", lambda host: None)


def make_fetcher(handler):
    return HttpxPdfFetcher(transport=httpx.MockTransport(handler))


def pdf_response(data=b"%PDF-1.4 ok", ctype="application/pdf"):
    return httpx.Response(200, content=data, headers={"content-type": ctype})


def test_fetch_ok_for_official_pdf():
    f = make_fetcher(lambda req: pdf_response(manual_pdf()))
    assert f.fetch("https://www.bosch-home.com/a.pdf", "Bosch").startswith(b"%PDF-")


@pytest.mark.parametrize("url", ["http://www.bosch-home.com/a.pdf", "https://evil.example/a.pdf"])
def test_fetch_refuses_non_https_or_non_official(url):
    f = make_fetcher(lambda req: pytest.fail("aucune requête ne doit partir"))
    with pytest.raises(FetchError) as exc:
        f.fetch(url, "Bosch")
    assert exc.value.code == "source_not_official"


def test_fetch_refuses_redirect_to_unofficial_host():
    f = make_fetcher(lambda req: httpx.Response(302, headers={"location": "https://evil.example/x.pdf"}))
    with pytest.raises(FetchError) as exc:
        f.fetch("https://www.bosch-home.com/a.pdf", "Bosch")
    assert exc.value.code == "source_not_official"


def test_fetch_follows_official_redirect_but_not_forever():
    calls = []

    def handler(req):
        calls.append(str(req.url))
        if req.url.path == "/a.pdf":
            return httpx.Response(302, headers={"location": "https://media3.bsh-group.com/b.pdf"})
        return pdf_response(manual_pdf())

    assert make_fetcher(handler).fetch("https://www.bosch-home.com/a.pdf", "Bosch").startswith(b"%PDF")
    assert len(calls) == 2
    loop = make_fetcher(lambda req: httpx.Response(302, headers={"location": "https://www.bosch-home.com/loop"}))
    with pytest.raises(FetchError) as exc:
        loop.fetch("https://www.bosch-home.com/loop", "Bosch")
    assert exc.value.code == "too_many_redirects"


def test_fetch_refuses_html_wrong_signature_and_oversize(monkeypatch):
    with pytest.raises(FetchError) as exc:
        make_fetcher(lambda r: pdf_response(b"<html>", "text/html")).fetch("https://www.bosch-home.com/a", "Bosch")
    assert exc.value.code == "not_pdf_content_type"
    with pytest.raises(FetchError) as exc:  # type annoncé PDF mais contenu non PDF
        make_fetcher(lambda r: pdf_response(b"MZ\x90 exe")).fetch("https://www.bosch-home.com/a", "Bosch")
    assert exc.value.code == "not_a_pdf"
    monkeypatch.setattr(fetcher_mod, "MAX_PDF_BYTES", 100)
    with pytest.raises(FetchError) as exc:
        make_fetcher(lambda r: pdf_response(b"%PDF-" + b"0" * 500)).fetch("https://www.bosch-home.com/a", "Bosch")
    assert exc.value.code == "too_large"


def test_fetch_refuses_non_public_address(monkeypatch):
    def private(host):
        raise FetchError("non_public_address")

    monkeypatch.setattr(fetcher_mod, "_assert_public_host", private)
    with pytest.raises(FetchError) as exc:
        make_fetcher(lambda r: pytest.fail("pas de requête")).fetch("https://www.bosch-home.com/a", "Bosch")
    assert exc.value.code == "non_public_address"


def test_fetch_sends_no_identity_headers():
    seen = {}

    def handler(req):
        seen.update(req.headers)
        return pdf_response(manual_pdf())

    make_fetcher(handler).fetch("https://www.bosch-home.com/a.pdf", "Bosch")
    assert "x-nalvium-install-id" not in seen and "cookie" not in seen and "authorization" not in seen


def test_query_tokens_keep_error_codes():
    assert "e15" in tokens("Mon lave-vaisselle affiche E15")
    assert "e15" in tokens("erreur e-15")
    assert "lave" not in tokens("Mon lave-vaisselle")


def test_family_pattern_with_wildcards_covers_the_model():
    pages = extract_pages(make_pdf([f"Lave-linge Manuel d'utilisation WW9*T******(*)/WW8*T******(*)\n{BODY * 3}"]))
    assert evaluate_match("WW90T534DAW", pages) is MatchLevel.EXACT
    assert evaluate_match("WW80T534DAW", pages) is MatchLevel.EXACT
    assert evaluate_match("WW70T534DAW", pages) is MatchLevel.NONE  # famille WW7 absente ici
    assert evaluate_match("WD90T534DAW", pages) is MatchLevel.NONE  # autre famille
    assert evaluate_match("WW90T534", pages) is MatchLevel.NONE  # longueur différente : pas la même référence
