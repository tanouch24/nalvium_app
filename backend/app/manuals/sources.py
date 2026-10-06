"""Sources OFFICIELLES par marque. Une notice n'est acceptée automatiquement que si son domaine figure ici
pour la marque de l'équipement. Liste volontairement courte et extensible ; marque inconnue = jamais officielle."""
import re
from urllib.parse import urlsplit

from app.equipment.catalog import normalize

# marque normalisée -> domaines officiels (le domaine lui-même et ses sous-domaines)
OFFICIAL_DOMAINS: dict[str, tuple[str, ...]] = {
    "bosch": ("bosch-home.com", "bosch-home.fr", "bosch-home.be", "bosch-home.ch", "bosch-home.co.uk",
              "media3.bsh-group.com", "bsh-group.com", "bosch.com"),
    "siemens": ("siemens-home.bsh-group.com", "siemens-home.com", "bsh-group.com"),
    "neff": ("neff-home.com", "bsh-group.com"),
    "samsung": ("samsung.com",),
    "lg": ("lg.com",),
    "whirlpool": ("whirlpool.fr", "whirlpool.com", "whirlpool.eu", "docs.whirlpool.eu"),
    "indesit": ("indesit.fr", "indesit.com", "docs.whirlpool.eu"),
    "hotpoint": ("hotpoint.eu", "hotpoint.fr", "docs.whirlpool.eu"),
    "electrolux": ("electrolux.fr", "electrolux.com", "electrolux-ui.com", "electrolux.be"),
    "aeg": ("aeg.fr", "aeg.com", "electrolux-ui.com"),
    "miele": ("miele.fr", "miele.com", "miele.be"),
    "beko": ("beko.com", "beko.fr"),
    "candy": ("candy-home.com", "candy.fr", "candy-group.com"),
    "haier": ("haier.com", "haier-europe.com"),
    "hisense": ("hisense.fr", "hisense.com", "hisense-eu.com"),
    "liebherr": ("liebherr.com",),
    "smeg": ("smeg.fr", "smeg.com"),
    "brandt": ("brandt.fr", "brandt.com"),
    "sauter": ("sauter.fr",),
    "de dietrich": ("dedietrich.fr", "dedietrich-thermique.fr", "dedietrich.com"),
    "vaillant": ("vaillant.fr", "vaillant.com", "vaillant-group.com"),
    "viessmann": ("viessmann.fr", "viessmann.com"),
    "saunier duval": ("saunierduval.fr", "saunierduval.com"),
    "atlantic": ("atlantic.fr", "atlantic-group.com", "groupe-atlantic.com"),
    "thermor": ("thermor.fr", "thermor.com"),
    "chaffoteaux": ("chaffoteaux.fr", "chaffoteaux.com"),
    "ariston": ("ariston.com", "ariston.fr"),
    "frisquet": ("frisquet.com",),
    "daikin": ("daikin.fr", "daikin.eu", "daikin.com"),
    "mitsubishi electric": ("mitsubishi-electric.fr", "mitsubishielectric.com"),
    "aldes": ("aldes.fr", "aldes.com"),
    "atlantic vmc": ("atlantic.fr",),
}

_ALIASES = {"bsh": "bosch", "saunier-duval": "saunier duval", "dedietrich": "de dietrich"}


def brand_key(brand: str) -> str:
    key = re.sub(r"\s+", " ", normalize(brand)).strip()
    return _ALIASES.get(key, key)


def official_domains(brand: str) -> tuple[str, ...]:
    return OFFICIAL_DOMAINS.get(brand_key(brand), ())


def host_of(url: str) -> str:
    return (urlsplit(url).hostname or "").lower()


def is_official_host(host: str, brand: str) -> bool:
    host = host.lower().rstrip(".")
    return any(host == d or host.endswith("." + d) for d in official_domains(brand))


def is_official_url(url: str, brand: str) -> bool:
    parts = urlsplit(url)
    return parts.scheme == "https" and not parts.username and is_official_host(parts.hostname or "", brand)
