Backend refactor scaffold for the CX assessment API.

Step 1 in the refactor:
- create a clean backend package layout
- centralize database configuration
- define production-oriented SQLAlchemy models
- add a SQL migration script for the current database

The legacy code under `app/` is kept in place for now to avoid a big-bang rewrite.

## Admin vocabulary alignment

The admin UI, API payloads, and consultant wording now follow one shared vocabulary:

- `question_guidelines`
  - Business name: `Question guidance for the LLM`
  - Meaning: internal guidance that helps the LLM generate better assessment questions
  - Not a fixed script shown to the client

- `recommendation_guideline`
  - Business name: `Recommended action direction`
  - Meaning: the core recommendation logic injected into the final report prompt

- `priority_hint`
  - Business name: `Priority level`
  - Meaning: urgency or maturity framing such as `urgent_foundation`, `build_consistency`, or `scale_advantage`

- `business_impact`
  - Business name: `Expected business impact`
  - Meaning: the customer or business outcome expected from the recommendation

- `tone_hint`
  - Business name: `Writing tone`
  - Meaning: preferred report tone such as `direct`, `balanced`, or `executive`

- `consultant_note`
  - Business name: `Optional framing note`
  - Meaning: optional nuance or framing support for the final recommendation wording

The API field names remain stable for compatibility, while UI labels and OpenAPI descriptions use the business wording above.

## Portal user administration

The internal portal now authenticates against the Postgres `users` table.

- Migration: `migrations/037_portal_users.sql`
- Predefined admin: `admin@ey.com` / `adminey123`
- Admin page: `internal_portal/admin.html`
- Invite password setup page: `internal_portal/setup-password.html`

Local database:

```sh
cd ../
docker compose up -d cx-db
```

Apply the SQL migrations to the `cx_assessment` database in order. For the new portal user table only:

```sh
psql "postgresql://postgres:Barbouch123!@127.0.0.1:5433/cx_assessment" -f backend/migrations/037_portal_users.sql
```

Email invitations use SMTP when these environment variables are set: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM_EMAIL`, `SMTP_USE_TLS`. Without SMTP, the invite API returns the one-time invite link for local testing.
