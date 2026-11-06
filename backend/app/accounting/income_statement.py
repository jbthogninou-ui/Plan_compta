"""Compte de résultat : Produits - Charges = Résultat de l'exercice."""
from decimal import Decimal
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from sqlalchemy import select

from app.accounting.trial_balance import get_trial_balance
from app.models.account import Account, AccountType


async def get_income_statement(db: AsyncSession, company_id: UUID) -> dict:
    balance_rows = await get_trial_balance(db, company_id)
    accounts_stmt = select(Account).where(Account.company_id == company_id)
    accounts = {a.id: a for a in (await db.execute(accounts_stmt)).scalars().all()}

    total_revenue = Decimal("0")
    total_expense = Decimal("0")
    revenue_lines = []
    expense_lines = []

    for row in balance_rows:
        account = accounts.get(row["account_id"])
        if account is None:
            continue
        if account.type == AccountType.REVENUE:
            amount = row["total_credit"] - row["total_debit"]
            total_revenue += amount
            revenue_lines.append({"code": row["code"], "name": row["name"], "amount": amount})
        elif account.type == AccountType.EXPENSE:
            amount = row["total_debit"] - row["total_credit"]
            total_expense += amount
            expense_lines.append({"code": row["code"], "name": row["name"], "amount": amount})

    return {
        "revenue": revenue_lines,
        "expense": expense_lines,
        "total_revenue": total_revenue,
        "total_expense": total_expense,
        "net_result": total_revenue - total_expense,
    }
