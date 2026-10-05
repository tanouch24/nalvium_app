# NALVIUM

L'assistant personnel de la maison. « Montrez le problème. Nalvium vous guide. »

Projet créé de zéro (Phase 1 : fondations). Aucun code d'un ancien projet n'est réutilisé.

## Structure

```
app/        Flutter (Android d'abord, structure iOS présente)
backend/    FastAPI + PostgreSQL + Alembic
scripts/    db.sh (PostgreSQL local via Docker, port 5433)
```

## Démarrage

```bash
scripts/db.sh start                      # PostgreSQL (bases nalvium + nalvium_test)

cd backend
python3 -m venv .venv && .venv/bin/pip install -e '.[dev]'
cp .env.example .env                     # jamais commité
.venv/bin/alembic upgrade head           # migrations
.venv/bin/uvicorn app.main:app --reload  # http://localhost:8000/health
.venv/bin/python -m pytest               # tests (intégration : base nalvium_test)

cd ../app
flutter pub get && flutter gen-l10n
flutter analyze && flutter test
flutter run                              # téléphone Android branché
flutter build apk --debug
```

## Phase 2 : moteur IA réel

```bash
# backend/.env (jamais commité) : la clé reste côté serveur
OPENAI_API_KEY=...
OPENAI_MODEL=gpt-4o            # optionnel
cd backend && PYTHONPATH=. .venv/bin/python tools/check_openai.py   # test réel isolé (texte + image)

# serveur accessible depuis le téléphone (réseau local, DEV uniquement)
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8001

# app : l'URL du backend est fournie à la compilation (IP LAN actuelle du Mac : ipconfig getifaddr en0)
cd app && flutter run --dart-define=NALVIUM_API_URL=http://IP_LAN:8001
```

En release, `NALVIUM_API_URL` doit être une URL https publique (localhost, 10.0.2.2 et IP privées sont refusés).
Identité : UUID aléatoire anonyme par installation (en-tête `X-Nalvium-Install-Id`), sans compte.

## Architecture backend (`backend/app`)

- `api/` routes minces, sans logique métier
- `services/` orchestration (`DiagnosticService` : Safety Engine → IA → Safety Engine)
- `repositories/` accès base de données
- `domain/` modèles purs (diagnostic, niveaux de risque, actions)
- `ai/` abstraction provider (`AIProvider`). Aucun provider par défaut : pas de résultat simulé
- `safety/` Safety Engine déterministe, prioritaire sur l'IA
- `media/`, `equipment/`, `community/`, `professional_requests/` : réservés aux phases suivantes

Aucune clé API dans Flutter : tous les appels IA sont côté serveur.

## Architecture Flutter (`app/lib`)

- `core/theme` design system (couleurs, espacements, thème)
- `core/router` go_router, navigation à 4 onglets + caméra-action
- `core/widgets` composants partagés (états vides)
- `features/` shell, home, house, repair, community, capture, settings
- `domain/` modèles du futur diagnostic + contrat `DiagnosticRepository`
- `services/` capture photo derrière une interface (testable)
- `l10n/` i18n (français en V1, ARB prêt pour d'autres langues)
