from typing import Annotated, cast

from fastapi import APIRouter, Header, Request, status

from agonez_api.core.localization import negotiate_content_locale
from agonez_api.modules.waitlist.schemas import (
    WaitlistSubmission,
    WaitlistSubmissionResponse,
)
from agonez_api.modules.waitlist.store import WaitlistStore

router = APIRouter(prefix="/api/waitlist", tags=["Waitlist"])


@router.post(
    "",
    response_model=WaitlistSubmissionResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
async def join_waitlist(
    payload: WaitlistSubmission,
    request: Request,
    accept_language: Annotated[str | None, Header(alias="Accept-Language")] = None,
) -> WaitlistSubmissionResponse:
    # Return the same response for honeypot and duplicate submissions so the
    # endpoint does not reveal which addresses are already present.
    if not payload.website:
        store = cast(WaitlistStore, request.app.state.waitlist_store)
        store.add(
            email=payload.email,
            locale=negotiate_content_locale(accept_language),
        )
    return WaitlistSubmissionResponse()
