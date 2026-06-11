from __future__ import annotations

import base64
import hashlib
import hmac
import json
import secrets
import smtplib
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
from typing import Any

from app.core.config import Settings
from app.db.models.user import User

PASSWORD_ITERATIONS = 260_000
INVITE_TTL_DAYS = 7
SESSION_TTL_HOURS = 12


def normalize_email(email: str) -> str:
    return email.strip().lower()


def hash_password(password: str) -> str:
    salt = secrets.token_urlsafe(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), PASSWORD_ITERATIONS)
    return f"pbkdf2_sha256${PASSWORD_ITERATIONS}${salt}${base64.b64encode(digest).decode('utf-8')}"


def verify_password(password: str, password_hash: str | None) -> bool:
    if not password_hash:
        return False
    try:
        algorithm, iterations_raw, salt, stored_digest = password_hash.split("$", 3)
        if algorithm != "pbkdf2_sha256":
            return False
        iterations = int(iterations_raw)
        digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), iterations)
        return hmac.compare_digest(base64.b64encode(digest).decode("utf-8"), stored_digest)
    except (ValueError, TypeError):
        return False


def token_hash(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def create_invite_token() -> str:
    return secrets.token_urlsafe(32)


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("utf-8")


def _b64url_decode(value: str) -> bytes:
    padding = "=" * (-len(value) % 4)
    return base64.urlsafe_b64decode(value + padding)


def create_session_token(user: User, settings: Settings) -> str:
    issued_at = utcnow()
    payload = {
        "sub": str(user.id),
        "email": user.email,
        "role": user.role,
        "iat": int(issued_at.timestamp()),
        "exp": int((issued_at + timedelta(hours=SESSION_TTL_HOURS)).timestamp()),
    }
    payload_part = _b64url(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    signature = hmac.new(settings.auth_secret_key.encode("utf-8"), payload_part.encode("utf-8"), hashlib.sha256)
    return f"{payload_part}.{_b64url(signature.digest())}"


def decode_session_token(token: str, settings: Settings) -> dict[str, Any] | None:
    try:
        payload_part, signature_part = token.split(".", 1)
        expected = hmac.new(settings.auth_secret_key.encode("utf-8"), payload_part.encode("utf-8"), hashlib.sha256)
        if not hmac.compare_digest(_b64url(expected.digest()), signature_part):
            return None
        payload = json.loads(_b64url_decode(payload_part))
        if int(payload.get("exp", 0)) < int(utcnow().timestamp()):
            return None
        return payload
    except (ValueError, json.JSONDecodeError, TypeError):
        return None


def build_invite_link(token: str, settings: Settings) -> str:
    base_url = settings.portal_public_url.rstrip("/")
    return f"{base_url}/setup-password.html#token={token}"


def send_invite_email(email: str, invite_link: str, settings: Settings) -> bool:
    if not settings.smtp_host or not settings.smtp_from_email:
        return False

    message = EmailMessage()
    message["Subject"] = "EY Studio+ portal invitation"
    message["From"] = settings.smtp_from_email
    message["To"] = email
    message.set_content(
        "You have been invited to the EY Studio+ internal portal.\n\n"
        f"Set your password here: {invite_link}\n\n"
        "This link expires in 7 days."
    )

    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=20) as smtp:
        if settings.smtp_use_tls:
            smtp.starttls()
        if settings.smtp_username and settings.smtp_password:
            smtp.login(settings.smtp_username, settings.smtp_password)
        smtp.send_message(message)
    return True
