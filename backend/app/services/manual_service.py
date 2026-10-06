"""Notice constructeur d'un équipement : recherche, validation, stockage privé, indexation, extraits pour le diagnostic.

Principes : source OFFICIELLE d'abord ; référence exacte (un modèle voisin n'est jamais associé sans accord) ; aucune
donnée utilisateur envoyée à l'extérieur (seulement marque + référence) ; copie locale réutilisée ensuite (pas
d'Internet à chaque diagnostic) ; la notice ne remplace jamais le Safety Engine."""
import hashlib
import logging
import uuid
from datetime import UTC, datetime
from urllib.parse import urlsplit

from fastapi.concurrency import run_in_threadpool

from app.ai.provider import AIProvider, AIProviderError
from app.db.models import Equipment, EquipmentDocument
from app.domain.diagnosis import ManualContext, ManualExcerpt
from app.manuals.extract import InvalidPdf, chunk_pages, extract_pages
from app.manuals.fetcher import FetchError, PdfFetcher
from app.manuals.matching import MatchLevel, evaluate_match
from app.manuals.search import search_passages
from app.media.storage import MediaStorage
from app.repositories.documents import DocumentRepository
from app.repositories.equipment import EquipmentRepository
from app.services.session_service import NotFound

log = logging.getLogger("nalvium.manual")

MIN_SCORE = 0.001
MAX_EXCERPTS = 4


class ReferenceRequired(Exception):
    """Marque ET référence sont nécessaires pour chercher une notice."""


class ManualService:
    def __init__(
        self,
        equipment: EquipmentRepository,
        documents: DocumentRepository,
        storage: MediaStorage,
        provider: AIProvider,
        fetcher: PdfFetcher,
    ) -> None:
        self._equipment, self._docs, self._storage = equipment, documents, storage
        self._provider, self._fetcher = provider, fetcher

    # ---- lecture ------------------------------------------------------------
    def _owned(self, user_id: uuid.UUID, equipment_id: uuid.UUID) -> Equipment:
        item = self._equipment.get_owned(equipment_id, user_id)
        if item is None:
            raise NotFound
        return item

    def get(self, user_id: uuid.UUID, equipment_id: uuid.UUID) -> EquipmentDocument | None:
        self._owned(user_id, equipment_id)
        return self._docs.for_equipment(equipment_id)

    def page(self, user_id: uuid.UUID, equipment_id: uuid.UUID, number: int) -> tuple[EquipmentDocument, str]:
        doc = self._usable(user_id, equipment_id)
        if not 1 <= number <= (doc.page_count or 0):
            raise NotFound
        return doc, self._docs.page_text(doc.id, number)

    def file(self, user_id: uuid.UUID, equipment_id: uuid.UUID) -> tuple[bytes, EquipmentDocument]:
        doc = self._usable(user_id, equipment_id)
        return self._storage.get(doc.storage_key), doc  # type: ignore[arg-type]

    def _usable(self, user_id: uuid.UUID, equipment_id: uuid.UUID) -> EquipmentDocument:
        doc = self.get(user_id, equipment_id)
        if doc is None or doc.status != "available" or not doc.storage_key:
            raise NotFound
        return doc

    # ---- recherche ----------------------------------------------------------
    async def search(self, user_id: uuid.UUID, equipment_id: uuid.UUID) -> tuple[EquipmentDocument, str]:
        """Retourne (document, issue) ; issue ∈ found | needs_confirmation | up_to_date | not_found | error | kept."""
        item = self._owned(user_id, equipment_id)
        brand, model = (item.brand or "").strip(), (item.model or "").strip()
        if not brand or not model:
            raise ReferenceRequired
        existing = self._docs.for_equipment(equipment_id)

        try:
            candidates = await self._provider.find_manual(brand, model)  # seules marque + référence sortent
        except AIProviderError:
            return self._failure(item, existing, "search_failed", "error")

        best = None
        fetch_errors = 0
        analyzed = 0
        for cand in candidates[:4]:
            try:
                data = await run_in_threadpool(self._fetcher.fetch, cand.url, brand)
                pages = await run_in_threadpool(extract_pages, data)
            except FetchError as exc:
                if exc.code != "source_not_official":
                    fetch_errors += 1
                continue
            except InvalidPdf:
                analyzed += 1
                continue
            analyzed += 1
            level = evaluate_match(model, pages)
            # Exacte d'abord ; parmi les exactes, la plus complète (une notice succincte de 2 pages vaut moins
            # qu'un manuel de 80 pages pour les codes erreur). Une approximative ne passe qu'en dernier.
            rank = (level is MatchLevel.EXACT, len(pages)) if level is not MatchLevel.NONE else None
            if rank and (best is None or rank > best[4]):
                best = (cand, data, pages, level, rank)

        if best is None:
            if fetch_errors and not analyzed:
                return self._failure(item, existing, "download_failed", "error")
            return self._failure(item, existing, None, "not_found")

        cand, data, pages, level, _rank = best
        checksum = hashlib.sha256(data).hexdigest()
        if existing and existing.status in ("available", "needs_confirmation") and existing.checksum == checksum:
            existing.retrieved_at = datetime.now(UTC)
            self._docs.commit()
            return existing, "up_to_date"

        doc_id = uuid.uuid4()
        key = f"{user_id}/manuals/{doc_id}.pdf"
        self._storage.put(key, data)
        exact = level is MatchLevel.EXACT
        self._replace(equipment_id, existing)
        doc = EquipmentDocument(
            id=doc_id, equipment_id=equipment_id, document_type="MANUAL",
            status="available" if exact else "needs_confirmation",
            title=cand.title[:300] or None, manufacturer=brand[:60], model_reference=model[:80],
            source_url=cand.url, source_domain=urlsplit(cand.url).hostname, source_is_official=True,
            storage_key=key, mime_type="application/pdf", file_size=len(data), checksum=checksum,
            page_count=len(pages), language=None, match_level=level.value, retrieved_at=datetime.now(UTC),
        )
        self._docs.add(doc, chunk_pages(pages))
        self._docs.commit()
        log.info("manual stored equipment=%s pages=%d level=%s", equipment_id, len(pages), level.value)
        return doc, "found" if exact else "needs_confirmation"

    def _failure(
        self, item: Equipment, existing: EquipmentDocument | None, code: str | None, outcome: str
    ) -> tuple[EquipmentDocument, str]:
        """Un échec ne détruit jamais une notice déjà disponible."""
        if existing is not None and existing.status in ("available", "needs_confirmation"):
            return existing, "kept"
        self._replace(item.id, existing)
        doc = EquipmentDocument(
            equipment_id=item.id, document_type="MANUAL", status="error" if outcome == "error" else "not_found",
            error_code=code, manufacturer=(item.brand or "")[:60] or None, model_reference=(item.model or "")[:80] or None,
        )
        self._docs.add(doc)
        self._docs.commit()
        return doc, outcome

    def _replace(self, equipment_id: uuid.UUID, existing: EquipmentDocument | None) -> None:
        if existing is None:
            return
        if existing.storage_key:
            self._storage.delete(existing.storage_key)
        self._docs.delete_for_equipment(equipment_id)

    def confirm(self, user_id: uuid.UUID, equipment_id: uuid.UUID) -> EquipmentDocument:
        """L'utilisateur accepte une notice dont la référence est proche (jamais fait automatiquement)."""
        doc = self.get(user_id, equipment_id)
        if doc is None or doc.status != "needs_confirmation":
            raise NotFound
        doc.status = "available"
        self._docs.commit()
        return doc

    def remove(self, user_id: uuid.UUID, equipment_id: uuid.UUID) -> None:
        self._owned(user_id, equipment_id)
        for key in self._docs.storage_keys(equipment_id):
            self._storage.delete(key)
        self._docs.delete_for_equipment(equipment_id)
        self._docs.commit()


class ManualRetriever:
    """Extraits de la notice liée à un équipement pour UN tour de diagnostic (recherche locale, aucun réseau)."""

    def __init__(self, documents: DocumentRepository) -> None:
        self._docs = documents

    def retrieve(self, equipment_id: uuid.UUID, query: str) -> tuple[uuid.UUID, ManualContext] | None:
        doc = self._docs.for_equipment(equipment_id)
        if doc is None or doc.status != "available":
            return None
        passages = [
            p for p in search_passages(self._docs.db, doc.id, query, limit=MAX_EXCERPTS) if p.score >= MIN_SCORE
        ]
        if not passages:
            return None
        return doc.id, ManualContext(
            manufacturer=doc.manufacturer, model=doc.model_reference,
            exact=doc.match_level == "exact",
            excerpts=[ManualExcerpt(page=p.page, section=p.section, text=p.text) for p in passages],
        )
