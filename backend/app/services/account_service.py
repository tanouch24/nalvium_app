"""« Mes données » : suppression complète et export des données rattachées à l'identité ANONYME de l'installation.

Politique de suppression (documentée dans docs/RETENTION.md) :
 • tout ce que l'utilisateur possède est supprimé : diagnostics et leurs messages, médias privés (+ vidéos et images
   extraites), Maison, équipements, notices indexées, demandes d'intervention (+ médias sélectionnés), Utile,
   enregistrements, SIGNALEMENTS qu'il a faits, et son identité ;
 • ses publications et commentaires Communauté sont SUPPRIMÉS (pas anonymisés) : les commentaires d'autres membres
   sous ses publications disparaissent avec elles ;
 • les données d'autres utilisateurs ne sont jamais touchées ; les fichiers sont effacés du stockage ;
 • non effaçable : un message déjà envoyé à l'exploitant (notification interne) ne peut pas être rappelé."""
import logging
import uuid
from datetime import datetime

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.db.models import (
    CommunityComment,
    CommunityHelpful,
    CommunityMedia,
    CommunityPost,
    CommunitySave,
    DiagnosticSession,
    Equipment,
    EquipmentDocument,
    Home,
    MediaAsset,
    ServiceRequest,
    User,
    VideoFrame,
)
from app.media.storage import MediaStorage

log = logging.getLogger("nalvium.account")

EXPORT_VERSION = 1


class AccountService:
    def __init__(self, db: Session, storage: MediaStorage) -> None:
        self._db, self._storage = db, storage

    # ---- suppression --------------------------------------------------------
    def _storage_keys(self, user_id: uuid.UUID) -> set[str]:
        db = self._db
        keys: set[str] = set()
        for sk, tk in db.execute(select(MediaAsset.storage_key, MediaAsset.thumb_key).where(MediaAsset.user_id == user_id)):
            keys.update(k for k in (sk, tk) if k)
        keys.update(db.execute(
            select(VideoFrame.storage_key).join(MediaAsset, MediaAsset.id == VideoFrame.media_id).where(MediaAsset.user_id == user_id)
        ).scalars())
        keys.update(k for k in db.execute(
            select(EquipmentDocument.storage_key)
            .join(Equipment, Equipment.id == EquipmentDocument.equipment_id)
            .join(Home, Home.id == Equipment.home_id)
            .where(Home.user_id == user_id)
        ).scalars() if k)
        for sk, tk in db.execute(select(CommunityMedia.storage_key, CommunityMedia.thumb_key).where(CommunityMedia.owner_user_id == user_id)):
            keys.update((sk, tk))
        return keys

    def delete_all(self, user_id: uuid.UUID) -> dict:
        """Supprime TOUT ce qui est rattaché à cette identité. Idempotent : une identité inconnue ne produit rien."""
        keys = self._storage_keys(user_id)
        counts = {
            "diagnostics": self._count(DiagnosticSession, DiagnosticSession.user_id, user_id),
            "service_requests": self._count(ServiceRequest, ServiceRequest.user_id, user_id),
            "community_posts": self._count(CommunityPost, CommunityPost.owner_user_id, user_id),
            "community_comments": self._count(CommunityComment, CommunityComment.owner_user_id, user_id),
        }
        # Les clés étrangères en cascade (voir les migrations) suppriment l'arbre complet de l'utilisateur.
        self._db.execute(delete(User).where(User.id == user_id))
        self._db.commit()
        failed = 0
        for key in keys:  # après le commit : la base ne référence plus ces fichiers
            try:
                self._storage.delete(key)
            except OSError:
                failed += 1
        counts["files"] = len(keys) - failed
        log.info("account deleted files=%d file_errors=%d", counts["files"], failed)  # aucun identifiant ni contenu
        return counts

    def _count(self, model, column, user_id) -> int:
        from sqlalchemy import func

        return self._db.execute(select(func.count()).select_from(model).where(column == user_id)).scalar_one()

    # ---- export -------------------------------------------------------------
    def export(self, user_id: uuid.UUID) -> dict:
        """Export JSON lisible. Jamais : prompts, raisonnement, chemins de stockage, secrets, données d'autrui."""
        db = self._db

        def iso(d: datetime | None) -> str | None:
            return d.isoformat() if d else None

        sessions = []
        for s in db.execute(select(DiagnosticSession).where(DiagnosticSession.user_id == user_id).order_by(DiagnosticSession.created_at)).unique().scalars():
            sessions.append({
                "id": str(s.id), "title": s.title, "category": s.category, "status": s.status, "description": s.description,
                "created_at": iso(s.created_at),
                "messages": [{"role": m.role, "kind": m.kind, "text": m.text, "created_at": iso(m.created_at)} for m in s.messages],
                "actions": [{"instruction": a.instruction, "status": a.status} for a in s.actions],
                "equipment_id": str(s.equipment_id) if s.equipment_id else None,
            })
        media = [
            {"id": str(m.id), "kind": m.kind, "created_at": iso(m.created_at), "size_bytes": m.size_bytes,
             "session_id": str(m.session_id) if m.session_id else None}
            for m in db.execute(select(MediaAsset).where(MediaAsset.user_id == user_id).order_by(MediaAsset.created_at)).scalars()
        ]
        homes = []
        for h in db.execute(select(Home).where(Home.user_id == user_id)).scalars():
            eq = db.execute(select(Equipment).where(Equipment.home_id == h.id)).unique().scalars().all()
            homes.append({"id": str(h.id), "equipment": [
                {"id": str(e.id), "type": e.equipment_type, "name": e.display_name, "brand": e.brand, "model": e.model,
                 "room": e.room.name if e.room else None, "created_at": iso(e.created_at)} for e in eq]})
        requests = []
        for r in db.execute(select(ServiceRequest).where(ServiceRequest.user_id == user_id).order_by(ServiceRequest.created_at)).scalars():
            requests.append({
                "id": str(r.id), "status": r.status, "problem": r.problem_summary, "category": r.problem_category,
                "first_name": r.first_name, "phone": r.phone, "email": r.email, "city": r.city, "postal_code": r.postal_code,
                "availability": r.availability_type, "consent_version": r.consent_version, "consented_at": iso(r.consented_at),
                "consented_categories": list(r.consented_categories or []), "submitted_at": iso(r.submitted_at),
                "media_ids": [str(m.media_asset_id) for m in r.media], "snapshot": r.structured_context,
            })
        posts = [
            {"id": str(p.id), "title": p.title, "solution": p.solution, "category": p.category, "materials": p.materials,
             "status": p.status, "created_at": iso(p.created_at)}
            for p in db.execute(select(CommunityPost).where(CommunityPost.owner_user_id == user_id).order_by(CommunityPost.created_at)).scalars()
        ]
        comments = [
            {"id": str(c.id), "post_id": str(c.post_id), "body": c.body, "status": c.status, "created_at": iso(c.created_at)}
            for c in db.execute(select(CommunityComment).where(CommunityComment.owner_user_id == user_id)).scalars()
        ]
        return {
            "export_version": EXPORT_VERSION,
            "note": "Données rattachées à l'identité anonyme de cette installation. Aucun secret, aucun chemin interne.",
            "diagnostics": sessions, "media": media, "home": homes, "service_requests": requests,
            "community": {
                "posts": posts, "comments": comments,
                "helpful_post_ids": [str(x) for x in db.execute(select(CommunityHelpful.post_id).where(CommunityHelpful.owner_user_id == user_id)).scalars()],
                "saved_post_ids": [str(x) for x in db.execute(select(CommunitySave.post_id).where(CommunitySave.owner_user_id == user_id)).scalars()],
            },
        }
