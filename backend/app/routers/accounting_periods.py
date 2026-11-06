from uuid import UUID

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.core.permissions import CAN_MANAGE_SETUP_ROLES, require_role
from app.database import get_db
from app.models.accounting_period import AccountingPeriod
from app.models.user import User
from app.schemas.accounting_period import (
    AccountingPeriodCreate,
    AccountingPeriodResponse,
    ClosePeriodResponse,
)
from app.services.period_service import close_period_and_log

router = APIRouter(prefix="/accounting-periods", tags=["accounting-periods"])


class ClosePeriodRequest(BaseModel):
    result_equity_account_id: UUID


@router.get("", response_model=list[AccountingPeriodResponse])
async def list_periods(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    result = await db.execute(
        select(AccountingPeriod).where(AccountingPeriod.company_id == user.company_id)
    )
    return result.scalars().all()


@router.post("", response_model=AccountingPeriodResponse, status_code=201)
async def create_period(
    payload: AccountingPeriodCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    require_role(user, CAN_MANAGE_SETUP_ROLES)
    period = AccountingPeriod(company_id=user.company_id, **payload.model_dump())
    db.add(period)
    await db.commit()
    await db.refresh(period)
    return period


@router.post("/{period_id}/close", response_model=ClosePeriodResponse)
async def close_period_endpoint(
    period_id: UUID,
    payload: ClosePeriodRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    require_role(user, CAN_MANAGE_SETUP_ROLES)
    return await close_period_and_log(db, period_id, payload.result_equity_account_id, user)
