BEGIN;

CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(320) NOT NULL,
  password_hash VARCHAR(512),
  role VARCHAR(20) NOT NULL DEFAULT 'user',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  invited_by_user_id BIGINT REFERENCES users(id),
  invite_token_hash VARCHAR(64),
  invite_sent_at TIMESTAMPTZ,
  invite_accepted_at TIMESTAMPTZ,
  invite_expires_at TIMESTAMPTZ,
  latest_login_at TIMESTAMPTZ,
  password_updated_at TIMESTAMPTZ,
  deactivated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT users_role_check CHECK (role IN ('admin', 'user'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_users_email_lower ON users (LOWER(email));
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_single_admin ON users (role) WHERE role = 'admin';
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_invite_token_hash
  ON users (invite_token_hash)
  WHERE invite_token_hash IS NOT NULL;
CREATE INDEX IF NOT EXISTS ix_users_role ON users(role);
CREATE INDEX IF NOT EXISTS ix_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS ix_users_latest_login_at ON users(latest_login_at);

INSERT INTO users (
  email,
  password_hash,
  role,
  is_active,
  password_updated_at,
  created_at,
  updated_at
)
VALUES (
  'admin@ey.com',
  'pbkdf2_sha256$260000$HiGzZHvtVUmRV7HIVKrcqg$cgit80EcrI0gGamBAKSo3JCWvzVg3e+HMPV+1jGvnx4=',
  'admin',
  TRUE,
  NOW(),
  NOW(),
  NOW()
)
ON CONFLICT ((LOWER(email))) DO UPDATE
SET
  password_hash = EXCLUDED.password_hash,
  role = 'admin',
  is_active = TRUE,
  password_updated_at = NOW(),
  updated_at = NOW();

COMMIT;
