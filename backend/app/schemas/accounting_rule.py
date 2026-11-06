from uuid import UUID

from pydantic import BaseModel

from app.models.transaction import PaymentMethod, TransactionType


class AccountingRuleCreate(BaseModel):
    transaction_type: TransactionType
    payment_method: PaymentMethod | None = None
    journal_id: UUID
    debit_account_id: UUID
    credit_account_id: UUID


class AccountingRuleResponse(AccountingRuleCreate):
    id: UUID

    class Config:
        from_attributes = True
