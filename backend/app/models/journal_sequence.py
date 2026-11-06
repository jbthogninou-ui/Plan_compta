import uuid

from sqlalchemy import ForeignKey, Integer, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models.base import UUIDPKMixin


class JournalSequence(Base, UUIDPKMixin):
    """Compteur transactionnel : une ligne par (journal, année).
    Verrouillée via SELECT ... FOR UPDATE au moment de la validation
    d'une écriture, pour garantir une numérotation séquentielle sans trou
    même avec plusieurs utilisateurs concurrents."""
    __tablename__ = "journal_sequences"
    __table_args__ = (UniqueConstraint("journal_id", "year", name="uq_sequence_journal_year"),)

    company_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("companies.id"), nullable=False
    )
    journal_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("journals.id"), nullable=False
    )
    year: Mapped[int] = mapped_column(Integer, nullable=False)
    last_number: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
