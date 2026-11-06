"""Grand livre : liste des mouvements par compte."""
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.journal_entry import EntryStatus, JournalEntry
from app.models.journal_entry_line import JournalEntryLine


async def get_ledger(db: AsyncSession, company_id: UUID, account_id: UUID | None = None) -> list[dict]:
    stmt = (
        select(JournalEntryLine, JournalEntry)
        .join(JournalEntry, JournalEntryLine.entry_id == JournalEntry.id)
        .where(
            JournalEntry.company_id == company_id,
            JournalEntry.status == EntryStatus.VALIDATED,
        )
        .order_by(JournalEntry.entry_date, JournalEntry.number)
    )
    if account_id is not None:
        stmt = stmt.where(JournalEntryLine.account_id == account_id)

    result = await db.execute(stmt)
    rows = result.all()

    return [
        {
            "entry_number": entry.number,
            "entry_date": entry.entry_date,
            "label": line.label,
            "account_id": line.account_id,
            "debit": line.debit,
            "credit": line.credit,
        }
        for line, entry in rows
    ]
