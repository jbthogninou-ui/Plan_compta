from uuid import UUID

from pydantic import BaseModel

from app.models.account import AccountType, NormalBalance


class AccountCreate(BaseModel):
    code: str
    name: str
    type: AccountType
    normal_balance: NormalBalance
    parent_id: UUID | None = None


class AccountResponse(BaseModel):
    id: UUID
    code: str
    name: str
    type: AccountType
    normal_balance: NormalBalance
    parent_id: UUID | None
    is_active: bool

    class Config:
        from_attributes = True
