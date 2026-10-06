"""Stockage PRIVÉ des médias (disque local en V1, interface remplaçable par un stockage objet)."""
from collections.abc import Iterator
from pathlib import Path
from typing import Protocol


class MediaStorage(Protocol):
    def put(self, key: str, data: bytes) -> None: ...
    def get(self, key: str) -> bytes: ...
    def delete(self, key: str) -> None: ...
    def iter_keys(self) -> Iterator[tuple[str, float]]: ...  # (clé, date de modification epoch)


class LocalMediaStorage:
    def __init__(self, root: str | Path) -> None:
        self._root = Path(root).resolve()

    def _path(self, key: str) -> Path:
        path = (self._root / key).resolve()
        if self._root not in path.parents:
            raise ValueError("invalid_storage_key")
        return path

    def put(self, key: str, data: bytes) -> None:
        path = self._path(key)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)

    def get(self, key: str) -> bytes:
        return self._path(key).read_bytes()

    def delete(self, key: str) -> None:
        self._path(key).unlink(missing_ok=True)

    def iter_keys(self) -> Iterator[tuple[str, float]]:
        """Tous les fichiers du stockage avec leur date de modification (balayage de nettoyage)."""
        if not self._root.exists():
            return
        for path in self._root.rglob("*"):
            if path.is_file():
                yield path.relative_to(self._root).as_posix(), path.stat().st_mtime
