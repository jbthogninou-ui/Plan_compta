from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.core.permissions import CAN_MANAGE_SETUP_ROLES, require_role
from app.database import get_db
from app.models.journal import Journal
from app.models.user import User
from app.schemas.journal import JournalCreate, JournalResponse

router = APIRouter(prefix="/journals", tags=["journals"])


@router.get("", response_model=list[JournalResponse])
async def list_journals(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    result = await db.execute(select(Journal).where(Journal.company_id == user.company_id))
    return result.scalars().all()


@router.post("", response_model=JournalResponse, status_code=201)
async def create_journal(
    payload: JournalCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    require_role(user, CAN_MANAGE_SETUP_ROLES)
    journal = Journal(company_id=user.company_id, **payload.model_dump())
    db.add(journal)
    await db.commit()
    await db.refresh(journal)
    return journal
