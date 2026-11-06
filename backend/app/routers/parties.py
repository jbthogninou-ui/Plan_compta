from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.customer import Customer
from app.models.supplier import Supplier
from app.models.user import User
from app.schemas.party import CustomerCreate, CustomerResponse, SupplierCreate, SupplierResponse

router = APIRouter(tags=["parties"])


@router.get("/customers", response_model=list[CustomerResponse])
async def list_customers(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    result = await db.execute(select(Customer).where(Customer.company_id == user.company_id))
    return result.scalars().all()


@router.post("/customers", response_model=CustomerResponse, status_code=201)
async def create_customer(
    payload: CustomerCreate, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)
):
    customer = Customer(company_id=user.company_id, **payload.model_dump())
    db.add(customer)
    await db.commit()
    await db.refresh(customer)
    return customer


@router.get("/suppliers", response_model=list[SupplierResponse])
async def list_suppliers(db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)):
    result = await db.execute(select(Supplier).where(Supplier.company_id == user.company_id))
    return result.scalars().all()


@router.post("/suppliers", response_model=SupplierResponse, status_code=201)
async def create_supplier(
    payload: SupplierCreate, db: AsyncSession = Depends(get_db), user: User = Depends(get_current_user)
):
    supplier = Supplier(company_id=user.company_id, **payload.model_dump())
    db.add(supplier)
    await db.commit()
    await db.refresh(supplier)
    return supplier
