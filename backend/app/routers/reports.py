from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.accounting.balance_sheet import get_balance_sheet
from app.accounting.income_statement import get_income_statement
from app.accounting.ledger import get_ledger
from app.accounting.trial_balance import get_trial_balance
from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/trial-balance")
async def trial_balance(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return await get_trial_balance(db, user.company_id)


@router.get("/ledger")
async def ledger(
    account_id: UUID | None = None,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return await get_ledger(db, user.company_id, account_id)


@router.get("/balance-sheet")
async def balance_sheet(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return await get_balance_sheet(db, user.company_id)


@router.get("/income-statement")
async def income_statement(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    return await get_income_statement(db, user.company_id)
