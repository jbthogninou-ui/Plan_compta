from uuid import UUID

from pydantic import BaseModel


class DocumentResponse(BaseModel):
    id: UUID
    filename: str
    mime_type: str
    size_bytes: int
    transaction_id: UUID | None

    class Config:
        from_attributes = True
