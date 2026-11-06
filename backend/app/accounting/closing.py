"""Clôture d'exercice.

Contrairement au bilan "à la volée" (qui recalcule le résultat en direct
depuis les comptes de produits/charges sans rien enregistrer), la clôture
POSTE une véritable écriture comptable qui :
  1. solde chaque compte de produit et de charge à zéro,
  2. reporte le résultat net dans un compte de capitaux propres désigné
     (ex: "Résultat de l'exercice" / "Report à nouveau").

Après clôture, le résultat de l'exercice est "figé" dans le grand livre :
consulter le bilan à cette date n'a plus besoin de recalculer le résultat,
il apparaît comme un solde de compte comme un autre. La période est ensuite
marquée CLOSED, ce qui bloque toute nouvelle écriture dessus (cf.
_get_open_period dans engine.py).
"""
from datetime import date
from decimal import Decimal
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.accounting.engine import validate_entry
from app.accounting.trial_balance import get_trial_balance
from app.core.exceptions import AccountingIntegrityError, NotFoundError
from app.models.account import Account, AccountType
from app.models.accounting_period import AccountingPeriod, PeriodStatus
from app.models.journal import Journal, JournalType
from app.models.journal_entry import JournalEntry
from app.models.journal_entry_line import JournalEntryLine


async def close_period(
    db: AsyncSession,
    company_id: UUID,
    period_id: UUID,
    result_equity_account_id: UUID,
    closed_by: UUID,
) -> tuple[AccountingPeriod, JournalEntry | None]:
    period_stmt = select(AccountingPeriod).where(
        AccountingPeriod.id == period_id, AccountingPeriod.company_id == company_id
    )
    period = (await db.execute(period_stmt)).scalar_one_or_none()
    if period is None:
        raise NotFoundError("Période comptable introuvable.")
    if period.status != PeriodStatus.OPEN:
        raise AccountingIntegrityError("Cette période est déjà clôturée.")

    equity_stmt = select(Account).where(
        Account.id == result_equity_account_id, Account.company_id == company_id
    )
    equity_account = (await db.execute(equity_stmt)).scalar_one_or_none()
    if equity_account is None:
        raise NotFoundError("Compte de capitaux propres introuvable.")
    if equity_account.type != AccountType.EQUITY:
        raise AccountingIntegrityError(
            "Le compte désigné pour recevoir le résultat doit être de type EQUITY."
        )

    journal_stmt = select(Journal).where(
        Journal.company_id == company_id, Journal.type == JournalType.MISC
    )
    journal = (await db.execute(journal_stmt)).scalar_one_or_none()
    if journal is None:
        raise NotFoundError(
            "Aucun journal de type MISC (opérations diverses) trouvé — "
            "il en faut un pour poser l'écriture de clôture."
        )

    balance_rows = await get_trial_balance(db, company_id)
    accounts_stmt = select(Account).where(Account.company_id == company_id)
    accounts = {a.id: a for a in (await db.execute(accounts_stmt)).scalars().all()}

    lines: list[JournalEntryLine] = []
    net_result = Decimal("0")

    for row in balance_rows:
        account = accounts.get(row["account_id"])
        if account is None:
            continue

        if account.type == AccountType.REVENUE:
            credit_balance = row["total_credit"] - row["total_debit"]
            if credit_balance == 0:
                continue
            net_result += credit_balance
            lines.append(JournalEntryLine(
                account_id=account.id,
                label=f"Solde de clôture - {account.name}",
                debit=credit_balance, credit=Decimal("0"),
            ))
            lines.append(JournalEntryLine(
                account_id=equity_account.id,
                label=f"Report résultat - {account.name}",
                debit=Decimal("0"), credit=credit_balance,
            ))

        elif account.type == AccountType.EXPENSE:
            debit_balance = row["total_debit"] - row["total_credit"]
            if debit_balance == 0:
                continue
            net_result -= debit_balance
            lines.append(JournalEntryLine(
                account_id=account.id,
                label=f"Solde de clôture - {account.name}",
                debit=Decimal("0"), credit=debit_balance,
            ))
            lines.append(JournalEntryLine(
                account_id=equity_account.id,
                label=f"Report résultat - {account.name}",
                debit=debit_balance, credit=Decimal("0"),
            ))

    if not lines:
        # Aucun mouvement de produits/charges sur la période : on clôture
        # simplement la période sans écriture (résultat nul).
        period.status = PeriodStatus.CLOSED
        await db.flush()
        return period, None

    entry = JournalEntry(
        company_id=company_id,
        journal_id=journal.id,
        period_id=period.id,
        entry_date=period.end_date,
        label=f"Clôture de l'exercice {period.year}",
        created_by=closed_by,
    )
    entry.lines = lines
    db.add(entry)
    await db.flush()

    entry = await validate_entry(db, entry, validated_by=closed_by)

    period.status = PeriodStatus.CLOSED
    await db.flush()

    return period, entry
