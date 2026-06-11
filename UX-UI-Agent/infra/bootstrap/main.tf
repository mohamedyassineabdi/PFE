terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Get your AWS account ID
data "aws_caller_identity" "current" {}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "ux-ui-auditor-tfstate-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.force_destroy_state_bucket

  tags = {
    Name = "Terraform State"
  }
}

# Prevent public access to state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "ux-ui-auditor-tfstate-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock"
  }
}

output "s3_bucket" {
  value = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table" {
  value = aws_dynamodb_table.terraform_locks.name
}

output "backend_config" {
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = var.state_key
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
    encrypt        = true
  }
  description = "Use this in infra/staging/backend.hcl"
}
