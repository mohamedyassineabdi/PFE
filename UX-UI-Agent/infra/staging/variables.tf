variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "ux-ui-auditor"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 10000
}

variable "app_domain" {
  description = "Full domain name (for example staging.example.com)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the ALB HTTPS listener"
  type        = string
  default     = ""
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = []
}

variable "public_image_uri" {
  description = "Public container image URI used by the ECS task definition"
  type        = string
  default     = "public.ecr.aws/k8t9f9t5/ui-ux-auditor:latest"
}

variable "health_check_grace_period_seconds" {
  description = "Grace period for ECS service health checks"
  type        = number
  default     = 180
}

variable "app_user_uid" {
  description = "UID used by the runtime container user and EFS access point"
  type        = number
  default     = 1000
}

variable "app_user_gid" {
  description = "GID used by the runtime container user and EFS access point"
  type        = number
  default     = 1000
}

variable "enable_vercel" {
  description = "Whether to inject Vercel deployment configuration into the ECS task"
  type        = bool
  default     = true
}

variable "enable_ai_review" {
  description = "Whether to enable website/mobile AI review configuration"
  type        = bool
  default     = true
}

variable "enable_figma_ai_review" {
  description = "Whether to enable Figma AI review configuration"
  type        = bool
  default     = false
}

variable "ai_review_backend" {
  description = "AI review backend for website/mobile audits"
  type        = string
  default     = "openai"
}

variable "ai_review_base_url" {
  description = "AI review API base URL for website/mobile audits"
  type        = string
  default     = "https://api.openai.com/v1"
}

variable "ai_review_model" {
  description = "AI review model for website/mobile audits"
  type        = string
  default     = ""
}

variable "ai_review_timeout" {
  description = "AI review timeout in seconds"
  type        = number
  default     = 120
}

variable "ollama_api_host" {
  description = "Ollama-compatible API host for Figma AI review"
  type        = string
  default     = ""
}

variable "ollama_report_model" {
  description = "Ollama-compatible report polishing model for Figma audits"
  type        = string
  default     = ""
}

variable "ollama_ai_review_model" {
  description = "Ollama-compatible AI review model for Figma audits"
  type        = string
  default     = ""
}

variable "gtm_vision_base_url" {
  description = "Ollama-compatible base URL for GTM vision review requests"
  type        = string
  default     = ""
}

variable "gtm_vision_model" {
  description = "Ollama-compatible vision model for GTM screenshot review"
  type        = string
  default     = ""
}

variable "ollama_report_polish" {
  description = "Whether to polish Figma report copy with the Ollama-compatible model"
  type        = bool
  default     = true
}

variable "figma_token_secret_name" {
  description = "Optional override for the FIGMA_TOKEN secret name"
  type        = string
  default     = ""
}

variable "ai_review_api_key_secret_name" {
  description = "Optional override for the website/mobile AI review API key secret name"
  type        = string
  default     = ""
}

variable "ollama_api_key_secret_name" {
  description = "Optional override for the Figma AI review API key secret name"
  type        = string
  default     = ""
}

variable "vercel_token_secret_name" {
  description = "Optional override for the Vercel token secret name"
  type        = string
  default     = ""
}

variable "vercel_org_id_secret_name" {
  description = "Optional override for the Vercel org ID secret name"
  type        = string
  default     = ""
}

variable "vercel_project_id_secret_name" {
  description = "Optional override for the Vercel project ID secret name"
  type        = string
  default     = ""
}

variable "vercel_scope_secret_name" {
  description = "Optional override for the Vercel scope secret name"
  type        = string
  default     = ""
}

variable "container_cpu" {
  description = "Container CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 512 # 0.5 vCPU
}

variable "container_memory" {
  description = "Container memory in MB"
  type        = number
  default     = 2048 # 2 GB
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "enable_ollama_host" {
  description = "Whether to create a private EC2 instance that runs an Ollama-compatible API for the ECS service"
  type        = bool
  default     = false
}

variable "ollama_instance_type" {
  description = "EC2 instance type used for the optional Ollama host"
  type        = string
  default     = "t3.large"
}

variable "ollama_root_volume_size" {
  description = "Root EBS volume size in GB for the optional Ollama host"
  type        = number
  default     = 80
}

variable "ollama_bootstrap_model" {
  description = "Optional Ollama model name to pull automatically on first boot"
  type        = string
  default     = ""
}

variable "ollama_instance_ami_ssm_parameter" {
  description = "SSM parameter name that resolves to the AMI for the optional Ollama host"
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

variable "seed_placeholder_secrets" {
  description = "Whether Terraform should write placeholder secret values for required application secrets"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "ux-ui-auditor"
    Environment = "staging"
  }
}
