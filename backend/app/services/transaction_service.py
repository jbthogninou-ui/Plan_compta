from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.accounting.engine import post_transaction
from app.models.transaction import Transaction
from app.models.user import User
from app.schemas.transaction import TransactionCreate
from app.services.audit_service import log_action


async def create_and_post_transaction(
    db: AsyncSession, payload: TransactionCreate, user: User
) -> Transaction:
    """Crée la Transaction puis la poste immédiatement via l'Accounting
    Engine. Les deux opérations sont dans la même transaction DB : si la
    génération de l'écriture échoue (règle manquante, période fermée...),
    tout est annulé, aucune Transaction orpheline en base."""
    transaction = Transaction(
        company_id=user.company_id,
        type=payload.type,
        transaction_date=payload.transaction_date,
        amount=payload.amount,
        description=payload.description,
        payment_method=payload.payment_method,
        cash_account_id=payload.cash_account_id,
        customer_id=payload.customer_id,
        supplier_id=payload.supplier_id,
        created_by=user.id,
    )
    db.add(transaction)
    await db.flush()

    entry = await post_transaction(db, transaction, posted_by=user.id)

    await log_action(
        db, user.company_id, user.id,
        action="transaction.post", entity_type="transaction", entity_id=str(transaction.id),
        new_values={"amount": str(transaction.amount), "entry_number": entry.number},
    )
    await db.commit()
    await db.refresh(transaction)
    return transaction
