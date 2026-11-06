from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel

from app.models.accounting_period import PeriodStatus


class AccountingPeriodCreate(BaseModel):
    year: int
    start_date: date
    end_date: date


class AccountingPeriodResponse(BaseModel):
    id: UUID
    year: int
    start_date: date
    end_date: date
    status: PeriodStatus

    class Config:
        from_attributes = True


class ClosePeriodResponse(BaseModel):
    period: AccountingPeriodResponse
    closing_entry_number: str | None
    net_result: str
