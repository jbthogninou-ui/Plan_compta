from uuid import UUID

from pydantic import BaseModel

from app.models.journal import JournalType


class JournalCreate(BaseModel):
    code: str
    name: str
    type: JournalType


class JournalResponse(BaseModel):
    id: UUID
    code: str
    name: str
    type: JournalType

    class Config:
        from_attributes = True
