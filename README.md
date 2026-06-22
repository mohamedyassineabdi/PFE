# PFE Workspace

This repository contains the portal, the UI/UX audit agent, the CX assessment application, and the AWS infrastructure used to run them together.


## Root Layout

- `internal_portal/` is the entry portal. It contains the public landing/index experience and the lightweight auth service used for login, user invites, and admin access.
- `UX-UI-Agent/` is the UI/UX auditor. It can audit websites, uploaded screenshots, Android app screens, and Figma files, then generate review reports. In AWS it runs as an ECS Fargate service and can use an Ollama EC2 host for AI review when enabled.
- `CX_Chat/` contains the customer-experience assessment product. The frontend is a React/Vite app, and the backend is a FastAPI service backed by PostgreSQL. The admin analytics view uses a Metabase embedded dashboard.
- `infra/` contains Terraform and PowerShell helpers for AWS deployment. It provisions the VPC, ALB, ECS services, RDS, EFS, Secrets Manager values, optional Metabase, and optional Ollama EC2 host.
- `.docker-deploy/` stores the local Docker client config used for pushing images to ECR.

## UI/UX Agent

The UI/UX project is focused on automated product review. It collects evidence from live URLs, screenshots, mobile screens, or Figma files, scores the experience across UX/UI dimensions, and can produce deployable reports. The AWS deployment wires its environment through ECS variables and Secrets Manager, including Figma, Vercel, and AI review settings.

Useful entry points:

```powershell
cd UX-UI-Agent
npm run ui
```

See `UX-UI-Agent/README.md` for local audit details.

## CX Project

The CX project provides the assessment conversation, admin management screens, and analytics. The backend uses PostgreSQL through `DATABASE_URL`, runs migrations through a dedicated one-off ECS task, and exposes analytics data to Metabase. The frontend talks to the backend through the configured CX API base URL.

Useful entry points:

```powershell
cd CX_Chat\frontend
npm.cmd run build

cd CX_Chat\backend
python -m app.db.migrate
```

See `CX_Chat/backend/README.md` and `CX_Chat/frontend/README.md` for project-specific details.

## Deployment Overview

Deployment is Terraform-first and lives under `infra/`.

- `infra/bootstrap/` creates the Terraform remote state bucket in S3 and the DynamoDB lock table.
- `infra/staging/` creates the runtime AWS stack.
- `infra/recreate-all.ps1` recreates the full stack and runs bootstrap steps such as migrations and Metabase dashboard setup.
- `infra/destroy-all.ps1` destroys the Terraform-managed billable resources.

Typical full recreate:

```powershell
cd infra
.\recreate-all.ps1 -AutoApprove
```

Typical full destroy:

```powershell
cd infra
.\destroy-all.ps1 -AutoApprove
```

Container images are built locally and pushed to public ECR before ECS is updated. The image repositories themselves are intentionally outside Terraform state.

For the full AWS guide, read `infra/README.md`.
