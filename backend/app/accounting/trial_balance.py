"""Balance générale : total débit/crédit et solde par compte."""
from decimal import Decimal
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.account import Account
from app.models.journal_entry import EntryStatus, JournalEntry
from app.models.journal_entry_line import JournalEntryLine


async def get_trial_balance(db: AsyncSession, company_id: UUID) -> list[dict]:
    stmt = (
        select(
            Account.id,
            Account.code,
            Account.name,
            func.coalesce(func.sum(JournalEntryLine.debit), 0).label("total_debit"),
            func.coalesce(func.sum(JournalEntryLine.credit), 0).label("total_credit"),
        )
        .join(JournalEntryLine, JournalEntryLine.account_id == Account.id, isouter=True)
        .join(
            JournalEntry,
            (JournalEntry.id == JournalEntryLine.entry_id)
            & (JournalEntry.status == EntryStatus.VALIDATED),
            isouter=True,
        )
        .where(Account.company_id == company_id)
        .group_by(Account.id, Account.code, Account.name)
        .order_by(Account.code)
    )
    result = await db.execute(stmt)
    rows = result.all()

    balance = []
    for account_id, code, name, total_debit, total_credit in rows:
        total_debit = Decimal(total_debit)
        total_credit = Decimal(total_credit)
        balance.append({
            "account_id": account_id,
            "code": code,
            "name": name,
            "total_debit": total_debit,
            "total_credit": total_credit,
            "balance": total_debit - total_credit,
        })
    return balance
