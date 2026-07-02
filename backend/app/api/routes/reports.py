from fastapi import APIRouter, Request, status

from app.core.config import settings
from app.core.deps import CurrentUser, DbDep
from app.core.rate_limit import limiter
from app.schemas.report import ReportCreate, ReportOut
from app.services.moderation import create_report

router = APIRouter(prefix="/reports", tags=["reports"])


@router.post("", response_model=ReportOut, status_code=status.HTTP_201_CREATED)
@limiter.limit(settings.rate_limit_auth)
async def submit_report(
    request: Request, payload: ReportCreate, user: CurrentUser, db: DbDep
) -> ReportOut:
    report = await create_report(
        db,
        user,
        listing_id=payload.listing_id,
        reported_user_id=payload.reported_user_id,
        reason=payload.reason,
        details=payload.details,
    )
    return ReportOut.model_validate(report)
