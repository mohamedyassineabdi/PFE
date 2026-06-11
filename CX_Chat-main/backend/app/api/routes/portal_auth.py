from datetime import timedelta

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.db.models.user import User
from app.dependencies.db import get_db
from app.schemas.portal_auth import (
    AuthResponse,
    InviteUserRequest,
    InviteUserResponse,
    LoginRequest,
    MessageResponse,
    PortalUser,
    SetPasswordRequest,
    UserListResponse,
    UserStatusRequest,
)
from app.services.portal_auth import (
    INVITE_TTL_DAYS,
    build_invite_link,
    create_invite_token,
    create_session_token,
    decode_session_token,
    hash_password,
    normalize_email,
    send_invite_email,
    token_hash,
    utcnow,
    verify_password,
)

router = APIRouter(prefix="/auth")


def to_portal_user(user: User) -> PortalUser:
    return PortalUser(
        id=user.id,
        email=user.email,
        role=user.role,
        is_active=user.is_active,
        latest_login_at=user.latest_login_at,
        invite_sent_at=user.invite_sent_at,
        invite_accepted_at=user.invite_accepted_at,
        created_at=user.created_at,
    )


async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    result = await db.execute(select(User).where(func.lower(User.email) == normalize_email(email)))
    return result.scalar_one_or_none()


async def current_user(
    authorization: str | None = Header(default=None),
    db: AsyncSession = Depends(get_db),
) -> User:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_session_token(token, get_settings())
    if not payload:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    user = await db.get(User, int(payload["sub"]))
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Inactive or unknown user")
    return user


async def current_admin(user: User = Depends(current_user)) -> User:
    if user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin role required")
    return user


@router.post("/login", response_model=AuthResponse)
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)) -> AuthResponse:
    user = await get_user_by_email(db, str(payload.email))
    if not user or not user.is_active or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

    user.latest_login_at = utcnow()
    await db.commit()
    await db.refresh(user)
    return AuthResponse(token=create_session_token(user, get_settings()), user=to_portal_user(user))


@router.get("/me", response_model=PortalUser)
async def me(user: User = Depends(current_user)) -> PortalUser:
    return to_portal_user(user)


@router.post("/set-password", response_model=MessageResponse)
async def set_password(payload: SetPasswordRequest, db: AsyncSession = Depends(get_db)) -> MessageResponse:
    result = await db.execute(select(User).where(User.invite_token_hash == token_hash(payload.token)))
    user = result.scalar_one_or_none()
    now = utcnow()
    if not user or not user.invite_expires_at or user.invite_expires_at < now or user.invite_accepted_at is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired invitation link")

    user.password_hash = hash_password(payload.password)
    user.invite_token_hash = None
    user.invite_accepted_at = now
    user.password_updated_at = now
    user.is_active = True
    user.deactivated_at = None
    await db.commit()
    return MessageResponse(message="Password set successfully")


@router.get("/admin/users", response_model=UserListResponse)
async def list_users(
    _admin: User = Depends(current_admin),
    db: AsyncSession = Depends(get_db),
) -> UserListResponse:
    result = await db.execute(select(User).order_by(User.created_at.desc()))
    return UserListResponse(items=[to_portal_user(user) for user in result.scalars().all()])


@router.post("/admin/users/invite", response_model=InviteUserResponse)
async def invite_user(
    payload: InviteUserRequest,
    admin: User = Depends(current_admin),
    db: AsyncSession = Depends(get_db),
) -> InviteUserResponse:
    email = normalize_email(str(payload.email))
    user = await get_user_by_email(db, email)
    if user and user.password_hash and user.invite_accepted_at:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="This user already has an account")
    if user and user.role == "admin":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="The admin account cannot be invited")

    invite_token = create_invite_token()
    now = utcnow()
    if not user:
        user = User(email=email, role="user", is_active=True, invited_by_user_id=admin.id)
        db.add(user)
    user.invited_by_user_id = admin.id
    user.invite_token_hash = token_hash(invite_token)
    user.invite_sent_at = now
    user.invite_expires_at = now + timedelta(days=INVITE_TTL_DAYS)
    user.invite_accepted_at = None
    user.updated_at = now

    await db.commit()
    await db.refresh(user)

    invite_link = build_invite_link(invite_token, get_settings())
    try:
        email_sent = send_invite_email(user.email, invite_link, get_settings())
    except OSError:
        email_sent = False

    return InviteUserResponse(user=to_portal_user(user), invite_link=invite_link, email_sent=email_sent)


@router.patch("/admin/users/{user_id}/status", response_model=PortalUser)
async def update_user_status(
    user_id: int,
    payload: UserStatusRequest,
    admin: User = Depends(current_admin),
    db: AsyncSession = Depends(get_db),
) -> PortalUser:
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if user.id == admin.id or user.role == "admin":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="The admin account cannot be deactivated")

    user.is_active = payload.is_active
    user.deactivated_at = None if payload.is_active else utcnow()
    await db.commit()
    await db.refresh(user)
    return to_portal_user(user)
