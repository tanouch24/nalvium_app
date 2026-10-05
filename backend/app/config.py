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

    media_root: str = "./var/media"

    @property
    def is_production(self) -> bool:
        return self.env is Environment.PRODUCTION

    def validate_for_runtime(self) -> None:
        if self.is_production and "nalvium_dev" in self.database_url:
            raise RuntimeError("Identifiants de base de données de dev interdits en production")


@lru_cache
def get_settings() -> Settings:
    return Settings()
