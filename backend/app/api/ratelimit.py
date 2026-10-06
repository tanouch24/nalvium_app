"""Protection simple contre les abus : fenêtre glissante PAR IDENTITÉ ANONYME (à défaut, par adresse).

V1 : état en mémoire du processus (suffisant pour un seul serveur ; à remplacer par un stockage partagé si plusieurs
instances). Les plafonds sont larges : un usage normal ne les atteint jamais."""
import threading
import time
from collections import defaultdict, deque

from fastapi import Header, HTTPException, Request

from app.config import get_settings

_lock = threading.Lock()
_hits: dict[tuple[str, str], deque[float]] = defaultdict(deque)


def reset() -> None:
    with _lock:
        _hits.clear()


def _check(bucket: str, key: str, limit: int, window_s: float) -> None:
    now = time.monotonic()
    with _lock:
        q = _hits[(bucket, key)]
        while q and now - q[0] > window_s:
            q.popleft()
        if len(q) >= limit:
            raise HTTPException(429, "rate_limited", headers={"Retry-After": str(int(window_s))})
        q.append(now)


def rate_limit(bucket: str, limit: int, window_s: float):
    """Dépendance FastAPI : `Depends(rate_limit("comment", 30, 600))`."""

    def dependency(request: Request, x_nalvium_install_id: str | None = Header(default=None)) -> None:
        if not get_settings().rate_limit_enabled:
            return
        key = x_nalvium_install_id or (request.client.host if request.client else "unknown")
        _check(bucket, key, limit, window_s)

    return dependency
