output "app_domain" {
  value       = var.app_domain
  description = "Your application domain"
}

output "certificate_arn" {
  value       = var.certificate_arn
  description = "ACM certificate ARN used by the ALB"
}

output "alb_dns" {
  value       = aws_lb.main.dns_name
  description = "ALB DNS name (intermediate, use domain instead)"
}

output "public_image_uri" {
  value       = var.public_image_uri
  description = "Public container image URI used by ECS"
}

output "ecs_cluster" {
  value       = aws_ecs_cluster.main.name
  description = "ECS cluster name"
}

output "ecs_service" {
  value       = aws_ecs_service.main.name
  description = "ECS service name"
}

output "secret_names" {
  value = {
    figma_token       = aws_secretsmanager_secret.figma_token.name
    ai_review_api_key = aws_secretsmanager_secret.ai_review_api_key.name
    ollama_api_key    = aws_secretsmanager_secret.ollama_api_key.name
    vercel_token      = var.enable_vercel ? aws_secretsmanager_secret.vercel_token[0].name : null
    vercel_org_id     = var.enable_vercel ? aws_secretsmanager_secret.vercel_org_id[0].name : null
    vercel_project_id = var.enable_vercel ? aws_secretsmanager_secret.vercel_project_id[0].name : null
    vercel_scope      = var.enable_vercel ? aws_secretsmanager_secret.vercel_scope[0].name : null
  }
  description = "Populate these Secrets Manager entries after apply"
}

output "ollama_instance_id" {
  value       = var.enable_ollama_host ? aws_instance.ollama[0].id : null
  description = "EC2 instance ID of the optional Ollama host"
}

output "ollama_private_ip" {
  value       = var.enable_ollama_host ? aws_instance.ollama[0].private_ip : null
  description = "Private IP of the optional Ollama host"
}

output "ollama_api_url" {
  value       = var.enable_ollama_host ? "http://${aws_instance.ollama[0].private_ip}:11434" : null
  description = "Private Ollama-compatible API URL reachable from ECS"
}
