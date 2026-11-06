"""Tests unitaires du moteur comptable, sur SQLite en mémoire (rapide,
sans dépendance à PostgreSQL) — voir conftest.py."""
from datetime import date
from decimal import Decimal

import pytest

from app.accounting.engine import post_transaction, reverse_entry, validate_entry
from app.core.exceptions import AccountingIntegrityError
from app.models.accounting_rule import AccountingRule
from app.models.journal_entry import EntryStatus, JournalEntry
from app.models.journal_entry_line import JournalEntryLine
from app.models.transaction import PaymentMethod, Transaction, TransactionStatus, TransactionType


@pytest.mark.asyncio
async def test_post_transaction_creates_balanced_validated_entry(db_session, company_setup):
    company = company_setup["company"]
    user = company_setup["user"]
    journal = company_setup["journal"]
    expense_account = company_setup["expense_account"]
    bank_account = company_setup["bank_account"]

    rule = AccountingRule(
        company_id=company.id, transaction_type=TransactionType.EXPENSE,
        payment_method=PaymentMethod.BANK, journal_id=journal.id,
        debit_account_id=expense_account.id, credit_account_id=bank_account.id,
    )
    db_session.add(rule)
    await db_session.flush()

    transaction = Transaction(
        company_id=company.id, type=TransactionType.EXPENSE,
        transaction_date=date.today(), amount=Decimal("50000"),
        description="Achat fournitures", payment_method=PaymentMethod.BANK,
        created_by=user.id,
    )
    db_session.add(transaction)
    await db_session.flush()

    entry = await post_transaction(db_session, transaction, posted_by=user.id)

    assert entry.status == EntryStatus.VALIDATED
    assert entry.number is not None
    assert transaction.status == TransactionStatus.POSTED
    assert len(entry.lines) == 2
    total_debit = sum(l.debit for l in entry.lines)
    total_credit = sum(l.credit for l in entry.lines)
    assert total_debit == total_credit == Decimal("50000")


@pytest.mark.asyncio
async def test_unbalanced_entry_is_rejected(db_session, company_setup):
    company = company_setup["company"]
    user = company_setup["user"]
    journal = company_setup["journal"]
    period = company_setup["period"]
    expense_account = company_setup["expense_account"]
    bank_account = company_setup["bank_account"]

    entry = JournalEntry(
        company_id=company.id, journal_id=journal.id, period_id=period.id,
        entry_date=date.today(), label="Écriture déséquilibrée", created_by=user.id,
    )
    entry.lines.append(JournalEntryLine(
        account_id=expense_account.id, label="Débit", debit=Decimal("100"), credit=Decimal("0"),
    ))
    entry.lines.append(JournalEntryLine(
        account_id=bank_account.id, label="Crédit", debit=Decimal("0"), credit=Decimal("90"),
    ))
    db_session.add(entry)
    await db_session.flush()

    with pytest.raises(AccountingIntegrityError):
        await validate_entry(db_session, entry, validated_by=user.id)


@pytest.mark.asyncio
async def test_validated_entry_numbers_are_sequential_per_journal(db_session, company_setup):
    company = company_setup["company"]
    user = company_setup["user"]
    journal = company_setup["journal"]
    period = company_setup["period"]
    expense_account = company_setup["expense_account"]
    bank_account = company_setup["bank_account"]

    numbers = []
    for i in range(3):
        entry = JournalEntry(
            company_id=company.id, journal_id=journal.id, period_id=period.id,
            entry_date=date.today(), label=f"Écriture {i}", created_by=user.id,
        )
        entry.lines.append(JournalEntryLine(
            account_id=expense_account.id, label="Débit", debit=Decimal("10"), credit=Decimal("0"),
        ))
        entry.lines.append(JournalEntryLine(
            account_id=bank_account.id, label="Crédit", debit=Decimal("0"), credit=Decimal("10"),
        ))
        db_session.add(entry)
        await db_session.flush()
        entry = await validate_entry(db_session, entry, validated_by=user.id)
        numbers.append(entry.number)

    year = date.today().year
    assert numbers == [f"{year}-OD-000001", f"{year}-OD-000002", f"{year}-OD-000003"]


@pytest.mark.asyncio
async def test_reverse_entry_creates_inverted_validated_entry(db_session, company_setup):
    company = company_setup["company"]
    user = company_setup["user"]
    journal = company_setup["journal"]
    period = company_setup["period"]
    expense_account = company_setup["expense_account"]
    bank_account = company_setup["bank_account"]

    entry = JournalEntry(
        company_id=company.id, journal_id=journal.id, period_id=period.id,
        entry_date=date.today(), label="Écriture initiale", created_by=user.id,
    )
    entry.lines.append(JournalEntryLine(
        account_id=expense_account.id, label="Débit", debit=Decimal("500"), credit=Decimal("0"),
    ))
    entry.lines.append(JournalEntryLine(
        account_id=bank_account.id, label="Crédit", debit=Decimal("0"), credit=Decimal("500"),
    ))
    db_session.add(entry)
    await db_session.flush()
    entry = await validate_entry(db_session, entry, validated_by=user.id)

    reversal = await reverse_entry(db_session, entry, created_by=user.id)

    assert entry.status == EntryStatus.REVERSED
    assert reversal.status == EntryStatus.VALIDATED
    reversal_debit = sum(l.debit for l in reversal.lines)
    reversal_credit = sum(l.credit for l in reversal.lines)
    assert reversal_debit == reversal_credit == Decimal("500")
    # Le compte débité dans l'original doit être crédité dans la contrepassation
    original_debit_account = next(l.account_id for l in entry.lines if l.debit > 0)
    reversal_credit_line = next(l for l in reversal.lines if l.account_id == original_debit_account)
    assert reversal_credit_line.credit == Decimal("500")
