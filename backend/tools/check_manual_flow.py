"""Validation RÉELLE du flux notice : recherche officielle → téléchargement → extraction → indexation → question → GPT-5.

Usage : cd backend && PYTHONPATH=. .venv/bin/python tools/check_manual_flow.py "Samsung" "WW90T534DAW" "washing_machine" "ma question"
Utilise la base de DEV (utilisateur jetable, supprimé à la fin). Envoie à l'extérieur UNIQUEMENT marque + référence
(recherche) puis la question + extraits (moteur diagnostic, comme en production). N'affiche jamais la clé.
"""
import asyncio
import sys
import time
import uuid

from sqlalchemy.orm import sessionmaker

from app.ai.registry import build_provider
from app.config import get_settings
from app.db.session import make_engine
from app.domain.diagnosis import DiagnosticContext
from app.manuals.fetcher import HttpxPdfFetcher
from app.media.storage import LocalMediaStorage
from app.repositories.documents import DocumentRepository
from app.repositories.equipment import EquipmentRepository, HomeRepository
from app.repositories.sessions import MediaRepository, UserRepository
from app.services.diagnostic_service import DiagnosticService
from app.services.equipment_service import EquipmentInput, EquipmentService
from app.services.manual_service import ManualRetriever, ManualService


async def main(brand: str, model: str, etype: str, question: str) -> int:
    settings = get_settings()
    provider = build_provider(settings)
    db = sessionmaker(bind=make_engine(), expire_on_commit=False)()
    storage = LocalMediaStorage(settings.media_root)
    user = uuid.uuid4()
    equipment_repo, docs = EquipmentRepository(db), DocumentRepository(db)
    eq_svc = EquipmentService(UserRepository(db), HomeRepository(db), equipment_repo, MediaRepository(db), storage,
                              provider, docs)
    item = eq_svc.create(user, EquipmentInput(equipment_type=etype, brand=brand, model=model, room_type="laundry"))
    try:
        manuals = ManualService(equipment_repo, docs, storage, provider, HttpxPdfFetcher())
        t = time.monotonic()
        doc, outcome = await manuals.search(user, item.id)
        print(f"recherche : {outcome} en {time.monotonic() - t:.1f}s")
        print(f"  statut={doc.status} officielle={doc.source_is_official} niveau={doc.match_level}")
        print(f"  source={doc.source_url}")
        print(f"  pages={doc.page_count} taille={doc.file_size} octets sha256={doc.checksum}")
        print(f"  chunks indexés={docs.chunk_count(doc.id)}")
        if doc.status != "available":
            return 1
        found = ManualRetriever(docs).retrieve(item.id, question)
        if not found:
            print("aucun passage retrouvé")
            return 1
        _, ctx_manual = found
        print(f"\nrequête : {question!r}  → {len(ctx_manual.excerpts)} passages")
        for e in ctx_manual.excerpts:
            print(f"  [page {e.page} — {e.section}] {e.text[:220]!r}")
        ctx = DiagnosticContext(
            session_id="check", description=question, conversation=[question], manual=ctx_manual,
            equipment=None,
        )
        from app.domain.diagnosis import EquipmentContext

        ctx.equipment = EquipmentContext(type=etype, name=item.display_name, brand=brand, model=model, room="Buanderie")
        t = time.monotonic()
        analysis = await DiagnosticService(provider).analyze(ctx)
        print(f"\nGPT-5 ({time.monotonic() - t:.1f}s) action={analysis.next_action.type.value} "
              f"pages_utilisées={analysis.manual_pages_used}")
        print(f"  message : {analysis.next_action.message}")
        provided = {e.page for e in ctx_manual.excerpts}
        print(f"  citation UI : {sorted(set(analysis.manual_pages_used) & provided)}")
        return 0
    finally:
        eq_svc.delete(user, item.id)
        db.close()


if __name__ == "__main__":
    sys.exit(asyncio.run(main(*sys.argv[1:5])))
