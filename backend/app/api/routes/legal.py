"""Politique de confidentialité PUBLIQUE (sans connexion), exigée par Google Play.

Page statique servie par le backend déjà déployé : aucune infrastructure supplémentaire, aucune base, aucun cookie.
Texte aligné sur `app/lib/features/settings/legal_texts.dart` (version 2026-10) et `docs/PRIVACY.md` :
en cas de modification, changer les trois ensemble (un test vérifie la cohérence des points sensibles)."""
from html import escape

from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter(tags=["legal"])

LEGAL_VERSION = "2026-10"
UPDATED = "octobre 2026"
CONTACT = "contact@nalvium.com"
TITLE = "Politique de confidentialité — Nalvium"

SECTIONS: list[tuple[str, list[str]]] = [
    ("En bref", [
        "Nalvium fonctionne sans compte. Nous ne vous demandons ni nom ni e-mail pour diagnostiquer un problème.",
        ("Certaines informations que vous choisissez de saisir ou de photographier sont traitées pour vous aider ; "
        "certaines sont envoyées à un fournisseur d'intelligence artificielle. Ce document explique lesquelles, "
        "pourquoi, et comment les supprimer."),
    ]),
    ("Responsable du traitement", [
        "Nathanyel David BENCHIMOL, entrepreneur individuel (nom commercial : NB CONSULTING).",
        "SIREN 509 817 649 · SIRET 509 817 649 00080.",
        "10 rue d'Hanoï, 69100 Villeurbanne, France.",
        f"Contact : {CONTACT}.",
    ]),
    ("Données que Nalvium traite", [
        ("• Identifiant anonyme d'installation : un code aléatoire généré sur votre téléphone. Ce n'est ni votre numéro, "
        "ni l'identifiant de votre appareil, ni votre identifiant publicitaire."),
        "• Diagnostics : texte et informations que vous fournissez, vos réponses, les étapes proposées et leur résultat.",
        ("• Photos et vidéos de diagnostic, ainsi que quelques images extraites d'une vidéo pour l'analyse. "
        "Elles sont privées par défaut."),
        ("• Maison : équipements, pièces, marque et référence que vous renseignez, photo d'équipement facultative, "
        "et notice du fabricant lorsque vous demandez de la rechercher (copie conservée sur nos serveurs et indexée "
        "pour répondre à vos questions)."),
        ("• Demandes d'intervention : problème, prénom, téléphone, e-mail (facultatif), ville, code postal, "
        "disponibilité, médias que vous avez explicitement choisis, et votre consentement (version, date, catégories)."),
        "• Communauté : vos publications, commentaires, « Utile », signalements, et vos enregistrements (privés).",
        "• Données techniques minimales : journaux sans contenu personnel (identifiants techniques, statuts, durées).",
        "• Publicité : voir la section « Publicité et consentement ».",
    ]),
    ("Finalités", [
        ("Vous guider dans un dépannage ; retrouver vos équipements et leur historique ; préparer et transmettre une "
        "demande d'intervention que vous décidez d'envoyer ; permettre le partage de solutions dans la Communauté ; "
        "assurer la sécurité et le bon fonctionnement du service ; afficher de la publicité."),
    ]),
    ("Intelligence artificielle (OpenAI)", [
        ("Pour analyser votre problème, Nalvium envoie à un fournisseur d'IA (aujourd'hui OpenAI) : votre description, "
        "vos réponses, les photos ou images extraites d'une vidéo nécessaires à l'analyse et, si votre diagnostic est "
        "lié à un équipement, sa marque, sa référence, sa pièce et des extraits de sa notice. Nous demandons au "
        "fournisseur de ne pas conserver la conversation lorsque son option le permet."),
        ("L'identification d'un équipement sur photo et la recherche de notice envoient aussi une image, ou la seule "
        "marque et référence, au fournisseur, jamais votre identité."),
        "Vos données ne restent donc pas uniquement sur les serveurs de Nalvium.",
    ]),
    ("Photos et vidéos", [
        ("Les médias de diagnostic restent privés. Leur localisation (GPS) et leurs métadonnées (EXIF) sont supprimées "
        "à l'enregistrement."),
        ("Une photo n'est publique que si vous la choisissez pour la Communauté : une copie nettoyée est alors créée ; "
        "l'original reste privé."),
        "Aucun média n'est transmis dans une demande d'intervention sans que vous l'ayez sélectionné explicitement.",
    ]),
    ("Demandes d'intervention et notification Telegram", [
        ("Avant l'envoi, vous voyez ce qui sera transmis et vous donnez un consentement explicite. Pendant le pilote, "
        "le service est disponible à Lyon et dans un rayon de 50 km. Nous n'utilisons pas votre position GPS : seuls "
        "la ville et le code postal que vous saisissez servent à vérifier la zone. Aucune adresse complète n'est demandée."),
        ("Lorsque vous envoyez une demande, Nalvium l'enregistre sur ses serveurs (source de vérité) et envoie une "
        "notification interne à l'exploitant via la messagerie Telegram. Ce message peut contenir : prénom, téléphone, "
        "ville, code postal, disponibilité, catégorie, résumé du problème et, si vous y avez consenti, certaines "
        "informations du diagnostic (équipement, constats, hypothèses non confirmées, actions déjà essayées)."),
        ("Vos photos et vidéos ne sont pas envoyées à Telegram : seul leur nombre peut apparaître dans la notification. "
        "Votre e-mail (facultatif) n'y figure pas non plus."),
        ("Votre demande peut ensuite être transmise aux opérateurs ou partenaires concernés lorsqu'elle est effectivement "
        "prise en charge, et uniquement après votre consentement explicite."),
    ]),
    ("Communauté publique", [
        ("Une publication ou un commentaire est visible par tous les membres, sous le nom « Membre Nalvium ». "
        "Votre identifiant n'est jamais affiché. Ne publiez pas d'information personnelle."),
    ]),
    ("Publicité et consentement (Google AdMob)", [
        ("Nalvium affiche de la publicité via Google AdMob. L'application déclare l'autorisation d'accès à "
        "l'identifiant publicitaire Android, utilisé par Google selon vos choix. Dans l'Espace économique européen, un "
        "message de consentement (Google UMP) vous est proposé et vous pouvez modifier vos choix à tout moment dans "
        "Réglages › Confidentialité et publicité. Google agit pour la publicité en application de ses propres règles. "
        "Aucune donnée de diagnostic n'est transmise aux annonceurs."),
    ]),
    ("Destinataires et sous-traitants", [
        "• OpenAI : analyse par intelligence artificielle (voir plus haut).",
        "• Google (AdMob / UMP) : publicité et gestion du consentement.",
        ("• Railway Corp., 548 Market St PMB 68956, San Francisco, California 94104, États-Unis : hébergement. Les "
        "services applicatifs et volumes persistants de Nalvium sont actuellement déployés dans la région EU West "
        "(Amsterdam, Pays-Bas)."),
        ("• Telegram : canal d'alerte interne à l'exploitant lors d'une demande d'intervention. Telegram ne reçoit ni "
        "votre diagnostic complet, ni vos photos ou vidéos : il ne porte que le texte de la notification. La base de "
        "données de Nalvium reste la source de vérité."),
        "• Opérateurs ou partenaires d'intervention : uniquement après votre consentement explicite.",
    ]),
    ("Transferts hors Union européenne", [
        ("Plusieurs de ces prestataires (OpenAI, Google, Railway, Telegram) peuvent traiter des données en dehors de "
        "l'Union européenne, notamment aux États-Unis. Nalvium ne garantit donc pas que vos données restent limitées à "
        "l'Union européenne ; les transferts concernés reposent sur les mécanismes prévus par le RGPD lorsqu'ils sont "
        "applicables."),
    ]),
    ("Conservation", [
        ("Vos diagnostics, médias, équipements, notices, demandes d'intervention envoyées, publications et commentaires "
        "sont conservés tant que vous ne supprimez pas vos données depuis Réglages › Mes données."),
        ("Les brouillons de demande, photos temporaires non rattachées, brouillons de Communauté non publiés et fichiers "
        "orphelins peuvent être supprimés lors d'opérations de maintenance (délais de quelques heures à 14 jours selon "
        "le cas)."),
        ("Les notifications Telegram sont conservées dans la conversation Telegram de l'exploitant jusqu'à leur "
        "suppression par celui-ci."),
    ]),
    ("Suppression de vos données", [
        ("Réglages › Mes données › Supprimer mes données : suppression définitive de tout ce qui est rattaché à votre "
        "identifiant anonyme sur nos serveurs, fichiers compris. Cette suppression ne peut pas rappeler une notification "
        "Telegram déjà envoyée, ni une demande déjà transmise à un opérateur ou partenaire."),
        f"Si vous n'avez plus l'application, écrivez à {CONTACT} en indiquant ce qui permet de retrouver votre demande.",
    ]),
    ("Vos droits (RGPD)", [
        ("Vous disposez des droits d'accès, de rectification, d'effacement, de limitation, d'opposition et de "
        f"portabilité. Pour les exercer (y compris l'export de vos données, traité manuellement) : {CONTACT}."),
        "Vous pouvez aussi introduire une réclamation auprès de la CNIL (www.cnil.fr).",
    ]),
    ("Sécurité", [
        ("Échanges chiffrés (HTTPS), journaux sans contenu personnel, métadonnées "
        "GPS/EXIF supprimées. Aucun système n'est infaillible : ne transmettez pas d'information dont vous n'avez pas besoin."),
    ]),
    ("Contact", [
        f"{CONTACT}. Version {LEGAL_VERSION} — mise à jour : {UPDATED}.",
    ]),
]


def render_html() -> str:
    body = "".join(
        f"<section><h2>{escape(h)}</h2>" + "".join(f"<p>{escape(p)}</p>" for p in ps) + "</section>"
        for h, ps in SECTIONS
    )
    return (
        '<!doctype html><html lang="fr"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        f"<title>{escape(TITLE)}</title>"
        '<meta name="robots" content="index,follow">'
        "<style>:root{color-scheme:light dark}"
        "body{margin:0;padding:16px;font:16px/1.6 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}"
        "main{max-width:720px;margin:0 auto}h1{font-size:1.6rem;line-height:1.25}"
        "h2{font-size:1.15rem;margin-top:2rem}p{margin:.5rem 0;overflow-wrap:anywhere}"
        ".meta{opacity:.7}</style></head><body><main>"
        f"<h1>{escape(TITLE)}</h1>"
        f'<p class="meta">Version {LEGAL_VERSION} · {UPDATED}</p>{body}</main></body></html>'
    )


def render_markdown() -> str:
    out = [f"# {TITLE}", "", f"Version {LEGAL_VERSION} · {UPDATED}", ""]
    for h, ps in SECTIONS:
        out += [f"## {h}", ""]
        for p in ps:
            out += ["- " + p[2:] if p.startswith("• ") else p, ""]
    return "\n".join(out)


@router.get("/privacy", response_class=HTMLResponse, include_in_schema=False)
def privacy() -> HTMLResponse:
    return HTMLResponse(
        render_html(),
        headers={
            "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'",
            "Cache-Control": "public, max-age=3600",
        },
    )
