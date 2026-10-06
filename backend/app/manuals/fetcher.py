"""Téléchargement SÛR d'un PDF : HTTPS uniquement, domaine officiel vérifié à CHAQUE redirection, adresses
publiques seulement (pas de réseau interne), taille plafonnée, type PDF vérifié par signature.
Rien du document n'est jamais exécuté. Aucune donnée utilisateur n'est envoyée (en-têtes génériques, pas de cookie)."""
import ipaddress
import socket
from typing import Protocol
from urllib.parse import urljoin, urlsplit

import httpx

from app.manuals.sources import is_official_url

MAX_PDF_BYTES = 40 * 1024 * 1024
MAX_REDIRECTS = 3
TIMEOUT_S = 40.0
USER_AGENT = "Mozilla/5.0 (compatible; NalviumManualFetcher/1.0)"


class FetchError(Exception):
    """`code` est un identifiant technique stable (jamais le contenu)."""

    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


class PdfFetcher(Protocol):
    def fetch(self, url: str, brand: str) -> bytes: ...


def _assert_public_host(host: str) -> None:
    try:
        infos = socket.getaddrinfo(host, 443, proto=socket.IPPROTO_TCP)
    except OSError as exc:
        raise FetchError("dns_failed") from exc
    for info in infos:
        if not ipaddress.ip_address(info[4][0]).is_global:
            raise FetchError("non_public_address")


class HttpxPdfFetcher:
    def __init__(self, transport: httpx.BaseTransport | None = None) -> None:
        self._transport = transport  # injectable pour les tests (aucun réseau)

    def fetch(self, url: str, brand: str) -> bytes:
        current = url
        with httpx.Client(
            timeout=TIMEOUT_S, follow_redirects=False, headers={"User-Agent": USER_AGENT}, transport=self._transport
        ) as client:
            for _ in range(MAX_REDIRECTS + 1):
                if not is_official_url(current, brand):
                    raise FetchError("source_not_official")
                _assert_public_host(urlsplit(current).hostname or "")
                try:
                    with client.stream("GET", current) as resp:
                        if resp.status_code in (301, 302, 303, 307, 308):
                            location = resp.headers.get("location")
                            if not location:
                                raise FetchError("bad_redirect")
                            current = urljoin(current, location)
                            continue
                        if resp.status_code != 200:
                            raise FetchError(f"http_{resp.status_code}")
                        ctype = resp.headers.get("content-type", "").lower()
                        if "pdf" not in ctype and "octet-stream" not in ctype:
                            raise FetchError("not_pdf_content_type")
                        declared = int(resp.headers.get("content-length") or 0)
                        if declared > MAX_PDF_BYTES:
                            raise FetchError("too_large")
                        data = bytearray()
                        for chunk in resp.iter_bytes():
                            data.extend(chunk)
                            if len(data) > MAX_PDF_BYTES:
                                raise FetchError("too_large")
                except httpx.HTTPError as exc:
                    raise FetchError("network_error") from exc
                if not bytes(data[:5]) == b"%PDF-":
                    raise FetchError("not_a_pdf")
                return bytes(data)
        raise FetchError("too_many_redirects")
