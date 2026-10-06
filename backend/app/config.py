"""Configuration par environnement. Aucun secret n'est commité : tout vient de l'env / .env."""
from enum import StrEnum
from functools import lru_cache

from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Environment(StrEnum):
    DEVELOPMENT = "development"
    TEST = "test"
    PRODUCTION = "production"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="NALVIUM_", env_file=".env", extra="ignore", populate_by_name=True
    )

    env: Environment = Environment.DEVELOPMENT
    database_url: str = "postgresql+psycopg://nalvium:nalvium_dev@localhost:5433/nalvium"

    # Serveur uniquement. Jamais exposé au client Flutter.
    ai_provider: str = "openai"
    openai_api_key: str | None = Field(
        default=None, validation_alias=AliasChoices("OPENAI_API_KEY", "NALVIUM_OPENAI_API_KEY")
    )
    openai_model: str = Field(
        default="gpt-4o", validation_alias=AliasChoices("OPENAI_MODEL", "NALVIUM_OPENAI_MODEL")
    )
    # Pour les modèles de raisonnement (gpt-5, o*) : "minimal" | "low" | "medium" | "high". None = défaut du modèle.
    openai_reasoning_effort: str | None = Field(
        default=None, validation_alias=AliasChoices("OPENAI_REASONING_EFFORT", "NALVIUM_OPENAI_REASONING_EFFORT")
    )
    openai_timeout_s: float = 60.0
    max_upload_bytes: int = 12 * 1024 * 1024
    # Vidéo (V1) : 15 s max (+1 s de tolérance), 30 Mo en entrée ; stockée en H.264/AAC ≤ 720p, sans métadonnées.
    max_video_bytes: int = 30 * 1024 * 1024
    max_video_seconds: float = 16.0
    video_frames_max: int = 6

    # Notification interne des nouvelles demandes (serveur uniquement ; absent = « non configurée »).
    telegram_bot_token: str | None = None
    telegram_chat_id: str | None = None
    telegram_timeout_s: float = 5.0

    media_root: str = "./var/media"

    # --- Production : API ---
    # Documentation interactive : jamais exposée en production.
    # Limites d'abus simples (mémoire du processus, par identité anonyme). Désactivable pour des tests de charge.
    rate_limit_enabled: bool = True

    # --- Rétention / nettoyage (ajustables après relecture juridique ; voir docs/RETENTION.md) ---
    # Brouillon de demande d'intervention jamais envoyé : l'utilisateur peut revenir dessus quelques jours.
    retention_draft_request_days: int = 14
    # Photo temporaire (ajout d'équipement / demande directe) non rattachée : abandon probable après 2 jours.
    retention_temp_photo_hours: int = 48
    # Copie publique de brouillon Communauté jamais publiée : un brouillon se fait en quelques minutes.
    retention_community_draft_hours: int = 24
    # Fichier du stockage sans aucune référence en base (reste d'un échec) : délai de sécurité avant suppression.
    retention_orphan_file_hours: int = 48
    # Nombre maximal d'éléments supprimés par catégorie et par exécution (job borné).
    cleanup_batch_limit: int = 500

    @property
    def is_production(self) -> bool:
        return self.env is Environment.PRODUCTION

    def validate_for_runtime(self) -> None:
        if self.is_production and "nalvium_dev" in self.database_url:
            raise RuntimeError("Identifiants de base de données de dev interdits en production")


@lru_cache
def get_settings() -> Settings:
    return Settings()
