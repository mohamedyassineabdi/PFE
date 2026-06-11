from datetime import datetime

from pydantic import BaseModel, EmailStr, Field, field_validator


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=256)


class PortalUser(BaseModel):
    id: int
    email: EmailStr
    role: str
    is_active: bool
    latest_login_at: datetime | None = None
    invite_sent_at: datetime | None = None
    invite_accepted_at: datetime | None = None
    created_at: datetime


class AuthResponse(BaseModel):
    token: str
    user: PortalUser


class InviteUserRequest(BaseModel):
    email: EmailStr


class InviteUserResponse(BaseModel):
    user: PortalUser
    invite_link: str
    email_sent: bool


class UserListResponse(BaseModel):
    items: list[PortalUser]


class UserStatusRequest(BaseModel):
    is_active: bool


class SetPasswordRequest(BaseModel):
    token: str = Field(min_length=20, max_length=256)
    password: str = Field(min_length=8, max_length=256)
    confirm_password: str = Field(min_length=8, max_length=256)

    @field_validator("confirm_password")
    @classmethod
    def passwords_match(cls, value: str, info) -> str:
        password = info.data.get("password")
        if password and value != password:
            raise ValueError("Passwords do not match")
        return value


class MessageResponse(BaseModel):
    message: str
