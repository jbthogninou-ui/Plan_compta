import os
import uuid
from datetime import date
from decimal import Decimal

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://test:test@localhost:5432/test")
os.environ.setdefault("SECRET_KEY", "test-secret")

from app.database import Base  # noqa: E402
from app.models.account import Account, AccountType, NormalBalance  # noqa: E402
from app.models.accounting_period import AccountingPeriod, PeriodStatus  # noqa: E402
from app.models.company import Company  # noqa: E402
from app.models.journal import Journal, JournalType  # noqa: E402
from app.models.user import User, UserRole  # noqa: E402
from app.core.security import hash_password  # noqa: E402

# Tests exécutés sur SQLite en mémoire (aiosqlite) pour valider la logique
# du moteur comptable sans dépendre d'un vrai serveur PostgreSQL.
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest_asyncio.fixture
async def db_session():
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with session_factory() as session:
        yield session

    await engine.dispose()


@pytest_asyncio.fixture
async def company_setup(db_session: AsyncSession):
    """Crée une entreprise, un utilisateur admin, un journal OD, une période
    ouverte, et deux comptes (charge / banque) prêts pour les tests du
    moteur comptable."""
    company = Company(name="Test SARL")
    db_session.add(company)
    await db_session.flush()

    user = User(
        company_id=company.id, email="admin@test.com",
        hashed_password=hash_password("secret123"), full_name="Admin Test",
        role=UserRole.ADMIN,
    )
    db_session.add(user)

    journal = Journal(company_id=company.id, code="OD", name="Opérations diverses", type=JournalType.MISC)
    db_session.add(journal)

    period = AccountingPeriod(
        company_id=company.id, year=date.today().year,
        start_date=date(date.today().year, 1, 1), end_date=date(date.today().year, 12, 31),
        status=PeriodStatus.OPEN,
    )
    db_session.add(period)

    expense_account = Account(
        company_id=company.id, code="6", name="Charges", type=AccountType.EXPENSE,
        normal_balance=NormalBalance.DEBIT,
    )
    bank_account = Account(
        company_id=company.id, code="512", name="Banque", type=AccountType.ASSET,
        normal_balance=NormalBalance.DEBIT,
    )
    db_session.add_all([expense_account, bank_account])
    await db_session.flush()

    return {
        "company": company, "user": user, "journal": journal, "period": period,
        "expense_account": expense_account, "bank_account": bank_account,
    }
