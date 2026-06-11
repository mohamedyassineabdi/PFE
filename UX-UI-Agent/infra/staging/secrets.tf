locals {
  figma_token_secret_name       = var.figma_token_secret_name != "" ? var.figma_token_secret_name : "${local.secret_name_prefix}/figma-token"
  ai_review_api_key_secret_name = var.ai_review_api_key_secret_name != "" ? var.ai_review_api_key_secret_name : "${local.secret_name_prefix}/ai-review-api-key"
  ollama_api_key_secret_name    = var.ollama_api_key_secret_name != "" ? var.ollama_api_key_secret_name : "${local.secret_name_prefix}/ollama-api-key"
  vercel_token_secret_name      = var.vercel_token_secret_name != "" ? var.vercel_token_secret_name : "${local.secret_name_prefix}/vercel-token"
  vercel_org_id_secret_name     = var.vercel_org_id_secret_name != "" ? var.vercel_org_id_secret_name : "${local.secret_name_prefix}/vercel-org-id"
  vercel_project_id_secret_name = var.vercel_project_id_secret_name != "" ? var.vercel_project_id_secret_name : "${local.secret_name_prefix}/vercel-project-id"
  vercel_scope_secret_name      = var.vercel_scope_secret_name != "" ? var.vercel_scope_secret_name : "${local.secret_name_prefix}/vercel-scope"
}

resource "aws_secretsmanager_secret" "figma_token" {
  name                    = local.figma_token_secret_name
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "figma_token" {
  count         = var.seed_placeholder_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.figma_token.id
  secret_string = "REPLACE_ME"
}

resource "aws_secretsmanager_secret" "ai_review_api_key" {
  name                    = local.ai_review_api_key_secret_name
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ai_review_api_key" {
  count         = var.seed_placeholder_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.ai_review_api_key.id
  secret_string = "REPLACE_ME"
}

resource "aws_secretsmanager_secret" "ollama_api_key" {
  name                    = local.ollama_api_key_secret_name
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ollama_api_key" {
  count         = var.seed_placeholder_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.ollama_api_key.id
  secret_string = "REPLACE_ME"
}

resource "aws_secretsmanager_secret" "vercel_token" {
  count                   = var.enable_vercel ? 1 : 0
  name                    = local.vercel_token_secret_name
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "vercel_token" {
  count         = var.enable_vercel && var.seed_placeholder_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.vercel_token[0].id
  secret_string = "REPLACE_ME"
}

resource "aws_secretsmanager_secret" "vercel_org_id" {
  count                   = var.enable_vercel ? 1 : 0
  name                    = local.vercel_org_id_secret_name
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "vercel_org_id" {
  count         = var.enable_vercel && var.seed_placeholder_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.vercel_org_id[0].id
  secret_string = "REPLACE_ME"
}

resource "aws_secretsmanager_secret" "vercel_project_id" {
  count                   = var.enable_vercel ? 1 : 0
  name                    = local.vercel_project_id_secret_name
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "vercel_project_id" {
  count         = var.enable_vercel && var.seed_placeholder_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.vercel_project_id[0].id
  secret_string = "REPLACE_ME"
}

resource "aws_secretsmanager_secret" "vercel_scope" {
  count                   = var.enable_vercel ? 1 : 0
  name                    = local.vercel_scope_secret_name
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "vercel_scope" {
  count         = var.enable_vercel && var.seed_placeholder_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.vercel_scope[0].id
  secret_string = "REPLACE_ME"
}
