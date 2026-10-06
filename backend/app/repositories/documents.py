import uuid

from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session

from app.db.models import DocumentChunk, EquipmentDocument
from app.manuals.extract import Chunk


class DocumentRepository:
    def __init__(self, db: Session) -> None:
        self._db = db

    @property
    def db(self) -> Session:
        return self._db

    def for_equipment(self, equipment_id: uuid.UUID) -> EquipmentDocument | None:
        stmt = (
            select(EquipmentDocument)
            .where(EquipmentDocument.equipment_id == equipment_id, EquipmentDocument.document_type == "MANUAL")
            .order_by(EquipmentDocument.created_at.desc())
            .limit(1)
        )
        return self._db.execute(stmt).scalar_one_or_none()

    def add(self, doc: EquipmentDocument, chunks: list[Chunk] | None = None) -> EquipmentDocument:
        self._db.add(doc)
        self._db.flush()
        for c in chunks or []:
            self._db.add(DocumentChunk(document_id=doc.id, idx=c.idx, page=c.page, section=c.section, text=c.text))
        self._db.flush()
        return doc

    def storage_keys(self, equipment_id: uuid.UUID) -> list[str]:
        stmt = select(EquipmentDocument.storage_key).where(
            EquipmentDocument.equipment_id == equipment_id, EquipmentDocument.storage_key.is_not(None)
        )
        return [k for k in self._db.execute(stmt).scalars()]

    def delete_for_equipment(self, equipment_id: uuid.UUID) -> None:
        self._db.execute(delete(EquipmentDocument).where(EquipmentDocument.equipment_id == equipment_id))
        self._db.flush()

    def page_text(self, document_id: uuid.UUID, page: int) -> str:
        stmt = (
            select(DocumentChunk.text)
            .where(DocumentChunk.document_id == document_id, DocumentChunk.page == page)
            .order_by(DocumentChunk.idx)
        )
        return "\n".join(self._db.execute(stmt).scalars())

    def chunk_count(self, document_id: uuid.UUID) -> int:
        return self._db.execute(
            select(func.count(DocumentChunk.id)).where(DocumentChunk.document_id == document_id)
        ).scalar_one()

    def commit(self) -> None:
        self._db.commit()
