# Image de production du backend Nalvium (FastAPI). Aucune clé ici : tout vient des variables d'environnement.
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /srv
COPY pyproject.toml alembic.ini ./
COPY app ./app
COPY migrations ./migrations
RUN pip install .

# Le volume persistant des médias est monté sur /data (NALVIUM_MEDIA_ROOT=/data/media).
# PORT est fourni par l'hébergeur ; --proxy-headers : l'adresse client réelle derrière le proxy HTTPS.
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --proxy-headers --forwarded-allow-ips='*'"]
