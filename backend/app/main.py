import logging

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.api.routes import (
    account,
    community,
    diagnostic,
    equipment,
    health,
    legal,
    service_requests,
    sessions,
)
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
    # Production : aucune documentation interactive ni schéma exposés. Pas de CORS : l'app mobile n'en a pas besoin.
    app = FastAPI(
        title="Nalvium API", version="0.1.0",
        docs_url=None if settings.is_production else "/docs",
        redoc_url=None, openapi_url=None if settings.is_production else "/openapi.json",
    )

    @app.middleware("http")
    async def security_headers(request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers.setdefault("Referrer-Policy", "no-referrer")
        return response

    @app.exception_handler(Exception)
    async def unexpected(request: Request, exc: Exception):  # jamais de trace, de SQL ni de secret côté client
        logging.getLogger("nalvium.api").error("unhandled error type=%s path=%s", type(exc).__name__, request.url.path)
        return JSONResponse({"detail": "internal_error"}, status_code=500)
    app.include_router(health.router)
    app.include_router(legal.router)
    app.include_router(diagnostic.router)
    app.include_router(sessions.router)
    app.include_router(equipment.router)
    app.include_router(service_requests.router)
    app.include_router(community.router)
    app.include_router(account.router)
    return app


app = create_app()
