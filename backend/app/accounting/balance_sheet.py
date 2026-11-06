"""Bilan : Actif = Passif + Capitaux propres (+ résultat de l'exercice).

Le résultat de l'exercice n'est PAS stocké dans un compte de capitaux
propres avant la clôture : il est calculé dynamiquement depuis le compte
de résultat et ajouté aux capitaux propres pour que le bilan s'équilibre
à tout moment de l'exercice, pas seulement après clôture."""
from decimal import Decimal
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.accounting.income_statement import get_income_statement
from app.accounting.trial_balance import get_trial_balance
from app.models.account import Account, AccountType


async def get_balance_sheet(db: AsyncSession, company_id: UUID) -> dict:
    balance_rows = await get_trial_balance(db, company_id)
    accounts_stmt = select(Account).where(Account.company_id == company_id)
    accounts = {a.id: a for a in (await db.execute(accounts_stmt)).scalars().all()}

    assets, liabilities, equity = [], [], []
    total_assets = total_liabilities = total_equity = Decimal("0")

    for row in balance_rows:
        account = accounts.get(row["account_id"])
        if account is None:
            continue
        if account.type == AccountType.ASSET:
            amount = row["total_debit"] - row["total_credit"]
            total_assets += amount
            assets.append({"code": row["code"], "name": row["name"], "amount": amount})
        elif account.type == AccountType.LIABILITY:
            amount = row["total_credit"] - row["total_debit"]
            total_liabilities += amount
            liabilities.append({"code": row["code"], "name": row["name"], "amount": amount})
        elif account.type == AccountType.EQUITY:
            amount = row["total_credit"] - row["total_debit"]
            total_equity += amount
            equity.append({"code": row["code"], "name": row["name"], "amount": amount})

    income_statement = await get_income_statement(db, company_id)
    net_result = income_statement["net_result"]
    total_equity_with_result = total_equity + net_result

    return {
        "assets": assets,
        "total_assets": total_assets,
        "liabilities": liabilities,
        "total_liabilities": total_liabilities,
        "equity": equity,
        "total_equity": total_equity,
        "net_result_of_period": net_result,
        "total_equity_and_result": total_equity_with_result,
        "total_liabilities_and_equity": total_liabilities + total_equity_with_result,
        "is_balanced": total_assets == (total_liabilities + total_equity_with_result),
    }
