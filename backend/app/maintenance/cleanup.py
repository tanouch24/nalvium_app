"""Nettoyage des données TEMPORAIRES ou ORPHELINES. Idempotent, borné, configurable, journalisé sans donnée personnelle.

Règles (durées dans Settings, justification dans docs/RETENTION.md) :
 • brouillons de demande d'intervention jamais envoyés, au-delà de N jours ;
 • photos temporaires (sans diagnostic, ni équipement, ni demande) au-delà de N heures ;
 • copies publiques Communauté de brouillon jamais publiées, au-delà de N heures ;
 • fichiers du stockage qu'AUCUNE ligne de la base ne référence, au-delà de N heures.
Ne supprime JAMAIS : un diagnostic, un média encore référencé, une demande envoyée, une publication."""
import logging
import time
from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.config import Settings, get_settings
from app.db.models import (
    CommunityMedia,
    Equipment,
    EquipmentDocument,
    MediaAsset,
    ServiceRequest,
    ServiceRequestMedia,
    VideoFrame,
)
from app.media.storage import MediaStorage

log = logging.getLogger("nalvium.cleanup")


@dataclass
class CleanupReport:
    draft_requests: int = 0
    temp_photos: int = 0
    community_drafts: int = 0
    orphan_files: int = 0
    files_deleted: int = 0
    errors: int = 0
    capped: list[str] = field(default_factory=list)  # catégories arrêtées par la limite de lot


def _delete_files(storage: MediaStorage, keys: list[str], report: CleanupReport) -> None:
    for key in keys:
        try:
            storage.delete(key)
            report.files_deleted += 1
        except OSError:
            report.errors += 1


def referenced_keys(db: Session) -> set[str]:
    keys: set[str] = set()
    for sk, tk in db.execute(select(MediaAsset.storage_key, MediaAsset.thumb_key)):
        keys.update(k for k in (sk, tk) if k)
    keys.update(db.execute(select(VideoFrame.storage_key)).scalars())
    keys.update(k for k in db.execute(select(EquipmentDocument.storage_key)).scalars() if k)
    for sk, tk in db.execute(select(CommunityMedia.storage_key, CommunityMedia.thumb_key)):
        keys.update((sk, tk))
    return keys


def run_cleanup(
    db: Session, storage: MediaStorage, settings: Settings | None = None, now: datetime | None = None
) -> CleanupReport:
    s, now = settings or get_settings(), now or datetime.now(UTC)
    limit = s.cleanup_batch_limit
    report = CleanupReport()

    # 1. brouillons de demande jamais envoyés
    cutoff = now - timedelta(days=s.retention_draft_request_days)
    ids = list(db.execute(
        select(ServiceRequest.id).where(ServiceRequest.status == "DRAFT", ServiceRequest.updated_at < cutoff).limit(limit + 1)
    ).scalars())
    if len(ids) > limit:
        report.capped.append("draft_requests")
    ids = ids[:limit]
    if ids:
        db.execute(delete(ServiceRequest).where(ServiceRequest.id.in_(ids)))
        db.commit()
    report.draft_requests = len(ids)

    # 2. photos temporaires non référencées
    cutoff = now - timedelta(hours=s.retention_temp_photo_hours)
    in_use = (
        select(Equipment.primary_media_id).where(Equipment.primary_media_id.is_not(None))
        .union(select(ServiceRequestMedia.media_asset_id))
        .subquery()
    )
    temps = db.execute(
        select(MediaAsset).where(
            MediaAsset.kind == "photo", MediaAsset.session_id.is_(None), MediaAsset.created_at < cutoff,
            MediaAsset.id.not_in(select(in_use)),
        ).limit(limit + 1)
    ).scalars().all()
    if len(temps) > limit:
        report.capped.append("temp_photos")
    temps = temps[:limit]
    keys = [k for m in temps for k in (m.storage_key, m.thumb_key) if k]
    for m in temps:
        db.delete(m)
    db.commit()
    _delete_files(storage, keys, report)
    report.temp_photos = len(temps)

    # 3. copies publiques de brouillon abandonnées
    cutoff = now - timedelta(hours=s.retention_community_draft_hours)
    drafts = db.execute(
        select(CommunityMedia).where(CommunityMedia.post_id.is_(None), CommunityMedia.created_at < cutoff).limit(limit + 1)
    ).scalars().all()
    if len(drafts) > limit:
        report.capped.append("community_drafts")
    drafts = drafts[:limit]
    keys = [k for m in drafts for k in (m.storage_key, m.thumb_key)]
    for m in drafts:
        db.delete(m)
    db.commit()
    _delete_files(storage, keys, report)
    report.community_drafts = len(drafts)

    # 4. fichiers orphelins (aucune référence en base) : délai de sécurité, balayage borné
    known = referenced_keys(db)
    cutoff_ts = (now - timedelta(hours=s.retention_orphan_file_hours)).timestamp()
    orphans: list[str] = []
    for key, mtime in storage.iter_keys():
        if key not in known and mtime < cutoff_ts:
            orphans.append(key)
            if len(orphans) > limit:
                report.capped.append("orphan_files")
                orphans = orphans[:limit]
                break
    _delete_files(storage, orphans, report)
    report.orphan_files = len(orphans)

    log.info(
        "cleanup drafts=%d temp_photos=%d community_drafts=%d orphan_files=%d errors=%d capped=%s",
        report.draft_requests, report.temp_photos, report.community_drafts, report.orphan_files, report.errors, report.capped,
    )
    return report


def main() -> None:  # pragma: no cover - lancement manuel / cron : python -m app.maintenance.cleanup
    from sqlalchemy.orm import sessionmaker

    from app.db.session import make_engine
    from app.media.storage import LocalMediaStorage

    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(name)s %(message)s")
    started = time.monotonic()
    settings = get_settings()
    with sessionmaker(bind=make_engine(), expire_on_commit=False)() as db:
        run_cleanup(db, LocalMediaStorage(settings.media_root), settings)
    log.info("cleanup finished in %.1fs", time.monotonic() - started)


if __name__ == "__main__":  # pragma: no cover
    main()
