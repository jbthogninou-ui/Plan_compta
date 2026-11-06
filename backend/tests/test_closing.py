from datetime import date
from decimal import Decimal

import pytest

from app.accounting.closing import close_period
from app.accounting.engine import post_transaction
from app.core.exceptions import AccountingIntegrityError
from app.models.account import Account, AccountType, NormalBalance
from app.models.accounting_period import PeriodStatus
from app.models.accounting_rule import AccountingRule
from app.models.transaction import PaymentMethod, Transaction, TransactionType


@pytest.mark.asyncio
async def test_close_period_zeroes_revenue_and_expense_and_posts_result(db_session, company_setup):
    company = company_setup["company"]
    user = company_setup["user"]
    journal = company_setup["journal"]
    period = company_setup["period"]
    expense_account = company_setup["expense_account"]
    bank_account = company_setup["bank_account"]

    revenue_account = Account(
        company_id=company.id, code="7", name="Ventes", type=AccountType.REVENUE,
        normal_balance=NormalBalance.CREDIT,
    )
    equity_account = Account(
        company_id=company.id, code="12", name="Résultat de l'exercice", type=AccountType.EQUITY,
        normal_balance=NormalBalance.CREDIT,
    )
    db_session.add_all([revenue_account, equity_account])
    await db_session.flush()

    # Une charge de 300 et un produit de 1000 -> résultat net attendu = 700
    expense_rule = AccountingRule(
        company_id=company.id, transaction_type=TransactionType.EXPENSE,
        payment_method=PaymentMethod.BANK, journal_id=journal.id,
        debit_account_id=expense_account.id, credit_account_id=bank_account.id,
    )
    income_rule = AccountingRule(
        company_id=company.id, transaction_type=TransactionType.INCOME,
        payment_method=PaymentMethod.BANK, journal_id=journal.id,
        debit_account_id=bank_account.id, credit_account_id=revenue_account.id,
    )
    db_session.add_all([expense_rule, income_rule])
    await db_session.flush()

    expense_tx = Transaction(
        company_id=company.id, type=TransactionType.EXPENSE, transaction_date=date.today(),
        amount=Decimal("300"), description="Charge test", payment_method=PaymentMethod.BANK,
        created_by=user.id,
    )
    income_tx = Transaction(
        company_id=company.id, type=TransactionType.INCOME, transaction_date=date.today(),
        amount=Decimal("1000"), description="Produit test", payment_method=PaymentMethod.BANK,
        created_by=user.id,
    )
    db_session.add_all([expense_tx, income_tx])
    await db_session.flush()

    await post_transaction(db_session, expense_tx, posted_by=user.id)
    await post_transaction(db_session, income_tx, posted_by=user.id)

    closed_period, closing_entry = await close_period(
        db_session, company.id, period.id, equity_account.id, closed_by=user.id
    )

    assert closed_period.status == PeriodStatus.CLOSED
    assert closing_entry is not None
    assert closing_entry.number is not None

    total_debit = sum(l.debit for l in closing_entry.lines)
    total_credit = sum(l.credit for l in closing_entry.lines)
    assert total_debit == total_credit  # partie double respectée sur l'écriture de clôture

    # Le compte de résultat doit avoir reçu net 700 de crédit (1000 produit - 300 charge)
    equity_lines = [l for l in closing_entry.lines if l.account_id == equity_account.id]
    net_on_equity = sum(l.credit for l in equity_lines) - sum(l.debit for l in equity_lines)
    assert net_on_equity == Decimal("700")


@pytest.mark.asyncio
async def test_closed_period_cannot_be_closed_twice(db_session, company_setup):
    company = company_setup["company"]
    user = company_setup["user"]
    period = company_setup["period"]

    equity_account = Account(
        company_id=company.id, code="12", name="Résultat", type=AccountType.EQUITY,
        normal_balance=NormalBalance.CREDIT,
    )
    db_session.add(equity_account)
    await db_session.flush()

    await close_period(db_session, company.id, period.id, equity_account.id, closed_by=user.id)

    with pytest.raises(AccountingIntegrityError):
        await close_period(db_session, company.id, period.id, equity_account.id, closed_by=user.id)


@pytest.mark.asyncio
async def test_posting_transaction_on_closed_period_is_rejected(db_session, company_setup):
    company = company_setup["company"]
    user = company_setup["user"]
    journal = company_setup["journal"]
    period = company_setup["period"]
    expense_account = company_setup["expense_account"]
    bank_account = company_setup["bank_account"]

    equity_account = Account(
        company_id=company.id, code="12", name="Résultat", type=AccountType.EQUITY,
        normal_balance=NormalBalance.CREDIT,
    )
    db_session.add(equity_account)
    await db_session.flush()

    await close_period(db_session, company.id, period.id, equity_account.id, closed_by=user.id)

    rule = AccountingRule(
        company_id=company.id, transaction_type=TransactionType.EXPENSE,
        payment_method=PaymentMethod.BANK, journal_id=journal.id,
        debit_account_id=expense_account.id, credit_account_id=bank_account.id,
    )
    db_session.add(rule)
    await db_session.flush()

    late_tx = Transaction(
        company_id=company.id, type=TransactionType.EXPENSE, transaction_date=date.today(),
        amount=Decimal("50"), description="Trop tard", payment_method=PaymentMethod.BANK,
        created_by=user.id,
    )
    db_session.add(late_tx)
    await db_session.flush()

    from app.core.exceptions import PeriodClosedError
    with pytest.raises(PeriodClosedError):
        await post_transaction(db_session, late_tx, posted_by=user.id)
