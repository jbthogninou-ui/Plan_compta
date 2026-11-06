from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.accounting.closing import close_period
from app.models.user import User
from app.schemas.accounting_period import ClosePeriodResponse
from app.services.audit_service import log_action


async def close_period_and_log(
    db: AsyncSession, period_id: UUID, result_equity_account_id: UUID, user: User
) -> ClosePeriodResponse:
    period, entry = await close_period(
        db, user.company_id, period_id, result_equity_account_id, closed_by=user.id
    )

    await log_action(
        db, user.company_id, user.id,
        action="period.close", entity_type="accounting_period", entity_id=str(period.id),
        new_values={
            "year": period.year,
            "closing_entry_number": entry.number if entry else None,
        },
    )
    await db.commit()
    await db.refresh(period)

    return ClosePeriodResponse(
        period=period,
        closing_entry_number=entry.number if entry else None,
        net_result="voir /reports/income-statement pour le détail de l'exercice clôturé" if entry else "0",
    )
