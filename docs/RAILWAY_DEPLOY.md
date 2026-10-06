# Déploiement du backend sur Railway (PROCÉDURE — non exécutée)

Prérequis réels du code : API FastAPI, PostgreSQL, **médias sur disque** (`LocalMediaStorage`, un seul volume persistant, une seule instance).

## Fichiers du dépôt
- `backend/Dockerfile` : Python 3.12, `uvicorn` sur `$PORT` avec `--proxy-headers`.
- `backend/railway.json` : build Dockerfile, migration en pré-déploiement (`alembic upgrade head`), healthcheck `/health`, 1 réplica, redémarrage sur échec.
- Racine du service Railway : `backend/`.

## Procédure
1. Créer un projet Railway, ajouter **PostgreSQL**, puis un service depuis le dépôt (racine `backend/`).
2. Ajouter un **Volume** au service API, monté sur `/data`.
3. Variables du service (voir ci-dessous) ; `DATABASE_URL` = référence à celle de PostgreSQL.
4. Activer le domaine public (HTTPS automatique) et noter l'URL.
5. Déployer ; vérifier `GET /health` puis `GET /health/db`.
6. Construire l'app avec `--dart-define=NALVIUM_API_URL=https://<domaine>`.
7. Renseigner l'hébergeur dans `legal_texts.dart` (Railway + région) une fois déployé.

## Variables
OBLIGATOIRE
- `NALVIUM_ENV=production`
- `DATABASE_URL` : URL PostgreSQL (refusée si elle contient les identifiants de dev).
- `NALVIUM_MEDIA_ROOT=/data/media` : chemin absolu du volume (refus de démarrer sinon).
- `OPENAI_API_KEY` : clé serveur (secret).
- `OPENAI_MODEL=gpt-5` et `OPENAI_REASONING_EFFORT=low` : sans eux le défaut du code est `gpt-4o`, non validé.

OPTIONNELLE
- `NALVIUM_AI_PROVIDER` (défaut `openai` ; `none` = aucune IA).
- `NALVIUM_TELEGRAM_BOT_TOKEN`, `NALVIUM_TELEGRAM_CHAT_ID` (absents = « non configurée », service normal), `NALVIUM_TELEGRAM_TIMEOUT_S`.
- `NALVIUM_OPENAI_TIMEOUT_S`, `NALVIUM_MAX_UPLOAD_BYTES`, `NALVIUM_MAX_VIDEO_BYTES`, `NALVIUM_MAX_VIDEO_SECONDS`, `NALVIUM_VIDEO_FRAMES_MAX`.
- `NALVIUM_RATE_LIMIT_ENABLED` (défaut `true`).
- `NALVIUM_RETENTION_*`, `NALVIUM_CLEANUP_BATCH_LIMIT`.
- `PORT` : fourni par Railway.

## Limites connues
- Une seule instance (disque + limiteur de débit en mémoire).
- Nettoyage : `python -m app.maintenance.cleanup` a besoin de la base ET du volume ; un volume ne se monte que sur un service : voir docs/RETENTION.md.
- Sauvegardes : activer celles de PostgreSQL ; le volume doit être sauvegardé séparément.
