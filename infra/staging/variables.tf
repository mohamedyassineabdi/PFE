variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "app_name" {
  description = "Application name prefix"
  type        = string
  default     = "twi-portal"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS on the ALB"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Optional Route 53 hosted zone ID for alias records"
  type        = string
  default     = ""
}

variable "portal_domain" {
  description = "Portal hostname"
  type        = string
  default     = ""
}

variable "ux_ui_domain" {
  description = "UI/UX auditor hostname"
  type        = string
  default     = ""
}

variable "cx_domain" {
  description = "CX frontend hostname"
  type        = string
  default     = ""
}

variable "cx_api_domain" {
  description = "Optional dedicated CX API hostname"
  type        = string
  default     = ""
}

variable "portal_api_base_url" {
  description = "Optional override for the portal auth API base URL. Leave blank to use same-origin /auth routes."
  type        = string
  default     = ""
}

variable "portal_image_uri" {
  description = "Container image URI for the internal portal"
  type        = string
  default     = "public.ecr.aws/k8t9f9t5/twi-portal:latest"
}

variable "portal_auth_image_uri" {
  description = "Container image URI for the internal portal auth service"
  type        = string
  default     = "public.ecr.aws/k8t9f9t5/twi-portal-auth:latest"
}

variable "ux_ui_image_uri" {
  description = "Container image URI for the UI/UX auditor"
  type        = string
  default     = "public.ecr.aws/k8t9f9t5/ui-ux-auditor:latest"
}

variable "cx_frontend_image_uri" {
  description = "Container image URI for the CX frontend"
  type        = string
  default     = "public.ecr.aws/k8t9f9t5/twi-cx-frontend:latest"
}

variable "cx_backend_image_uri" {
  description = "Container image URI for the CX backend"
  type        = string
  default     = "public.ecr.aws/k8t9f9t5/twi-cx-backend:latest"
}

variable "portal_container_port" {
  description = "Portal container port"
  type        = number
  default     = 80
}

variable "portal_auth_container_port" {
  description = "Portal auth container port"
  type        = number
  default     = 8081
}

variable "ux_ui_container_port" {
  description = "UI/UX container port"
  type        = number
  default     = 10000
}

variable "cx_frontend_container_port" {
  description = "CX frontend container port"
  type        = number
  default     = 8080
}

variable "cx_backend_container_port" {
  description = "CX backend container port"
  type        = number
  default     = 8000
}

variable "metabase_enabled" {
  description = "Whether to run Metabase in ECS and expose it through the shared ALB"
  type        = bool
  default     = true
}

variable "metabase_image_uri" {
  # v0.47.x is the last release whose /embed/* endpoint does not emit a
  # nonce-based style-src CSP.  Newer versions block the inline styles that
  # Leaflet needs to position map markers, breaking the pin-map card.
  description = "Container image URI for Metabase"
  type        = string
  default     = "metabase/metabase:v0.47.6"
}

variable "metabase_container_port" {
  description = "Metabase container port"
  type        = number
  default     = 3000
}

variable "metabase_alb_listener_port" {
  description = "Public ALB listener port used for Metabase when no custom domain is configured"
  type        = number
  default     = 3000
}

variable "portal_container_cpu" {
  description = "Portal container CPU units"
  type        = number
  default     = 256
}

variable "portal_container_memory" {
  description = "Portal container memory in MB"
  type        = number
  default     = 512
}

variable "portal_auth_container_cpu" {
  description = "Portal auth container CPU units"
  type        = number
  default     = 256
}

variable "portal_auth_container_memory" {
  description = "Portal auth container memory in MB"
  type        = number
  default     = 512
}

variable "ux_ui_container_cpu" {
  description = "UI/UX container CPU units"
  type        = number
  default     = 512
}

variable "ux_ui_container_memory" {
  description = "UI/UX container memory in MB"
  type        = number
  default     = 2048
}

variable "cx_frontend_container_cpu" {
  description = "CX frontend container CPU units"
  type        = number
  default     = 256
}

variable "cx_frontend_container_memory" {
  description = "CX frontend container memory in MB"
  type        = number
  default     = 512
}

variable "cx_backend_container_cpu" {
  description = "CX backend container CPU units"
  type        = number
  default     = 512
}

variable "cx_backend_container_memory" {
  description = "CX backend container memory in MB"
  type        = number
  default     = 1024
}

variable "metabase_container_cpu" {
  description = "Metabase container CPU units"
  type        = number
  default     = 1024
}

variable "metabase_container_memory" {
  description = "Metabase container memory in MB"
  type        = number
  default     = 2048
}

variable "portal_desired_count" {
  description = "Number of portal tasks"
  type        = number
  default     = 1
}

variable "portal_auth_desired_count" {
  description = "Number of portal auth tasks"
  type        = number
  default     = 1
}

variable "ux_ui_desired_count" {
  description = "Number of UI/UX tasks"
  type        = number
  default     = 1
}

variable "cx_frontend_desired_count" {
  description = "Number of CX frontend tasks"
  type        = number
  default     = 1
}

variable "cx_backend_desired_count" {
  description = "Number of CX backend tasks"
  type        = number
  default     = 1
}

variable "metabase_desired_count" {
  description = "Number of Metabase tasks"
  type        = number
  default     = 1
}

variable "portal_health_check_grace_period_seconds" {
  description = "Portal service health check grace period"
  type        = number
  default     = 60
}

variable "portal_auth_health_check_grace_period_seconds" {
  description = "Portal auth service health check grace period"
  type        = number
  default     = 60
}

variable "ux_ui_health_check_grace_period_seconds" {
  description = "UI/UX service health check grace period"
  type        = number
  default     = 180
}

variable "cx_frontend_health_check_grace_period_seconds" {
  description = "CX frontend service health check grace period"
  type        = number
  default     = 60
}

variable "cx_backend_health_check_grace_period_seconds" {
  description = "CX backend service health check grace period"
  type        = number
  default     = 90
}

variable "metabase_health_check_grace_period_seconds" {
  description = "Metabase service health check grace period"
  type        = number
  default     = 300
}

variable "ux_app_user_uid" {
  description = "UID used by the UI/UX runtime container user and EFS access point"
  type        = number
  default     = 1000
}

variable "ux_app_user_gid" {
  description = "GID used by the UI/UX runtime container user and EFS access point"
  type        = number
  default     = 1000
}

variable "ux_enable_vercel" {
  description = "Whether to inject Vercel deployment configuration into the UI/UX task"
  type        = bool
  default     = true
}

variable "ux_vercel_token" {
  description = "Vercel token used by the UI/UX report deployment service"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ux_vercel_org_id" {
  description = "Vercel team/org ID used by the UI/UX report deployment service"
  type        = string
  default     = ""
}

variable "ux_vercel_project_id" {
  description = "Vercel project ID used by the UI/UX report deployment service"
  type        = string
  default     = ""
}

variable "ux_vercel_scope" {
  description = "Optional Vercel scope name or team slug for CLI deploys. Leave empty when the linked project is enough."
  type        = string
  default     = ""
}

variable "portal_auth_session_ttl_hours" {
  description = "Portal auth session lifetime in hours"
  type        = number
  default     = 24
}

variable "portal_auth_invite_ttl_hours" {
  description = "Portal auth invitation lifetime in hours"
  type        = number
  default     = 72
}

variable "portal_auth_ses_region" {
  description = "AWS SES region used by portal auth invitation emails. Defaults to aws_region when empty."
  type        = string
  default     = ""
}

variable "portal_auth_ses_from_email" {
  description = "Verified SES sender email for portal auth invitation emails. Leave empty to disable email delivery."
  type        = string
  default     = ""
}

variable "portal_auth_ses_configuration_set" {
  description = "Optional SES configuration set for portal auth invitation emails."
  type        = string
  default     = ""
}

variable "portal_auth_admin_email_secret_name" {
  description = "Optional override for the portal auth bootstrap admin email secret name"
  type        = string
  default     = ""
}

variable "portal_auth_admin_password_secret_name" {
  description = "Optional override for the portal auth bootstrap admin password secret name"
  type        = string
  default     = ""
}

variable "portal_auth_admin_email" {
  description = "Bootstrap admin email for the internal portal auth service"
  type        = string
  default     = ""
  sensitive   = true
}

variable "portal_auth_admin_password" {
  description = "Bootstrap admin password for the internal portal auth service"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ux_enable_ai_review" {
  description = "Whether to enable website and mobile AI review configuration for the UI/UX app"
  type        = bool
  default     = true
}

variable "ux_enable_figma_ai_review" {
  description = "Whether to enable Figma AI review configuration"
  type        = bool
  default     = false
}

variable "ux_ai_review_backend" {
  description = "AI review backend for website and mobile audits"
  type        = string
  default     = "ollama"
}

variable "ux_ai_review_base_url" {
  description = "AI review API base URL"
  type        = string
  default     = ""
}

variable "ux_ai_review_model" {
  description = "AI review model"
  type        = string
  default     = "gpt-oss:120b-cloud"
}

variable "ux_ai_review_timeout" {
  description = "AI review timeout in seconds"
  type        = number
  default     = 120
}

variable "ux_ollama_api_host" {
  description = "Explicit Ollama-compatible API host for the UI/UX app"
  type        = string
  default     = ""
}

variable "ux_ollama_report_model" {
  description = "Ollama-compatible report polishing model for Figma audits"
  type        = string
  default     = "gpt-oss:120b-cloud"
}

variable "ux_ollama_ai_review_model" {
  description = "Ollama-compatible AI review model for Figma audits"
  type        = string
  default     = "gpt-oss:120b-cloud"
}

variable "ux_gtm_vision_base_url" {
  description = "Ollama-compatible base URL for GTM vision review requests"
  type        = string
  default     = ""
}

variable "ux_gtm_vision_model" {
  description = "Ollama-compatible vision model for GTM screenshot review"
  type        = string
  default     = "qwen3-vl:235b-cloud"
}

variable "ux_ollama_report_polish" {
  description = "Whether to polish Figma report copy with the Ollama-compatible model"
  type        = bool
  default     = true
}

variable "ux_enable_ollama_host" {
  description = "Whether to create a private EC2 instance that runs an Ollama-compatible API for UI/UX"
  type        = bool
  default     = true
}

variable "ux_ollama_instance_type" {
  description = "EC2 instance type used for the optional UI/UX Ollama host"
  type        = string
  default     = "c7i-flex.large"
}

variable "ux_ollama_root_volume_size" {
  description = "Root EBS volume size in GB for the optional UI/UX Ollama host"
  type        = number
  default     = 80
}

variable "ux_ollama_bootstrap_model" {
  description = "Optional Ollama model name to pull automatically on first boot"
  type        = string
  default     = "gpt-oss:120b-cloud"
}

variable "ux_ollama_instance_ami_ssm_parameter" {
  description = "SSM parameter name used to resolve the Ollama host AMI"
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

variable "ux_figma_token_secret_name" {
  description = "Optional override for the UI/UX FIGMA_TOKEN secret name"
  type        = string
  default     = ""
}

variable "ux_ai_review_api_key_secret_name" {
  description = "Optional override for the UI/UX AI review API key secret name"
  type        = string
  default     = ""
}

variable "ux_ollama_api_key_secret_name" {
  description = "Optional override for the UI/UX Ollama API key secret name"
  type        = string
  default     = ""
}

variable "ux_figma_token" {
  description = "UI/UX FIGMA_TOKEN value"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ux_ai_review_api_key" {
  description = "UI/UX AI_REVIEW_API_KEY value for non-Ollama providers"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ux_ollama_api_key" {
  description = "UI/UX OLLAMA_API_KEY value"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ux_vercel_token_secret_name" {
  description = "Optional override for the UI/UX Vercel token secret name"
  type        = string
  default     = ""
}

variable "ux_vercel_org_id_secret_name" {
  description = "Optional override for the UI/UX Vercel org ID secret name"
  type        = string
  default     = ""
}

variable "ux_vercel_project_id_secret_name" {
  description = "Optional override for the UI/UX Vercel project ID secret name"
  type        = string
  default     = ""
}

variable "ux_vercel_scope_secret_name" {
  description = "Optional override for the UI/UX Vercel scope secret name"
  type        = string
  default     = ""
}

variable "create_cx_rds" {
  description = "Whether to provision a PostgreSQL RDS instance for the CX backend"
  type        = bool
  default     = true
}

variable "cx_db_name" {
  description = "Database name for the CX backend"
  type        = string
  default     = "cxportal"
}

variable "cx_db_username" {
  description = "Database username for the CX backend"
  type        = string
  default     = "cxportal"
}

variable "cx_db_password" {
  description = "Database password for the CX backend RDS instance"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

variable "cx_db_instance_class" {
  description = "RDS instance class for the CX database"
  type        = string
  default     = "db.t4g.micro"
}

variable "cx_db_allocated_storage" {
  description = "Allocated storage in GB for the CX database"
  type        = number
  default     = 20
}

variable "cx_db_engine_version" {
  description = "PostgreSQL engine version for the CX database"
  type        = string
  default     = "16.3"
}

variable "cx_db_multi_az" {
  description = "Whether to enable Multi-AZ for the CX database"
  type        = bool
  default     = false
}

variable "cx_db_backup_retention_days" {
  description = "Backup retention for the CX database"
  type        = number
  default     = 7
}

variable "cx_db_skip_final_snapshot" {
  description = "Whether to skip the final snapshot on destroy for the CX database"
  type        = bool
  default     = true
}

variable "cx_app_env" {
  description = "APP_ENV passed to the CX backend"
  type        = string
  default     = "staging"
}

variable "cx_app_name" {
  description = "APP_NAME passed to the CX backend"
  type        = string
  default     = "CX Assessment API"
}

variable "cx_mistral_model" {
  description = "Mistral model used by the CX backend"
  type        = string
  default     = "mistral-medium"
}

variable "cx_mistral_base_url" {
  description = "Mistral base URL used by the CX backend"
  type        = string
  default     = "https://api.mistral.ai/v1"
}

variable "cx_langsearch_base_url" {
  description = "LangSearch base URL used by the CX backend"
  type        = string
  default     = "https://api.langsearch.com/v1"
}

variable "cx_mistral_api_key" {
  description = "CX MISTRAL_API_KEY value"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cx_langsearch_api_key" {
  description = "CX LANGSEARCH_API_KEY value"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cx_consultation_receiver_email" {
  description = "CX consultation receiver email"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cx_metabase_dashboard_id" {
  description = "Optional Metabase dashboard ID exposed to the CX backend"
  type        = string
  default     = ""
}

variable "metabase_embedding_secret" {
  description = "Static embedding secret shared by Metabase and the CX backend"
  type        = string
  sensitive   = true
  default     = "02fc91b23b7f4d491f251a0ae7e11b488f0d43b7419b4efdcfe5e6940c405cf9"
}

variable "cx_database_url_secret_name" {
  description = "Optional override for the CX DATABASE_URL secret name"
  type        = string
  default     = ""
}

variable "cx_mistral_api_key_secret_name" {
  description = "Optional override for the CX MISTRAL_API_KEY secret name"
  type        = string
  default     = ""
}

variable "cx_langsearch_api_key_secret_name" {
  description = "Optional override for the CX LANGSEARCH_API_KEY secret name"
  type        = string
  default     = ""
}

variable "cx_consultation_receiver_email_secret_name" {
  description = "Optional override for the CX CONSULTATION_RECEIVER_EMAIL secret name"
  type        = string
  default     = ""
}

variable "cx_metabase_site_url_secret_name" {
  description = "Optional override for the CX METABASE_SITE_URL secret name"
  type        = string
  default     = ""
}

variable "cx_metabase_embed_secret_secret_name" {
  description = "Optional override for the CX METABASE_EMBED_SECRET secret name"
  type        = string
  default     = ""
}

variable "seed_placeholder_secrets" {
  description = "Whether Terraform should write placeholder values for required secrets"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "twi-portal"
    Environment = "staging"
  }
}
