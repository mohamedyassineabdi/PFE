# Portal AWS Deployment

This stack brings the whole portal onto AWS using the same Terraform-first pattern already used in `UX-UI-Agent/infra`, but expanded for all repo surfaces:

1. `internal_portal` as a static nginx site on ECS Fargate
2. `internal_portal/auth_service` as a lightweight FastAPI auth service on ECS Fargate with persistent data on EFS
3. `UX-UI-Agent` as the existing Python auditor service on ECS Fargate with EFS and optional Vercel credentials
4. `CX_Chat/frontend` as a static nginx site on ECS Fargate
5. `CX_Chat/backend` as a FastAPI service on ECS Fargate
6. Optional PostgreSQL RDS instance for the CX backend
7. Optional Metabase service on ECS Fargate for the CX admin analytics embed
8. Shared ALB, VPC, subnets, security groups, and optional Route 53 aliases
9. Terraform backend bootstrap state bucket and lock table

## Layout

1. `infra/bootstrap`
2. `infra/staging`
3. `infra/recreate-all.ps1`
4. `infra/destroy-all.ps1`

The `bootstrap` stack creates the remote Terraform state backend.
The `staging` stack creates the runtime infrastructure.
The helper scripts rebuild or remove the full shared stack without touching your already-published public container images.

## CX Model Coverage

The shared AWS stack includes the CX providers used by the backend today:

1. `MISTRAL_MODEL`
2. `MISTRAL_BASE_URL`
3. `MISTRAL_API_KEY`
4. `LANGSEARCH_BASE_URL`
5. `LANGSEARCH_API_KEY`

Those are injected through ECS environment values and Secrets Manager, so the CX assessment flows, report generation, and benchmark discovery services have their required model configuration on AWS.

## Runtime Model

Recommended DNS layout:

1. `portal.example.com` -> internal portal
2. `ux.example.com` -> UI/UX auditor
3. `cx.example.com` -> CX frontend
4. `cx-api.example.com` -> optional dedicated CX API hostname



## Portal Auth

The shared stack now includes the portal auth service that powers:

1. `POST /auth/login`
2. `GET /auth/me`
3. `POST /auth/set-password`
4. `GET /auth/admin/users`
5. `POST /auth/admin/users/invite`
6. `PATCH /auth/admin/users/{id}/status`

It is recreated automatically with the rest of the stack and uses:

1. Secrets Manager for the bootstrap admin email and password
2. The shared EFS file system for persistent SQLite storage
3. ALB path routing on `/auth/*`

## UI/UX Vercel Support

The shared stack preserves the existing UI/UX report deployment flow:

1. The UI/UX container still includes the Vercel CLI
2. Terraform can still inject `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`, and `VERCEL_SCOPE`
3. The ECS task continues to package and publish report artifacts to Vercel

## CX Metabase Embed

The stack can run Metabase without ngrok and without a custom domain:

1. `metabase_enabled = true` starts `metabase/metabase` on ECS Fargate.
2. Metabase is exposed through the shared ALB on `metabase_alb_listener_port`, default `3000`.
3. `terraform output metabase_url` prints the URL, usually `http://<alb-dns>:3000`.
4. Metabase stores its app database on EFS through a dedicated access point.
5. The CX backend receives `METABASE_SITE_URL`, `METABASE_EMBED_SECRET`, and `METABASE_DASHBOARD_ID`.

`recreate-all.ps1` bootstraps Metabase after the CX database migrations run. It creates the Metabase admin user from the portal admin secrets, connects the CX Postgres database, creates the `CX Analytics` dashboard, enables static embedding, writes the resulting dashboard ID back to `infra/staging/terraform.tfvars`, and reapplies Terraform if the CX backend needs a new `METABASE_DASHBOARD_ID`.

## Bootstrap

```powershell
cd infra\bootstrap
terraform init
terraform apply
```

Use the output values to fill `infra/staging/backend.hcl`.

## One-Command Helpers

Recreate all billable resources:

```powershell
cd infra
.\recreate-all.ps1 -AutoApprove
```

Destroy all Terraform-managed billable resources:

```powershell
cd infra
.\destroy-all.ps1 -AutoApprove
```

These helpers:

1. Recreate or destroy the bootstrap backend resources
2. Recreate or destroy the shared staging stack
3. Cover the billable runtime resources in state, including VPC, public/private subnets, route tables, ALB, ECS services, EFS, RDS, Secrets Manager secrets, managed Metabase, and the optional EC2 Ollama host with its EBS volume
4. Preserve the public image URIs because image repositories are intentionally outside Terraform

When `ux_enable_ollama_host = true`, `recreate-all.ps1` also waits for the EC2 host to appear in SSM, pulls/registers `ux_ollama_bootstrap_model`, `ux_ai_review_model`, `ux_gtm_vision_model`, and `ux_ollama_report_model`, then verifies the model list through SSM.

## Staging

1. Copy `infra/staging/backend.hcl.example` to `infra/staging/backend.hcl`
2. Copy `infra/staging/terraform.tfvars.example` to `infra/staging/terraform.tfvars`
3. Fill in your domains, ACM certificate ARN, image URIs, and any real secret values

Then deploy:

```powershell
cd infra\staging
terraform init -backend-config=backend.hcl
terraform apply
```

## Important Note

`PORTAL_API_BASE` is now optional. When it is blank, the portal frontend uses same-origin `/auth/*` routes, which is the default AWS setup created by this stack.
