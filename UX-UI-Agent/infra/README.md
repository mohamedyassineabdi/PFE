# Terraform AWS Deployment

This Terraform layout now focuses on infrastructure only:

1. ECS service for the UI app
2. ALB, VPC, NAT, subnets, security groups
3. EFS for shared app storage
4. Secrets Manager entries used by the app
5. Optional private Ollama EC2 host
6. Terraform backend state bucket + DynamoDB lock table

It no longer depends on a private ECR repository, CodeBuild, CodePipeline, or CodeStar Connections.
The app image is expected to live in the public repository:

```text
public.ecr.aws/k8t9f9t5/ui-ux-auditor:latest
```

## Main Files

1. `infra/recreate-all.ps1`
2. `infra/destroy-all.ps1`
3. `infra/staging/terraform.tfvars`
4. `infra/staging/backend.hcl`

## Recreate Everything

This recreates:

1. Terraform backend bucket
2. Terraform lock table
3. Full staging infrastructure
4. Optional Ollama host if enabled in `terraform.tfvars`

Run:

```powershell
cd infra
.\recreate-all.ps1 -AutoApprove
```

After recreate, if the private Ollama host is enabled, you can verify the local Ollama-compatible API through SSM without opening the instance:

```powershell
cd infra
.\check-ollama-host.ps1
```

## Destroy Everything Billable

This destroys all Terraform-managed AWS resources that can keep costing money, including:

1. ECS cluster and service
2. ALB
3. NAT gateway and EIP
4. VPC networking
5. EFS
6. EC2 Ollama host if enabled
7. Secrets Manager secrets
8. Terraform state bucket
9. Terraform DynamoDB lock table

It intentionally does not touch the public image repository:

```text
public.ecr.aws/k8t9f9t5/ui-ux-auditor
```

Run:

```powershell
cd infra
.\destroy-all.ps1 -AutoApprove
```

## Optional Ollama Host

The staging stack can create a private EC2 instance that runs an Ollama-compatible API on port `11434`.

Relevant settings in `infra/staging/terraform.tfvars`:

1. `enable_ollama_host`
2. `ollama_instance_type`
3. `ollama_root_volume_size`
4. `ollama_api_host`

Behavior:

1. If `enable_ollama_host = true` and `ollama_api_host = ""`, ECS uses the private EC2 host automatically.
2. If `ollama_api_host` is set explicitly, ECS uses that URL instead.
3. The Ollama host is private and only accepts traffic from the ECS service security group.
4. The EC2 host reads the `ux-ui-auditor/staging/ollama-api-key` secret at boot and starts the Ollama container with that API key in its environment.
5. The EC2 host does not auto-pull models; it just exposes the local Ollama-compatible API on `11434`.
6. `.\check-ollama-host.ps1` sends a test `/api/chat` request to `127.0.0.1:11434` on the instance through AWS SSM, so you can confirm the local Ollama API responds after create.

## Notes

1. The current staging defaults enable the private Ollama host and point the app at cloud-style Ollama models through the local Ollama API.
2. If you change the Ollama host instance type, make sure your AWS account in `eu-west-3` allows that EC2 type.
3. The public image repository is outside Terraform on purpose, so destroy/recreate cycles do not wipe your published image.
