output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "Shared ALB DNS name"
}

output "portal_url" {
  value       = local.portal_external_url
  description = "Portal URL, using the custom domain when configured or the ALB DNS name otherwise"
}

output "ux_ui_url" {
  value       = local.ux_ui_url
  description = "UI/UX URL when ux_ui_domain is configured"
}

output "cx_url" {
  value       = local.cx_url
  description = "CX frontend URL when cx_domain is configured"
}

output "cx_api_base_url" {
  value       = local.cx_api_public_url
  description = "Public CX API base URL"
}

output "metabase_url" {
  value       = var.metabase_enabled ? local.metabase_external_url : null
  description = "Metabase URL exposed through the shared ALB when enabled"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "Shared ECS cluster name"
}

output "ecs_service_names" {
  value = {
    portal      = aws_ecs_service.portal.name
    portal_auth = aws_ecs_service.portal_auth.name
    ux_ui       = aws_ecs_service.ux_ui.name
    cx_frontend = aws_ecs_service.cx_frontend.name
    cx_backend  = aws_ecs_service.cx_backend.name
    metabase    = var.metabase_enabled ? aws_ecs_service.metabase[0].name : null
  }
}

output "cx_migration_task_definition_arn" {
  value       = aws_ecs_task_definition.cx_backend_migrate.arn
  description = "Task definition used for one-off CX database migrations"
}

output "cx_backend_subnet_ids" {
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  description = "Subnet IDs used by CX backend and migration tasks"
}

output "cx_backend_security_group_id" {
  value       = aws_security_group.cx_backend_ecs.id
  description = "Security group ID used by CX backend tasks"
}

output "secret_names" {
  value = {
    portal_auth = {
      bootstrap_admin_email    = aws_secretsmanager_secret.portal_auth_admin_email.name
      bootstrap_admin_password = aws_secretsmanager_secret.portal_auth_admin_password.name
    }
    ux_ui = {
      figma_token    = aws_secretsmanager_secret.ux_figma_token.name
      ai_review_key  = aws_secretsmanager_secret.ux_ai_review_api_key.name
      ollama_api_key = aws_secretsmanager_secret.ux_ollama_api_key.name
      vercel_token   = var.ux_enable_vercel ? aws_secretsmanager_secret.ux_vercel_token[0].name : null
      vercel_org_id  = var.ux_enable_vercel ? aws_secretsmanager_secret.ux_vercel_org_id[0].name : null
      vercel_project = var.ux_enable_vercel ? aws_secretsmanager_secret.ux_vercel_project_id[0].name : null
      vercel_scope   = var.ux_enable_vercel ? aws_secretsmanager_secret.ux_vercel_scope[0].name : null
    }
    cx = {
      database_url          = aws_secretsmanager_secret.cx_database_url.name
      mistral_api_key       = aws_secretsmanager_secret.cx_mistral_api_key.name
      langsearch_api_key    = aws_secretsmanager_secret.cx_langsearch_api_key.name
      consultation_receiver = aws_secretsmanager_secret.cx_consultation_receiver_email.name
      metabase_site_url     = aws_secretsmanager_secret.cx_metabase_site_url.name
      metabase_embed_secret = aws_secretsmanager_secret.cx_metabase_embed_secret.name
    }
  }
}

output "rds_endpoint" {
  value       = var.create_cx_rds ? aws_db_instance.cx[0].address : null
  description = "CX PostgreSQL endpoint when create_cx_rds is enabled"
}

output "ux_ui_efs_id" {
  value       = aws_efs_file_system.ux_ui_shared.id
  description = "EFS file system used by the UI/UX app"
}

output "ux_ollama_instance_id" {
  value       = var.ux_enable_ollama_host ? aws_instance.ux_ollama[0].id : null
  description = "Optional Ollama EC2 instance ID"
}
