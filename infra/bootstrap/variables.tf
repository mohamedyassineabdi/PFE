variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "state_key" {
  description = "Object key used by the staging Terraform state file inside the remote state bucket"
  type        = string
  default     = "twi-portal/staging/terraform.tfstate"
}

variable "force_destroy_state_bucket" {
  description = "Allow destroying the remote state bucket even when it still contains versioned objects"
  type        = bool
  default     = true
}
