from typing import Any


class ExecutionAPIError(Exception):
    """Expected Execution failure with a stable public error code."""

    def __init__(
        self,
        status_code: int,
        code: str,
        message: str,
        details: dict[str, Any] | None = None,
    ) -> None:
        self.status_code = status_code
        self.code = code
        self.message = message
        self.details = details or {}
        super().__init__(message)


def not_found(code: str, message: str) -> ExecutionAPIError:
    return ExecutionAPIError(404, code, message)


def conflict(
    code: str,
    message: str,
    details: dict[str, Any] | None = None,
) -> ExecutionAPIError:
    return ExecutionAPIError(409, code, message, details)


def invalid(
    code: str,
    message: str,
    details: dict[str, Any] | None = None,
) -> ExecutionAPIError:
    return ExecutionAPIError(422, code, message, details)
