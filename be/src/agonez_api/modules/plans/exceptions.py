class PlanError(Exception):
    """Base class for expected PlanCreator failures."""


class PlanNotFoundError(PlanError):
    def __init__(self, plan_id: int) -> None:
        self.plan_id = plan_id
        super().__init__(f"Plan {plan_id} was not found")


class PlanDraftNotFoundError(PlanError):
    def __init__(self, plan_id: int) -> None:
        self.plan_id = plan_id
        super().__init__(f"Plan {plan_id} has no draft revision")


class PlanImageNotFoundError(PlanError):
    def __init__(self, plan_id: int) -> None:
        self.plan_id = plan_id
        super().__init__(f"Plan {plan_id} has no cover image")


class PlanConflictError(PlanError):
    def __init__(self, *, submitted_lock_version: int, current_lock_version: int) -> None:
        self.submitted_lock_version = submitted_lock_version
        self.current_lock_version = current_lock_version
        super().__init__(
            "Draft was changed after it was loaded "
            f"(submitted version {submitted_lock_version}, current version {current_lock_version})"
        )


class PlanDomainValidationError(PlanError):
    def __init__(self, detail: str) -> None:
        self.detail = detail
        super().__init__(detail)


class PlanRevisionNotFoundError(PlanError):
    def __init__(self, revision_id: int) -> None:
        self.revision_id = revision_id
        super().__init__(f"Plan revision {revision_id} was not found")


class PlanScopeError(PlanError):
    """A library-only operation was requested for a run plan."""

    def __init__(self, detail: str) -> None:
        self.detail = detail
        super().__init__(detail)


class PlanInUseError(PlanError):
    """The plan's rows are still referenced by a plan run (RESTRICT foreign keys)."""

    def __init__(self, plan_id: int) -> None:
        self.plan_id = plan_id
        super().__init__(f"Plan {plan_id} is still used by a plan run")
