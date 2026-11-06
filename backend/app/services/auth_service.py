from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AuthenticationError, ValidationAppError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.company import Company
from app.models.user import User, UserRole
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse


async def register(db: AsyncSession, payload: RegisterRequest) -> User:
    existing = await db.execute(select(User).where(User.email == payload.email))
    if existing.scalar_one_or_none() is not None:
        raise ValidationAppError("Un utilisateur avec cet email existe déjà.")

    company = Company(name=payload.company_name)
    db.add(company)
    await db.flush()

    user = User(
        company_id=company.id,
        email=payload.email,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
        role=UserRole.ADMIN,  # le premier utilisateur d'une entreprise est admin
    )
    db.add(user)
    await db.flush()
    return user


async def login(db: AsyncSession, payload: LoginRequest) -> TokenResponse:
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()

    if user is None or not verify_password(payload.password, user.hashed_password):
        raise AuthenticationError("Email ou mot de passe incorrect.")
    if not user.is_active:
        raise AuthenticationError("Ce compte est désactivé.")

    return TokenResponse(
        access_token=create_access_token(user.id, user.company_id),
        refresh_token=create_refresh_token(user.id, user.company_id),
    )


async def refresh(db: AsyncSession, refresh_token: str) -> TokenResponse:
    try:
        payload = decode_token(refresh_token)
    except ValueError as exc:
        raise AuthenticationError(str(exc)) from exc

    if payload.get("type") != "refresh":
        raise AuthenticationError("Ce token n'est pas un refresh token.")

    from uuid import UUID
    result = await db.execute(select(User).where(User.id == UUID(payload["sub"])))
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        raise AuthenticationError("Utilisateur introuvable ou inactif.")

    return TokenResponse(
        access_token=create_access_token(user.id, user.company_id),
        refresh_token=create_refresh_token(user.id, user.company_id),
    )
