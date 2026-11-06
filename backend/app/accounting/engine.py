"""Accounting Engine — le cœur du logiciel.

Toute écriture comptable passe par ici, que son origine soit :
  - automatique : Transaction -> AccountingRule -> JournalEntry
  - manuelle : saisie directe dans le journal OD

Les DEUX chemins repassent par validate_entry(), qui applique exactement
les mêmes contrôles. Aucune écriture ne devient VALIDATED sans être
passée par cette fonction.
"""
from datetime import date, datetime, timezone
from decimal import Decimal
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AccountingIntegrityError, NotFoundError, PeriodClosedError
from app.models.account import Account
from app.models.accounting_period import AccountingPeriod, PeriodStatus
from app.models.accounting_rule import AccountingRule
from app.models.journal import Journal
from app.models.journal_entry import EntryStatus, JournalEntry
from app.models.journal_entry_line import JournalEntryLine
from app.models.transaction import Transaction, TransactionStatus
from app.services.numbering_service import get_next_entry_number


async def _get_open_period(db: AsyncSession, company_id: UUID, entry_date: date) -> AccountingPeriod:
    stmt = select(AccountingPeriod).where(
        AccountingPeriod.company_id == company_id,
        AccountingPeriod.year == entry_date.year,
    )
    result = await db.execute(stmt)
    period = result.scalar_one_or_none()
    if period is None:
        raise NotFoundError(f"Aucune période comptable ouverte pour l'année {entry_date.year}.")
    if period.status != PeriodStatus.OPEN:
        raise PeriodClosedError(f"La période comptable {entry_date.year} est clôturée.")
    return period


def _validate_double_entry(lines: list[JournalEntryLine]) -> None:
    total_debit = sum((line.debit for line in lines), Decimal("0"))
    total_credit = sum((line.credit for line in lines), Decimal("0"))

    if total_debit != total_credit:
        raise AccountingIntegrityError(
            "Le total des débits ne correspond pas au total des crédits.",
            details={"total_debit": str(total_debit), "total_credit": str(total_credit)},
        )
    if total_debit == 0:
        raise AccountingIntegrityError("Une écriture ne peut pas avoir un montant total nul.")
    for line in lines:
        if line.debit > 0 and line.credit > 0:
            raise AccountingIntegrityError(
                "Une ligne d'écriture ne peut pas être à la fois débitrice et créditrice."
            )
        if line.debit == 0 and line.credit == 0:
            raise AccountingIntegrityError("Une ligne d'écriture doit avoir un montant non nul.")


async def _validate_accounts_active(db: AsyncSession, lines: list[JournalEntryLine]) -> None:
    account_ids = {line.account_id for line in lines}
    stmt = select(Account).where(Account.id.in_(account_ids))
    result = await db.execute(stmt)
    accounts = {a.id: a for a in result.scalars().all()}

    for account_id in account_ids:
        account = accounts.get(account_id)
        if account is None:
            raise NotFoundError(f"Compte {account_id} introuvable.")
        if not account.is_active:
            raise AccountingIntegrityError(f"Le compte '{account.code}' est inactif.")


async def validate_entry(
    db: AsyncSession, entry: JournalEntry, validated_by: UUID
) -> JournalEntry:
    """Applique tous les contrôles obligatoires et fait passer une écriture
    (automatique ou manuelle) de DRAFT à VALIDATED. Assigne le numéro
    définitif. Après cet appel, l'écriture est immuable."""
    if entry.status != EntryStatus.DRAFT:
        raise AccountingIntegrityError("Seule une écriture en brouillon peut être validée.")

    _validate_double_entry(entry.lines)
    await _validate_accounts_active(db, entry.lines)

    period = await _get_open_period(db, entry.company_id, entry.entry_date)
    if period.id != entry.period_id:
        entry.period_id = period.id

    journal_stmt = select(Journal).where(Journal.id == entry.journal_id)
    journal = (await db.execute(journal_stmt)).scalar_one()

    entry.number = await get_next_entry_number(
        db, entry.company_id, entry.journal_id, journal.code, entry.entry_date.year
    )
    entry.status = EntryStatus.VALIDATED
    entry.validated_by = validated_by
    entry.validated_at = datetime.now(timezone.utc)

    await db.flush()
    return entry


async def reverse_entry(db: AsyncSession, entry: JournalEntry, created_by: UUID) -> JournalEntry:
    """Contrepassation : crée une nouvelle écriture avec débits/crédits
    inversés, la valide immédiatement, et marque l'originale REVERSED.
    L'écriture originale n'est jamais modifiée ni supprimée."""
    if entry.status != EntryStatus.VALIDATED:
        raise AccountingIntegrityError("Seule une écriture validée peut être contrepassée.")

    reversal = JournalEntry(
        company_id=entry.company_id,
        journal_id=entry.journal_id,
        period_id=entry.period_id,
        entry_date=date.today(),
        label=f"Contrepassation de {entry.number}",
        created_by=created_by,
    )
    for line in entry.lines:
        reversal.lines.append(
            JournalEntryLine(
                account_id=line.account_id,
                label=f"Contrepassation: {line.label}",
                debit=line.credit,
                credit=line.debit,
                party_type=line.party_type,
                party_id=line.party_id,
            )
        )
    db.add(reversal)
    await db.flush()

    reversal = await validate_entry(db, reversal, validated_by=created_by)

    entry.status = EntryStatus.REVERSED
    entry.reversed_entry_id = reversal.id
    await db.flush()

    return reversal


async def _find_rule(
    db: AsyncSession, transaction: Transaction
) -> AccountingRule:
    stmt = select(AccountingRule).where(
        AccountingRule.company_id == transaction.company_id,
        AccountingRule.transaction_type == transaction.type,
    )
    result = await db.execute(stmt)
    rules = result.scalars().all()

    if not rules:
        raise NotFoundError(
            f"Aucune règle comptable configurée pour le type de transaction "
            f"'{transaction.type.value}'."
        )

    # Priorité à une règle spécifique au moyen de paiement, sinon règle générique
    specific = [r for r in rules if r.payment_method == transaction.payment_method]
    if specific:
        return specific[0]
    generic = [r for r in rules if r.payment_method is None]
    if generic:
        return generic[0]

    raise NotFoundError(
        f"Aucune règle comptable ne correspond au moyen de paiement "
        f"'{transaction.payment_method}' pour ce type de transaction."
    )


async def post_transaction(
    db: AsyncSession, transaction: Transaction, posted_by: UUID
) -> JournalEntry:
    """Traduit une Transaction métier en écriture comptable validée, en
    appliquant la règle configurée pour son (type, moyen de paiement)."""
    if transaction.status != TransactionStatus.PENDING:
        raise AccountingIntegrityError("Cette transaction a déjà été traitée.")

    rule = await _find_rule(db, transaction)
    period = await _get_open_period(db, transaction.company_id, transaction.transaction_date)

    entry = JournalEntry(
        company_id=transaction.company_id,
        journal_id=rule.journal_id,
        period_id=period.id,
        entry_date=transaction.transaction_date,
        label=transaction.description,
        transaction_id=transaction.id,
        created_by=posted_by,
    )
    entry.lines.append(
        JournalEntryLine(
            account_id=rule.debit_account_id,
            label=transaction.description,
            debit=transaction.amount,
            credit=Decimal("0"),
        )
    )
    entry.lines.append(
        JournalEntryLine(
            account_id=rule.credit_account_id,
            label=transaction.description,
            debit=Decimal("0"),
            credit=transaction.amount,
        )
    )
    db.add(entry)
    await db.flush()

    entry = await validate_entry(db, entry, validated_by=posted_by)

    transaction.status = TransactionStatus.POSTED
    await db.flush()

    return entry
