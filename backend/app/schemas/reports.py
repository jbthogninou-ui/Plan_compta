from datetime import date
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel


class TrialBalanceLine(BaseModel):
    account_id: UUID
    code: str
    name: str
    total_debit: Decimal
    total_credit: Decimal
    balance: Decimal


class LedgerLine(BaseModel):
    entry_number: str | None
    entry_date: date
    label: str
    account_id: UUID
    debit: Decimal
    credit: Decimal
