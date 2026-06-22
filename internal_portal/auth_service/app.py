import base64
import hashlib
import hmac
import html
import logging
import os
import re
import secrets
import sqlite3
import threading
import uuid
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Iterator

from fastapi import Depends, FastAPI, Header, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel


EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
PASSWORD_MIN_LENGTH = 8
PBKDF2_ITERATIONS = 310_000
logger = logging.getLogger("portal-auth")


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def to_iso(value: datetime) -> str:
    return value.replace(microsecond=0).isoformat().replace("+00:00", "Z")


def from_iso(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def normalize_email(value: str) -> str:
    normalized = value.strip().lower()
    if not EMAIL_RE.match(normalized):
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="A valid email is required.")
    return normalized


def validate_password(password: str) -> None:
    if len(password) < PASSWORD_MIN_LENGTH:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Password must be at least {PASSWORD_MIN_LENGTH} characters long.",
        )


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, PBKDF2_ITERATIONS)
    return "pbkdf2_sha256${iterations}${salt}${digest}".format(
        iterations=PBKDF2_ITERATIONS,
        salt=base64.b64encode(salt).decode("ascii"),
        digest=base64.b64encode(digest).decode("ascii"),
    )


def verify_password(password: str, encoded: str) -> bool:
    try:
        scheme, iterations, salt_b64, digest_b64 = encoded.split("$", 3)
        if scheme != "pbkdf2_sha256":
            return False
        digest = hashlib.pbkdf2_hmac(
            "sha256",
            password.encode("utf-8"),
            base64.b64decode(salt_b64.encode("ascii")),
            int(iterations),
        )
        return hmac.compare_digest(digest, base64.b64decode(digest_b64.encode("ascii")))
    except Exception:
        return False


@dataclass(frozen=True)
class Settings:
    db_path: str
    public_base_url: str
    session_ttl_hours: int
    invite_ttl_hours: int
    bootstrap_admin_email: str
    bootstrap_admin_password: str
    allowed_origins: list[str]
    ses_region: str
    ses_from_email: str
    ses_configuration_set: str

    @classmethod
    def from_env(cls) -> "Settings":
        allowed_origins = [
            item.strip()
            for item in os.getenv("PORTAL_AUTH_ALLOWED_ORIGINS", "").split(",")
            if item.strip()
        ]
        bootstrap_email = os.getenv("PORTAL_AUTH_BOOTSTRAP_ADMIN_EMAIL", "admin@example.com").strip()
        bootstrap_password = os.getenv("PORTAL_AUTH_BOOTSTRAP_ADMIN_PASSWORD", "ChangeMe123!")
        return cls(
            db_path=os.getenv("PORTAL_AUTH_DB_PATH", "/data/portal-auth.db"),
            public_base_url=os.getenv("PORTAL_AUTH_PUBLIC_BASE_URL", "").rstrip("/"),
            session_ttl_hours=max(1, int(os.getenv("PORTAL_AUTH_SESSION_TTL_HOURS", "24"))),
            invite_ttl_hours=max(1, int(os.getenv("PORTAL_AUTH_INVITE_TTL_HOURS", "72"))),
            bootstrap_admin_email=bootstrap_email,
            bootstrap_admin_password=bootstrap_password,
            allowed_origins=allowed_origins,
            ses_region=os.getenv("PORTAL_AUTH_SES_REGION", os.getenv("AWS_REGION", "")).strip(),
            ses_from_email=os.getenv("PORTAL_AUTH_SES_FROM_EMAIL", "").strip(),
            ses_configuration_set=os.getenv("PORTAL_AUTH_SES_CONFIGURATION_SET", "").strip(),
        )


class Database:
    def __init__(self, path: str) -> None:
        self.path = path
        self._lock = threading.Lock()
        Path(path).parent.mkdir(parents=True, exist_ok=True)

    @contextmanager
    def connect(self) -> Iterator[sqlite3.Connection]:
        connection = sqlite3.connect(self.path, timeout=30, check_same_thread=False)
        connection.row_factory = sqlite3.Row
        try:
            connection.execute("PRAGMA journal_mode=WAL")
            connection.execute("PRAGMA foreign_keys=ON")
            yield connection
            connection.commit()
        finally:
            connection.close()

    def initialize(self) -> None:
        with self._lock, self.connect() as connection:
            connection.executescript(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    email TEXT NOT NULL UNIQUE,
                    role TEXT NOT NULL,
                    password_hash TEXT,
                    is_active INTEGER NOT NULL DEFAULT 1,
                    invite_sent_at TEXT,
                    latest_login_at TEXT,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );

                CREATE TABLE IF NOT EXISTS sessions (
                    token_hash TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    expires_at TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                );

                CREATE TABLE IF NOT EXISTS invite_tokens (
                    token_hash TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    expires_at TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                );
                """
            )

    def seed_admin(self, email: str, password: str) -> None:
        normalized_email = normalize_email(email)
        validate_password(password)
        with self._lock, self.connect() as connection:
            existing = connection.execute("SELECT id FROM users WHERE email = ?", (normalized_email,)).fetchone()
            if existing:
                return
            now = to_iso(utc_now())
            connection.execute(
                """
                INSERT INTO users (id, email, role, password_hash, is_active, created_at, updated_at)
                VALUES (?, ?, 'admin', ?, 1, ?, ?)
                """,
                (str(uuid.uuid4()), normalized_email, hash_password(password), now, now),
            )

    def get_user_by_email(self, email: str) -> sqlite3.Row | None:
        with self.connect() as connection:
            return connection.execute("SELECT * FROM users WHERE email = ?", (email,)).fetchone()

    def get_user_by_id(self, user_id: str) -> sqlite3.Row | None:
        with self.connect() as connection:
            return connection.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()

    def create_session(self, user_id: str, ttl_hours: int) -> str:
        token = secrets.token_urlsafe(32)
        now = utc_now()
        with self._lock, self.connect() as connection:
            connection.execute(
                """
                INSERT INTO sessions (token_hash, user_id, expires_at, created_at)
                VALUES (?, ?, ?, ?)
                """,
                (hash_token(token), user_id, to_iso(now + timedelta(hours=ttl_hours)), to_iso(now)),
            )
        return token

    def get_user_for_session(self, token: str) -> sqlite3.Row | None:
        now = to_iso(utc_now())
        with self._lock, self.connect() as connection:
            connection.execute("DELETE FROM sessions WHERE expires_at <= ?", (now,))
            return connection.execute(
                """
                SELECT users.*
                FROM sessions
                JOIN users ON users.id = sessions.user_id
                WHERE sessions.token_hash = ?
                """,
                (hash_token(token),),
            ).fetchone()

    def update_latest_login(self, user_id: str) -> None:
        now = to_iso(utc_now())
        with self._lock, self.connect() as connection:
            connection.execute(
                "UPDATE users SET latest_login_at = ?, updated_at = ? WHERE id = ?",
                (now, now, user_id),
            )

    def list_users(self) -> list[sqlite3.Row]:
        with self.connect() as connection:
            return list(
                connection.execute(
                    """
                    SELECT *
                    FROM users
                    ORDER BY CASE role WHEN 'admin' THEN 0 ELSE 1 END, email ASC
                    """
                ).fetchall()
            )

    def upsert_invited_user(self, email: str, invite_ttl_hours: int) -> tuple[sqlite3.Row, str]:
        now_dt = utc_now()
        now = to_iso(now_dt)
        token = secrets.token_urlsafe(32)
        token_hash_value = hash_token(token)
        expires_at = to_iso(now_dt + timedelta(hours=invite_ttl_hours))

        with self._lock, self.connect() as connection:
            user = connection.execute("SELECT * FROM users WHERE email = ?", (email,)).fetchone()
            if user is None:
                user_id = str(uuid.uuid4())
                connection.execute(
                    """
                    INSERT INTO users (id, email, role, is_active, invite_sent_at, created_at, updated_at)
                    VALUES (?, ?, 'user', 1, ?, ?, ?)
                    """,
                    (user_id, email, now, now, now),
                )
            else:
                user_id = user["id"]
                if user["role"] == "admin":
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Admin accounts cannot be reinvited through this workflow.",
                    )
                connection.execute(
                    """
                    UPDATE users
                    SET invite_sent_at = ?, updated_at = ?
                    WHERE id = ?
                    """,
                    (now, now, user_id),
                )
                connection.execute("DELETE FROM invite_tokens WHERE user_id = ?", (user_id,))

            connection.execute(
                """
                INSERT INTO invite_tokens (token_hash, user_id, expires_at, created_at)
                VALUES (?, ?, ?, ?)
                """,
                (token_hash_value, user_id, expires_at, now),
            )
            user = connection.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        return user, token

    def consume_invite(self, invite_token: str, password: str) -> sqlite3.Row:
        now = to_iso(utc_now())
        with self._lock, self.connect() as connection:
            token_row = connection.execute(
                "SELECT * FROM invite_tokens WHERE token_hash = ?",
                (hash_token(invite_token),),
            ).fetchone()
            if token_row is None or token_row["expires_at"] <= now:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invitation token is invalid or expired.")

            connection.execute(
                """
                UPDATE users
                SET password_hash = ?, is_active = 1, updated_at = ?
                WHERE id = ?
                """,
                (hash_password(password), now, token_row["user_id"]),
            )
            connection.execute("DELETE FROM invite_tokens WHERE user_id = ?", (token_row["user_id"],))
            return connection.execute("SELECT * FROM users WHERE id = ?", (token_row["user_id"],)).fetchone()

    def set_user_status(self, user_id: str, is_active: bool) -> sqlite3.Row:
        now = to_iso(utc_now())
        with self._lock, self.connect() as connection:
            user = connection.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
            if user is None:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")
            if user["role"] == "admin":
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Admin users cannot be deactivated.")

            connection.execute(
                "UPDATE users SET is_active = ?, updated_at = ? WHERE id = ?",
                (1 if is_active else 0, now, user_id),
            )
            if not is_active:
                connection.execute("DELETE FROM sessions WHERE user_id = ?", (user_id,))
            return connection.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()


class LoginRequest(BaseModel):
    email: str
    password: str


class SetPasswordRequest(BaseModel):
    token: str
    password: str
    confirm_password: str


class InviteUserRequest(BaseModel):
    email: str


class SetUserStatusRequest(BaseModel):
    is_active: bool


def user_payload(row: sqlite3.Row) -> dict:
    return {
        "id": row["id"],
        "email": row["email"],
        "role": row["role"],
        "is_active": bool(row["is_active"]),
        "invite_sent_at": row["invite_sent_at"],
        "latest_login_at": row["latest_login_at"],
    }


settings = Settings.from_env()
database = Database(settings.db_path)
database.initialize()
database.seed_admin(settings.bootstrap_admin_email, settings.bootstrap_admin_password)

app = FastAPI(title="Portal Auth Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins or ["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


def build_invite_url(token: str) -> str:
    relative_path = f"/setup-password.html?token={token}"
    if settings.public_base_url:
        return f"{settings.public_base_url}{relative_path}"
    return relative_path


def send_invite_email(to_email: str, invite_url: str) -> bool:
    if not settings.ses_from_email:
        return False

    try:
        import boto3
    except Exception as exc:
        logger.warning("SES invite email skipped because boto3 is unavailable: %s", exc)
        return False

    subject = "Your TWI Portal account is ready"
    text_body = (
        "Hello,\n\n"
        "An administrator invited you to TWI Portal.\n\n"
        f"Create your password here: {invite_url}\n\n"
        f"This invitation expires in {settings.invite_ttl_hours} hours."
    )
    escaped_url = html.escape(invite_url, quote=True)
    html_body = (
        "<p>Hello,</p>"
        "<p>An administrator invited you to TWI Portal.</p>"
        f'<p><a href="{escaped_url}">Create your password</a></p>'
        f"<p>This invitation expires in {settings.invite_ttl_hours} hours.</p>"
    )
    message = {
        "Source": settings.ses_from_email,
        "Destination": {"ToAddresses": [to_email]},
        "Message": {
            "Subject": {"Data": subject, "Charset": "UTF-8"},
            "Body": {
                "Text": {"Data": text_body, "Charset": "UTF-8"},
                "Html": {"Data": html_body, "Charset": "UTF-8"},
            },
        },
    }
    if settings.ses_configuration_set:
        message["ConfigurationSetName"] = settings.ses_configuration_set

    try:
        client_kwargs = {"region_name": settings.ses_region} if settings.ses_region else {}
        boto3.client("ses", **client_kwargs).send_email(**message)
        return True
    except Exception as exc:
        logger.warning("SES invite email failed for %s: %s", to_email, exc)
        return False


def get_bearer_token(authorization: str | None = Header(default=None)) -> str:
    if not authorization:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication required.")
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authorization header.")
    return token


def get_current_user(token: str = Depends(get_bearer_token)) -> sqlite3.Row:
    user = database.get_user_for_session(token)
    if user is None or not bool(user["is_active"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Session expired or invalid.")
    return user


def require_admin(user: sqlite3.Row = Depends(get_current_user)) -> sqlite3.Row:
    if user["role"] != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin role required.")
    return user


@app.get("/healthz")
def healthz() -> dict:
    return {"status": "ok"}


@app.post("/auth/login")
def login(payload: LoginRequest) -> dict:
    email = normalize_email(payload.email)
    user = database.get_user_by_email(email)
    if user is None or not user["password_hash"] or not verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password.")
    if not bool(user["is_active"]):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="This account is inactive.")

    token = database.create_session(user["id"], settings.session_ttl_hours)
    database.update_latest_login(user["id"])
    refreshed_user = database.get_user_by_id(user["id"])
    return {"token": token, "user": user_payload(refreshed_user)}


@app.get("/auth/me")
def me(user: sqlite3.Row = Depends(get_current_user)) -> dict:
    return user_payload(user)


@app.post("/auth/set-password")
def set_password(payload: SetPasswordRequest) -> dict:
    if payload.password != payload.confirm_password:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Passwords do not match.")
    validate_password(payload.password)
    user = database.consume_invite(payload.token, payload.password)
    return {"user": user_payload(user)}


@app.get("/auth/admin/users")
def list_users(_admin: sqlite3.Row = Depends(require_admin)) -> dict:
    return {"items": [user_payload(user) for user in database.list_users()]}


@app.post("/auth/admin/users/invite")
def invite_user(payload: InviteUserRequest, _admin: sqlite3.Row = Depends(require_admin)) -> dict:
    email = normalize_email(payload.email)
    user, token = database.upsert_invited_user(email, settings.invite_ttl_hours)
    invite_url = build_invite_url(token)
    return {
        "email": user["email"],
        "email_sent": send_invite_email(user["email"], invite_url),
        "invite_url": invite_url,
        "user": user_payload(user),
    }


@app.patch("/auth/admin/users/{user_id}/status")
def update_user_status(
    user_id: str,
    payload: SetUserStatusRequest,
    _admin: sqlite3.Row = Depends(require_admin),
) -> dict:
    user = database.set_user_status(user_id, payload.is_active)
    return user_payload(user)
