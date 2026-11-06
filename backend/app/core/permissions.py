from app.core.exceptions import PermissionDeniedError
from app.models.user import User, UserRole

CAN_POST_ROLES = {UserRole.ADMIN, UserRole.ACCOUNTANT}
CAN_MANAGE_SETUP_ROLES = {UserRole.ADMIN}


def require_role(user: User, allowed_roles: set[UserRole]) -> None:
    if user.role not in allowed_roles:
        raise PermissionDeniedError(
            f"Le rôle '{user.role.value}' n'est pas autorisé à effectuer cette action."
        )
