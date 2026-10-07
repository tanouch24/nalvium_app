/// Textes juridiques et d'information de Nalvium, centralisés et versionnés. Ils décrivent le fonctionnement RÉEL de Nalvium.
///
/// Pour les modifier : modifier ce fichier (ou charger ces documents depuis une autre source) et changer [kLegalVersion].
const kLegalVersion = '2026-10';
const kLegalContact = 'contact@nalvium.com';

/// Identité de l'exploitant (entrepreneur individuel : ce n'est PAS une société, aucun capital social).
const kPublisherName = 'Nathanyel David BENCHIMOL';
const kTradeName = 'NB CONSULTING';
const kSiren = '509 817 649';
const kSiret = '509 817 649 00080';
const kApeCode = '70.22Z';
const kPublisherAddress = "10 rue d'Hanoï, 69100 Villeurbanne, France";
const _publisherLine =
    '$kPublisherName, entrepreneur individuel (nom commercial : $kTradeName)';

class LegalSection {
  const LegalSection(this.heading, this.paragraphs);
  final String heading;
  final List<String> paragraphs;
}

class LegalDocument {
  const LegalDocument({
    required this.id,
    required this.title,
    required this.sections,
  });
  final String id;
  final String title;
  final List<LegalSection> sections;
}

const privacyPolicy = LegalDocument(
  id: 'privacy',
  title: 'Politique de confidentialité',
  sections: [
    LegalSection('En bref', [
      "Nalvium fonctionne sans compte. Nous ne vous demandons ni nom ni e-mail pour diagnostiquer un problème.",
      "Certaines informations que vous choisissez de saisir ou de photographier sont traitées pour vous aider ; certaines sont envoyées à un fournisseur d'intelligence artificielle. Ce document explique lesquelles, pourquoi, et comment les supprimer.",
    ]),
    LegalSection("Qui est responsable", [
      "Responsable du traitement : $_publisherLine, $kPublisherAddress (SIREN $kSiren). Contact : $kLegalContact.",
    ]),
    LegalSection("Ce que Nalvium conserve", [
      "• Un identifiant anonyme d'installation : un code aléatoire généré sur votre téléphone. Ce n'est ni votre numéro, ni l'identifiant de votre appareil, ni votre identifiant publicitaire.",
      "• Vos diagnostics : ce que vous décrivez, vos réponses, les étapes proposées et leur résultat.",
      "• Vos photos et vidéos de diagnostic, ainsi que quelques images extraites d'une vidéo pour l'analyse. Elles sont PRIVÉES par défaut.",
      "• Votre Maison : équipements, pièces, marque et référence que vous renseignez, photo d'équipement facultative.",
      "• La notice du fabricant de vos équipements, lorsque vous demandez de la rechercher (copie conservée sur nos serveurs et indexée pour répondre à vos questions).",
      "• Vos demandes d'intervention : problème, prénom, téléphone, e-mail (facultatif), ville, code postal, disponibilité, médias que vous avez explicitement choisis, et votre consentement (version, date, catégories).",
      "• Communauté : vos publications, commentaires, « Utile », signalements, et vos enregistrements (privés).",
      "• Des données techniques minimales : journaux sans contenu personnel (identifiants techniques, statuts, durées).",
    ]),
    LegalSection("Pourquoi (finalités)", [
      "Vous guider dans un dépannage ; retrouver vos équipements et leur historique ; préparer et transmettre une demande d'intervention que vous décidez d'envoyer ; permettre le partage de solutions dans la Communauté ; assurer la sécurité et le bon fonctionnement du service ; afficher de la publicité (voir plus bas).",
    ]),
    LegalSection("Intelligence artificielle", [
      "Pour analyser votre problème, Nalvium envoie à un fournisseur d'IA (aujourd'hui OpenAI) : votre description, vos réponses, les photos ou images extraites d'une vidéo nécessaires à l'analyse, et — si votre diagnostic est lié à un équipement — sa marque, sa référence, sa pièce et des extraits de sa notice. Nous demandons au fournisseur de ne pas conserver la conversation lorsque son option le permet.",
      "Vos données ne restent donc pas uniquement sur les serveurs de Nalvium : celles nécessaires à l'analyse sont transmises au fournisseur d'IA. Les règles de sécurité de Nalvium s'appliquent avant et après l'IA.",
      "L'identification d'un équipement sur photo et la recherche de notice envoient aussi une image ou la seule marque et référence au fournisseur, jamais votre identité.",
    ]),
    LegalSection("Photos et vidéos", [
      "Les médias de diagnostic restent privés. Leur localisation (GPS) et leurs métadonnées (EXIF) sont supprimées à l'enregistrement.",
      "Une photo n'est publique que si vous la choisissez pour la Communauté : une COPIE nettoyée est alors créée ; l'original reste privé.",
      "Aucun média n'est transmis dans une demande d'intervention sans que vous l'ayez sélectionné explicitement.",
    ]),
    LegalSection("Demandes d'intervention", [
      "Avant l'envoi, vous voyez exactement ce qui sera transmis et vous donnez un consentement explicite. Seules les informations sélectionnées sont concernées.",
      "Pendant le pilote, ce service est disponible à Lyon et dans un rayon de 50 km. Nous n'utilisons PAS votre position GPS : seuls la ville et le code postal que vous saisissez servent à vérifier la zone. Aucune adresse complète n'est demandée.",
      "Lorsque vous envoyez une demande, Nalvium enregistre la demande sur ses serveurs (source de vérité) et envoie une notification interne à l'exploitant via la messagerie Telegram. Ce message peut contenir : prénom, téléphone, ville, code postal, disponibilité, catégorie, résumé du problème et, si vous y avez consenti, certaines informations du diagnostic (équipement, constats, hypothèses non confirmées, actions déjà essayées).",
      "Vos photos et vidéos ne sont PAS envoyées à Telegram : seul leur nombre peut apparaître dans la notification. Votre e-mail (facultatif) n'y figure pas non plus.",
      "Votre demande peut ensuite être transmise aux opérateurs ou partenaires concernés lorsqu'elle est effectivement prise en charge, et uniquement après votre consentement explicite. Seules les informations que vous avez choisi de transmettre sont concernées.",
    ]),
    LegalSection("Communauté", [
      "Une publication ou un commentaire est visible par tous les membres, sous le nom « Membre Nalvium ». Votre identifiant n'est jamais affiché. Ne publiez pas d'information personnelle.",
    ]),
    LegalSection("Publicité", [
      "Nalvium affiche de la publicité via Google AdMob. Dans l'Espace économique européen, un message de consentement (Google UMP) vous est proposé et vous pouvez modifier vos choix à tout moment dans Réglages › Confidentialité et publicité. Aucune donnée de diagnostic n'est transmise aux annonceurs.",
    ]),
    LegalSection("Durées de conservation", [
      "Vos données sont conservées tant que vous ne les supprimez pas depuis Réglages › Mes données. Les brouillons et fichiers temporaires abandonnés peuvent être supprimés lors d'opérations de maintenance.",
      "Les notifications Telegram sont conservées dans la conversation Telegram de l'exploitant jusqu'à leur suppression par celui-ci.",
    ]),
    LegalSection("Vos droits", [
      "Vous pouvez supprimer toutes vos données depuis Réglages › Mes données › Supprimer mes données. Cette suppression est définitive et efface les données rattachées à votre identifiant anonyme sur nos serveurs. Elle ne peut pas rappeler une notification Telegram déjà envoyée à l'exploitant, ni une demande d'intervention déjà transmise à un opérateur ou partenaire.",
      "Pour exercer vos droits d'accès, de rectification ou d'export, ou pour toute question : $kLegalContact.",
    ]),
    LegalSection("Sous-traitants et destinataires", [
      "Fournisseur d'IA : OpenAI. Publicité : Google (AdMob / UMP). Hébergement : Railway Corp., 548 Market St PMB 68956, San Francisco, California 94104, États-Unis. Les services applicatifs et volumes persistants de Nalvium sont actuellement déployés dans la région EU West (Amsterdam, Pays-Bas).",
      "Notification interne : Telegram, utilisé uniquement comme canal d'alerte à l'exploitant lors d'une demande d'intervention (contenu décrit plus haut). Telegram ne reçoit ni votre diagnostic complet, ni vos photos ou vidéos : il ne porte que le texte de la notification. La base de données de Nalvium reste la source de vérité.",
      "Plusieurs de ces prestataires (OpenAI, Google, Railway, Telegram) peuvent traiter des données en dehors de l'Union européenne, notamment aux États-Unis. Nalvium ne garantit donc pas que vos données restent limitées à l'Union européenne ; les transferts concernés reposent sur les mécanismes prévus par le RGPD lorsqu'ils sont applicables.",
    ]),
  ],
);

const termsOfUse = LegalDocument(
  id: 'terms',
  title: "Conditions d'utilisation",
  sections: [
    LegalSection('Objet', [
      "Nalvium est un assistant qui aide à comprendre et à traiter de petits problèmes domestiques. Il est fourni gratuitement, avec de la publicité.",
    ]),
    LegalSection('Ce que Nalvium est — et n\'est pas', [
      "• Nalvium est un outil d'assistance : ses réponses sont des hypothèses, jamais un diagnostic certain.",
      "• Nalvium ne remplace pas un professionnel qualifié.",
      "• Nalvium peut vous demander d'arrêter une manipulation. Vous ne devez jamais contourner un arrêt de sécurité.",
      "• En cas de danger immédiat, appelez les secours (18 ou 112).",
    ]),
    LegalSection("Votre responsabilité", [
      "Vous restez responsable de ce que vous faites chez vous. N'intervenez jamais sur le gaz, l'électricité sous tension ou une structure.",
    ]),
    LegalSection("Demandes d'intervention", [
      "Avec votre accord explicite, votre demande peut être transmise à un opérateur ou partenaire susceptible de vous aider, lorsqu'elle est effectivement prise en charge. Nalvium ne garantit ni qu'un professionnel soit disponible, ni un délai, ni un prix. Le service est actuellement limité à Lyon et à un rayon de 50 km.",
    ]),
    LegalSection("Communauté", [
      "Les solutions de la Communauté sont partagées par des membres. Elles ne sont ni validées par Nalvium, ni garanties, ni recommandées par un professionnel. Vous êtes responsable de ce que vous publiez : pas de contenu dangereux, illicite, trompeur, publicitaire ou contenant des informations personnelles. Nous pouvons retirer un contenu signalé.",
    ]),
    LegalSection("Disponibilité", [
      "Le service peut être interrompu ou modifié. L'analyse dépend d'un fournisseur d'IA et peut être indisponible.",
    ]),
    LegalSection("Contact", [
      '$kLegalContact.',
      "Droit applicable : droit français. Si vous êtes un consommateur, cela ne vous prive pas des droits que la loi impérative vous reconnaît, ni de la possibilité de saisir la juridiction compétente selon les règles applicables.",
    ]),
  ],
);

const legalNotice = LegalDocument(
  id: 'legal',
  title: 'Mentions légales',
  sections: [
    LegalSection('Éditeur', [
      "Nalvium est édité par $_publisherLine.",
      "SIREN : $kSiren · SIRET : $kSiret · Code APE : $kApeCode.",
      "Adresse : $kPublisherAddress.",
      "Directeur de la publication : $kPublisherName.",
    ]),
    LegalSection('Contact', [kLegalContact]),
    LegalSection('Hébergement', [
      "Railway Corp., 548 Market St PMB 68956, San Francisco, California 94104, États-Unis. Les services applicatifs et volumes persistants de Nalvium sont actuellement déployés dans la région EU West (Amsterdam, Pays-Bas).",
    ]),
    LegalSection('Propriété', [
      "Nalvium, son logo et ses contenus sont protégés. Les contenus publiés par les membres restent la responsabilité de leurs auteurs.",
    ]),
  ],
);

const aboutNalvium = LegalDocument(
  id: 'about',
  title: 'À propos et limites de Nalvium',
  sections: [
    LegalSection("Notre promesse", [
      "Montrez le problème. Nalvium vous guide, une étape à la fois.",
    ]),
    LegalSection("Les limites à connaître", [
      "• Nalvium donne des hypothèses, pas des certitudes.",
      "• Il ne remplace pas un professionnel qualifié.",
      "• Si Nalvium vous demande de vous arrêter, arrêtez-vous : c'est une règle de sécurité.",
      "• Aucun professionnel n'est garanti, ni aucun délai d'intervention.",
      "• Les solutions de la Communauté sont des témoignages de membres, pas des consignes officielles de Nalvium.",
    ]),
    LegalSection("Sécurité", [
      "Gaz, fumée, fils dénudés, eau près de l'électricité, tableau électrique, risque de structure, grosse fuite, produits dangereux, appareil sous pression : Nalvium s'arrête et vous explique quoi faire. En cas de danger immédiat, appelez le 18 ou le 112.",
    ]),
    LegalSection("Contact", [
      "$kLegalContact (réponse sans engagement de délai).",
    ]),
  ],
);

const aiInformation = LegalDocument(
  id: 'ai',
  title: "Informations relatives à l'IA",
  sections: [
    LegalSection("Comment l'IA est utilisée", [
      "Nalvium utilise un modèle d'intelligence artificielle (fourni par OpenAI) pour analyser votre description et vos photos et vous poser la question ou l'étape suivante.",
      "Les données nécessaires à l'analyse sont envoyées à ce fournisseur (voir la politique de confidentialité).",
    ]),
    LegalSection("Ce que l'IA peut se tromper", [
      "L'IA peut mal interpréter une photo ou proposer une hypothèse fausse. Chaque hypothèse est présentée avec prudence. Vérifiez et ne prenez aucun risque.",
    ]),
    LegalSection("Garde-fous", [
      "Des règles de sécurité de Nalvium s'appliquent avant et après l'IA : elles peuvent interrompre une conversation et priment toujours sur l'IA, sur la publicité et sur les demandes d'aide.",
      "Une notice de fabricant n'est utilisée que si elle a été retrouvée pour votre appareil exact.",
    ]),
  ],
);

const legalDocuments = <LegalDocument>[
  privacyPolicy,
  termsOfUse,
  legalNotice,
  aboutNalvium,
  aiInformation,
];

LegalDocument? legalById(String id) {
  for (final d in legalDocuments) {
    if (d.id == id) return d;
  }
  return null;
}
