from datetime import date
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel

from app.models.transaction import PaymentMethod, TransactionStatus, TransactionType


class TransactionCreate(BaseModel):
    type: TransactionType
    transaction_date: date
    amount: Decimal
    description: str
    payment_method: PaymentMethod | None = None
    cash_account_id: UUID | None = None
    customer_id: UUID | None = None
    supplier_id: UUID | None = None


class TransactionResponse(BaseModel):
    id: UUID
    type: TransactionType
    transaction_date: date
    amount: Decimal
    description: str
    payment_method: PaymentMethod | None
    status: TransactionStatus

    class Config:
        from_attributes = True


class JournalEntryLineResponse(BaseModel):
    account_id: UUID
    label: str
    debit: Decimal
    credit: Decimal

    class Config:
        from_attributes = True


class JournalEntryResponse(BaseModel):
    id: UUID
    number: str | None
    entry_date: date
    label: str
    status: str
    lines: list[JournalEntryLineResponse]

    class Config:
        from_attributes = True
