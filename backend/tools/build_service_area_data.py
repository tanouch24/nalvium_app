"""Construit le référentiel local des communes françaises (nom, codes postaux, centre) pour la zone de service.

Usage : cd backend && .venv/bin/python tools/build_service_area_data.py
Source : API « Découpage administratif » (geo.api.gouv.fr, Etalab). Voir app/service_area/data/README.md.
Le fichier produit est versionné : la soumission d'une demande ne dépend d'AUCUN appel réseau."""
import csv
import gzip
import json
import urllib.request
from pathlib import Path

URL = "https://geo.api.gouv.fr/communes?fields=nom,code,codesPostaux,centre&format=json&geometry=centre"
OUT = Path(__file__).resolve().parent.parent / "app" / "service_area" / "data" / "communes_fr.csv.gz"


def main() -> None:
    with urllib.request.urlopen(URL, timeout=120) as resp:
        communes = json.load(resp)
    rows = []
    for c in communes:
        if not c.get("centre") or not c.get("codesPostaux"):
            continue
        lon, lat = c["centre"]["coordinates"]
        rows.append((c["code"], c["nom"], " ".join(c["codesPostaux"]), f"{lat:.4f}", f"{lon:.4f}"))
    rows.sort()
    with gzip.open(OUT, "wt", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["insee", "nom", "codes_postaux", "lat", "lon"])
        w.writerows(rows)
    print(f"{len(rows)} communes -> {OUT} ({OUT.stat().st_size // 1024} Ko)")


if __name__ == "__main__":
    main()
