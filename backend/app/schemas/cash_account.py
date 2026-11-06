from uuid import UUID

from pydantic import BaseModel

from app.models.cash_account import CashAccountType


class CashAccountCreate(BaseModel):
    account_id: UUID
    name: str
    type: CashAccountType
    iban: str | None = None


class CashAccountResponse(CashAccountCreate):
    id: UUID
    is_active: bool

    class Config:
        from_attributes = True
