from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.core.permissions import CAN_MANAGE_SETUP_ROLES, require_role
from app.database import get_db
from app.models.accounting_rule import AccountingRule
from app.models.user import User
from app.schemas.accounting_rule import AccountingRuleCreate, AccountingRuleResponse

router = APIRouter(prefix="/accounting-rules", tags=["accounting-rules"])


@router.get("", response_model=list[AccountingRuleResponse])
async def list_rules(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    result = await db.execute(
        select(AccountingRule).where(AccountingRule.company_id == user.company_id)
    )
    return result.scalars().all()


@router.post("", response_model=AccountingRuleResponse, status_code=201)
async def create_rule(
    payload: AccountingRuleCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    require_role(user, CAN_MANAGE_SETUP_ROLES)
    rule = AccountingRule(company_id=user.company_id, **payload.model_dump())
    db.add(rule)
    await db.commit()
    await db.refresh(rule)
    return rule
