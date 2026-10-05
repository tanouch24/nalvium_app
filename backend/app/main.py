import logging

from fastapi import FastAPI

from app.api.routes import diagnostic, health, sessions
from app.config import get_settings


def create_app() -> FastAPI:
    # Logs applicatifs (jamais de contenu : ni photo, ni texte, ni clé).
    logging.getLogger("nalvium").setLevel(logging.INFO)
    if not logging.getLogger("nalvium").handlers:
        handler = logging.StreamHandler()
        handler.setFormatter(logging.Formatter("%(asctime)s %(name)s %(message)s", "%H:%M:%S"))
        logging.getLogger("nalvium").addHandler(handler)
    settings = get_settings()
    settings.validate_for_runtime()
    app = FastAPI(title="Nalvium API", version="0.1.0", docs_url=None if settings.is_production else "/docs")
    app.include_router(health.router)
    app.include_router(diagnostic.router)
    app.include_router(sessions.router)
    return app


app = create_app()
