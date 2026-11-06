import enum
import uuid

from sqlalchemy import Enum, ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class JournalType(str, enum.Enum):
    SALES = "SALES"          # VE
    PURCHASES = "PURCHASES"  # AC
    BANK = "BANK"            # BQ
    CASH = "CASH"            # CA
    MISC = "MISC"            # OD - opérations diverses / écritures manuelles


class Journal(Base, UUIDPKMixin, TimestampMixin):
    __tablename__ = "journals"
    __table_args__ = (UniqueConstraint("company_id", "code", name="uq_journal_company_code"),)

    company_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("companies.id"), nullable=False
    )
    code: Mapped[str] = mapped_column(String(10), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    type: Mapped[JournalType] = mapped_column(Enum(JournalType, name="journal_type"), nullable=False)

    company = relationship("Company", back_populates="journals")
