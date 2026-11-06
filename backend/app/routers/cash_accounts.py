from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.cash_account import CashAccount
from app.models.user import User
from app.schemas.cash_account import CashAccountCreate, CashAccountResponse

router = APIRouter(prefix="/cash-accounts", tags=["cash-accounts"])


@router.get("", response_model=list[CashAccountResponse])
async def list_cash_accounts(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    result = await db.execute(select(CashAccount).where(CashAccount.company_id == user.company_id))
    return result.scalars().all()


@router.post("", response_model=CashAccountResponse, status_code=201)
async def create_cash_account(
    payload: CashAccountCreate, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)
):
    account = CashAccount(company_id=user.company_id, **payload.model_dump())
    db.add(account)
    await db.commit()
    await db.refresh(account)
    return account
