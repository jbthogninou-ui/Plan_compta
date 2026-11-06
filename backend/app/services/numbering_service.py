from datetime import date
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.journal_sequence import JournalSequence


async def get_next_entry_number(
    db: AsyncSession, company_id: UUID, journal_id: UUID, journal_code: str, year: int
) -> str:
    """Génère le prochain numéro d'écriture pour un journal/année donnés.

    Verrouille la ligne de compteur avec SELECT ... FOR UPDATE : si deux
    utilisateurs valident une écriture sur le même journal en même temps,
    le deuxième attend que le premier ait committé avant d'obtenir son
    numéro. Garantit une séquence sans trou, contrairement à un simple
    compteur applicatif en mémoire.

    Doit être appelé DANS la même transaction DB que la validation de
    l'écriture (le verrou est tenu jusqu'au commit/rollback appelant).
    """
    stmt = (
        select(JournalSequence)
        .where(JournalSequence.journal_id == journal_id, JournalSequence.year == year)
        .with_for_update()
    )
    result = await db.execute(stmt)
    sequence = result.scalar_one_or_none()

    if sequence is None:
        sequence = JournalSequence(
            company_id=company_id, journal_id=journal_id, year=year, last_number=0
        )
        db.add(sequence)
        await db.flush()
        # Re-verrouille après insertion pour rester cohérent en cas de course
        result = await db.execute(stmt)
        sequence = result.scalar_one()

    sequence.last_number += 1
    await db.flush()

    return f"{year}-{journal_code}-{sequence.last_number:06d}"
