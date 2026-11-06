class AppError(Exception):
    """Erreur métier de base, convertie en réponse API uniforme."""
    status_code: int = 400
    code: str = "APP_ERROR"

    def __init__(self, message: str, details: dict | None = None):
        self.message = message
        self.details = details or {}
        super().__init__(message)


class NotFoundError(AppError):
    status_code = 404
    code = "NOT_FOUND"


class ValidationAppError(AppError):
    status_code = 422
    code = "VALIDATION_ERROR"


class PermissionDeniedError(AppError):
    status_code = 403
    code = "PERMISSION_DENIED"


class AuthenticationError(AppError):
    status_code = 401
    code = "AUTHENTICATION_ERROR"


class AccountingIntegrityError(AppError):
    status_code = 409
    code = "ACCOUNTING_INTEGRITY_ERROR"


class PeriodClosedError(AppError):
    status_code = 409
    code = "PERIOD_CLOSED"
