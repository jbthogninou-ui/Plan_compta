from uuid import UUID

from pydantic import BaseModel


class CustomerCreate(BaseModel):
    name: str
    email: str | None = None
    phone: str | None = None
    address: str | None = None


class CustomerResponse(CustomerCreate):
    id: UUID
    is_active: bool

    class Config:
        from_attributes = True


class SupplierCreate(BaseModel):
    name: str
    email: str | None = None
    phone: str | None = None
    address: str | None = None


class SupplierResponse(SupplierCreate):
    id: UUID
    is_active: bool

    class Config:
        from_attributes = True
