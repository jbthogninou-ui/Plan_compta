import enum
import uuid

from sqlalchemy import Boolean, Enum, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class CashAccountType(str, enum.Enum):
    BANK = "BANK"
    CASH = "CASH"


class CashAccount(Base, UUIDPKMixin, TimestampMixin):
    """Compte de trésorerie (banque ou caisse), relié à un compte comptable
    du plan comptable pour que le moteur sache quoi débiter/créditer."""
    __tablename__ = "cash_accounts"

    company_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("companies.id"), nullable=False
    )
    account_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("accounts.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    type: Mapped[CashAccountType] = mapped_column(Enum(CashAccountType, name="cash_account_type"))
    iban: Mapped[str | None] = mapped_column(String(50))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
