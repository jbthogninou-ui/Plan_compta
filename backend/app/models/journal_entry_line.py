import uuid
from decimal import Decimal

from sqlalchemy import ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.base import UUIDPKMixin


class JournalEntryLine(Base, UUIDPKMixin):
    """Une ligne débit OU crédit (jamais les deux) d'une écriture.
    L'invariant Σdébit = Σcrédit est vérifié au niveau de l'écriture entière
    par l'Accounting Engine avant validation, pas au niveau de la ligne."""
    __tablename__ = "journal_entry_lines"

    entry_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("journal_entries.id", ondelete="CASCADE"), nullable=False
    )
    account_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("accounts.id"), nullable=False
    )
    label: Mapped[str] = mapped_column(String(255), nullable=False)
    debit: Mapped[Decimal] = mapped_column(Numeric(18, 2), default=0)
    credit: Mapped[Decimal] = mapped_column(Numeric(18, 2), default=0)
    party_type: Mapped[str | None] = mapped_column(String(20), nullable=True)
    party_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)

    entry = relationship("JournalEntry", back_populates="lines")
