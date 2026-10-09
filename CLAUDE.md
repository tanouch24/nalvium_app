# Nalvium — contexte pour Claude Code

App mobile d'aide au dépannage de la maison : on montre le problème (photo,
vidéo, texte), l'IA guide pas à pas. Flutter (`app/`) + FastAPI/PostgreSQL
(`backend/`). Éditeur : Nathanyel BENCHIMOL, EI (NB CONSULTING). Package
`com.nalvium.nalvium`. Direction : « le Cal AI du dépannage ».

## Règles de travail (non négociables)

- Nathanyel n'est pas développeur : réponses en français, courtes, concrètes.
- **Aucun push git, aucun déploiement serveur, aucun envoi aux stores sans son
  « go » explicite.** Commits locaux OK, un lot = un commit, `git add` ciblé.
- Avant chaque commit : `flutter analyze` + `flutter test` (app) et
  `.venv/bin/python -m pytest -q` + `.venv/bin/ruff check app tests` (backend),
  tout au vert.
- Ne jamais contourner le Safety Engine (gaz, électricité, etc.) ni afficher une
  estimation de coût sur un arrêt de sécurité.
- Vouvoiement partout dans l'app (comme le prompt IA).

## Emplacements

- Code à jour : **`~/nalvium`** (remote `tanouch24/nalvium_app`), branche
  **`premium-refonte`** (13 commits locaux au 09/10/2026, non poussés).
- `~/Desktop/nalvium` (remote `tanouch24/nalvium`) = **site web** + ancienne app
  abandonnée. Ne pas y coder l'app.
- API prod : `https://nalvium-api-production.up.railway.app` (Railway, migrations
  auto via `preDeployCommand`). Page publique : `/privacy`.
- Base locale : `scripts/db.sh start` (Docker, port 5433) pour les tests backend.

## Décisions produit (08/10/2026)

- Plus de publicités, plus de Communauté. iPhone seul, portrait.
- Gratuit + **« Soutenir Nalvium »** : dons en achat intégré consommables
  `nalvium.tip.coffee` / `two_coffees` / `meal` (2,99 / 4,99 / 9,99 €), sans
  contrepartie. Lien Stripe **uniquement sur nalvium.com**, jamais dans l'app
  (ni lien vers la page qui le contient).
- Abonnement « Nalvium+ » (~1,99 €/mois) : plus tard, si l'app décolle.
- Points vitaux (vanne, tableau, gaz) **facultatifs**, jamais bloquants.
- Profil maison et photos des points vitaux : **sur le téléphone uniquement**.
- Design : fond `#F6F4EF`, encre `#15140F`, accent cuivre `#B0561F`, Figtree,
  boutons pilule. Tokens dans `app/lib/core/theme/` (aucune couleur en dur).
  Maquette : https://claude.ai/artifact/WW9ZS7EU9oKQmpXfxXTUcu

## Fait en 1.1.0+2 (branche premium-refonte)

Retrait pubs/Communauté ; design premium + navigation Accueil · Ma maison ·
Historique + bouton Scanner ; démarrage (accord IA nommant OpenAI, profil,
points vitaux) ; carte résultat chiffrée (faisabilité, durée, coût vous-même vs
artisan, pièces) ; « Signaler ce résultat » ; tableau de bord (suivi, économies
réelles, prochain entretien) ; Ma maison (points vitaux, entretiens) ; écran
Urgence (consignes fixes, 0 800 47 33 33, 18, 15, 112) ; dons ; accord IA
retirable dans Réglages ; textes légaux à jour. Serveur : estimation
(migration 0009), `POST /v1/sessions/{id}/report`, limite 8 diagnostics/24 h.

Installée sur le Samsung (adb `R9ZL304ZVLK`) le 09/10 en profil pour essai par
Nathanyel — retours à recueillir.

## Reste à faire avant la sortie (détail : `docs/SORTIE_1.1.md`)

1. Recueillir les retours de Nathanyel sur le Samsung.
2. Déployer le serveur `premium-refonte` (avec son go) AVANT l'app.
3. Créer les 3 dons dans App Store Connect et la Play Console.
4. Mettre à jour Confidentialité (Apple) et Sécurité des données (Google) :
   plus de pub ni d'identifiant publicitaire ; déclarer le contenu IA.
5. Nouvelles captures ; notes Apple (texte prêt dans le guide).
6. Envoyer : `release/nalvium-1.1.0+2.aab` (même clé que la 1.0) ; iOS via
   Xcode (`open app/build/ios/archive/Runner.xcarchive` › Distribute App) —
   recompiler les deux si le code change.
7. nalvium.com : politique à jour + page Stripe « Soutenir ».

## Compiler et vérifier

```bash
cd ~/nalvium/app
flutter build apk --profile --target-platform android-arm64 \
  --dart-define=NALVIUM_API_URL=https://nalvium-api-production.up.railway.app
adb -s R9ZL304ZVLK install -r build/app/outputs/flutter-apk/app-profile.apk
```

Captures sans téléphone : `app/test/_shots/shots_tool.dart` (exclu de git) —
`SHOTS=/home,/house H=4400 FLUTTER_ROOT=… flutter test test/_shots/shots_tool.dart --update-goldens`.

## Après la sortie

Rappels d'entretien par notification ; envoyer le profil maison à l'IA pour
personnaliser (mettre à jour la confidentialité) ; lecture hebdomadaire des
signalements (`result_reports`) ; Nalvium+.
