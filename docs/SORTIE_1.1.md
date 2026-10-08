# Nalvium 1.1.0 (build 2) — ce qu'il reste à faire pour la sortie

Branche `premium-refonte` (commits locaux, rien n'a été poussé ni déployé).
Fichiers prêts :
- Android : `release/nalvium-1.1.0+2.aab` (signé avec la même clé que la 1.0).
- iPhone : archive `app/build/ios/archive/Runner.xcarchive` (1.1.0, build 2,
  iPhone seul, portrait). L'envoi demande ton compte Apple dans Xcode :
  `open app/build/ios/archive/Runner.xcarchive` puis « Distribute App » ›
  App Store Connect.

## 1. Déployer le serveur AVANT de publier l'app (avec ton go)

L'app 1.1 a besoin du serveur à jour : estimation des coûts, signalement des
résultats, limite de 8 diagnostics par jour, page `/privacy` mise à jour.

- Railway : déployer la branche `premium-refonte` (dossier `backend/`).
- La migration `0009` (colonne `estimate`, table `result_reports`) s'applique toute seule au
  déploiement (`preDeployCommand: alembic upgrade head` dans `railway.json`) : vérifier les logs.
- Facultatif : `NALVIUM_DAILY_SESSION_LIMIT` (8 par défaut).
- Vérifier ensuite : `https://nalvium-api-production.up.railway.app/privacy`
  ne mentionne plus AdMob ni la Communauté.

L'ancienne app 1.0 continue de fonctionner avec ce serveur (les nouveaux champs
sont simplement ignorés).

## 2. Créer les 3 dons (achats intégrés CONSOMMABLES)

Mêmes identifiants sur les deux stores, sinon le bouton « Soutenir » affiche
« pas disponible ».

| Identifiant | Nom affiché | Prix |
|---|---|---|
| `nalvium.tip.coffee` | Un café | 2,99 € |
| `nalvium.tip.two_coffees` | Deux cafés | 4,99 € |
| `nalvium.tip.meal` | Un repas | 9,99 € |

- **Apple** (App Store Connect › Nalvium › Achats intégrés) : type *Consommable*.
  Description : « Un don pour soutenir Nalvium. Aucune contrepartie : tout reste
  gratuit. » Ajouter la capture de la feuille « Soutenir Nalvium » pour la
  vérification. Les rattacher à la version 1.1 avant de la soumettre.
- **Google** (Play Console › Monétiser › Produits intégrés) : mêmes ID, actifs.
- Le compte doit avoir un **profil de paiement** (Google) et l'**accord
  « Applications payantes »** signé (Apple), sinon les produits restent invisibles.

## 3. Mettre à jour les déclarations de confidentialité

**Apple — Confidentialité de l'app**
- Retirer : *Identifiants › Identifiant publicitaire*, *Données d'usage pour la
  publicité*. Suivi (tracking) : **Non**.
- Garder : Photos ou vidéos, Audio (son des vidéos), Contenu utilisateur (texte
  des diagnostics), Coordonnées (prénom, téléphone, e-mail des demandes
  d'intervention), Identifiant utilisateur (identifiant anonyme d'installation).
  Usage : fonctionnement de l'app. Non utilisées pour le suivi.

**Google — Sécurité des données**
- Retirer : identifiant publicitaire, partage avec Google pour la publicité.
- Déclarer : photos et vidéos, enregistrements audio, nom, téléphone, e-mail,
  autre contenu généré par l'utilisateur, identifiants de l'appareil ou autres
  (identifiant anonyme). Partage : OpenAI (analyse IA). Chiffrement en transit :
  oui. Suppression : oui, dans l'app (Réglages › Mes données) et par e-mail.
- Formulaire « Contenu généré par IA » : oui ; signalement dans l'app : oui
  (« Signaler ce résultat » sous chaque réponse).
- Publicités : **Non**.

## 4. Site nalvium.com

- La page de confidentialité du site (si elle est différente de `/privacy` du
  serveur) doit reprendre `docs/PRIVACY.md`.
- Page « Soutenir » avec ton lien Stripe : **uniquement sur le site**. L'app ne
  doit jamais y renvoyer.

## 5. Fiches et captures

- iPad retiré : plus de captures iPad nécessaires.
- Nouvelles captures (iPhone 6,9" et Android) : accueil (tableau de bord), carte
  résultat (« Estimation »), Ma maison (points vitaux + entretiens), Urgence,
  écran « C'est réglé ».
- Retirer de la fiche toute mention de la Communauté et de « gratuit avec pub ».

## 6. Notes pour l'équipe de vérification Apple (à coller, en anglais)

```
Nalvium is a free home-repair assistant. No account is needed.

How to test:
1. Launch the app and go through the short onboarding. The AI consent screen
   explains what is sent to OpenAI; tap "J'accepte et je continue".
   Every profile question and the "vital points" photos are optional.
2. On the home screen, tap "Décrire" and type, e.g., "Mon évier fuit sous le
   siphon". Nalvium asks one question at a time and shows an indicative
   "Estimation" card (DIY vs. professional cost; never a quote).
3. Safety: typing "Ça sent le gaz dans la cuisine" triggers a safety stop
   (no repair instructions, emergency numbers only).
4. "Signaler ce résultat" under every AI answer lets users report wrong,
   dangerous or offensive content.
5. "Soutenir Nalvium" (after a resolved repair, or Settings) offers optional
   consumable tips. They unlock nothing.
6. Settings › "Accord pour l'analyse IA" lets users withdraw consent;
   Settings › Mes données › Supprimer mes données deletes everything.

The "find a professional" request is a pilot limited to Lyon (France) + 50 km:
outside this area the app explains it is not available yet. This is expected.
No ads, no tracking, no user-generated public content.
```

## 7. Points ouverts (après la sortie)

- Les signalements sont en base (`result_reports`) : les lire chaque semaine
  (`SELECT created_at, reason, details FROM result_reports ORDER BY created_at DESC;`).
- Le profil maison n'est pas encore envoyé à l'IA (il reste sur le téléphone) :
  l'utiliser pour personnaliser les diagnostics serait une V1.2, avec mise à jour
  de la confidentialité.
- Rappels d'entretien par notification : à ajouter (aujourd'hui, visibles dans l'app).
- Abonnement « Nalvium+ » : plus tard, si l'app décolle.
