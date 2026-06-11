locals {
  effective_ollama_api_host = trimspace(var.ollama_api_host) != "" ? trimspace(var.ollama_api_host) : (
    var.enable_ollama_host ? "http://${aws_instance.ollama[0].private_ip}:11434" : ""
  )
  effective_gtm_vision_base_url = trimspace(var.gtm_vision_base_url) != "" ? trimspace(var.gtm_vision_base_url) : local.effective_ollama_api_host

  container_environment = concat(
    [
      {
        name  = "HOST"
        value = "0.0.0.0"
      },
      {
        name  = "PORT"
        value = tostring(var.container_port)
      },
      {
        name  = "AUDIT_BROWSER_HEADLESS"
        value = "1"
      },
      {
        name  = "AUDIT_PAGE_CONCURRENCY"
        value = "2"
      },
      {
        name  = "CRAWLER_USE_AI_NAV"
        value = "0"
      },
      {
        name  = "USE_AI_NAV"
        value = "0"
      },
      {
        name  = "GTM_DISABLE_VERCEL_DEPLOY"
        value = var.enable_vercel ? "0" : "1"
      },
      {
        name  = "GTM_AUTO_DEPLOY"
        value = "0"
      },
      {
        name  = "ALLOWED_ORIGIN"
        value = local.allowed_origin
      }
    ],
    var.enable_ai_review ? [
      {
        name  = "AI_REVIEW_BACKEND"
        value = var.ai_review_backend
      },
      {
        name  = "AI_REVIEW_BASE_URL"
        value = var.ai_review_base_url
      },
      {
        name  = "AI_REVIEW_MODEL"
        value = var.ai_review_model
      },
      {
        name  = "AI_REVIEW_TIMEOUT"
        value = tostring(var.ai_review_timeout)
      }
    ] : [],
    [
      {
        name  = "OLLAMA_API_HOST"
        value = local.effective_ollama_api_host
      },
      {
        name  = "OLLAMA_BASE_URL"
        value = local.effective_ollama_api_host
      },
      {
        name  = "OLLAMA_HOST"
        value = local.effective_ollama_api_host
      },
      {
        name  = "OLLAMA_REPORT_MODEL"
        value = var.ollama_report_model
      },
      {
        name  = "OLLAMA_REPORT_POLISH"
        value = var.enable_figma_ai_review && var.ollama_report_polish ? "true" : "false"
      },
      {
        name  = "OLLAMA_AI_REVIEW"
        value = var.enable_figma_ai_review ? "true" : "false"
      },
      {
        name  = "OLLAMA_AI_REVIEW_MODEL"
        value = var.ollama_ai_review_model
      },
      {
        name  = "GTM_VISION_BASE_URL"
        value = local.effective_gtm_vision_base_url
      },
      {
        name  = "GTM_VISION_MODEL"
        value = var.gtm_vision_model
      }
    ]
  )

  container_secrets = concat(
    [
      {
        name      = "FIGMA_TOKEN"
        valueFrom = aws_secretsmanager_secret.figma_token.arn
      }
    ],
    var.enable_ai_review ? [
      {
        name      = "AI_REVIEW_API_KEY"
        valueFrom = aws_secretsmanager_secret.ai_review_api_key.arn
      }
    ] : [],
    var.enable_figma_ai_review ? [
      {
        name      = "OLLAMA_API_KEY"
        valueFrom = aws_secretsmanager_secret.ollama_api_key.arn
      }
    ] : [],
    var.enable_vercel ? [
      {
        name      = "VERCEL_TOKEN"
        valueFrom = aws_secretsmanager_secret.vercel_token[0].arn
      },
      {
        name      = "VERCEL_ORG_ID"
        valueFrom = aws_secretsmanager_secret.vercel_org_id[0].arn
      },
      {
        name      = "VERCEL_PROJECT_ID"
        valueFrom = aws_secretsmanager_secret.vercel_project_id[0].arn
      },
      {
        name      = "VERCEL_SCOPE"
        valueFrom = aws_secretsmanager_secret.vercel_scope[0].arn
      }
    ] : []
  )
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.app_name}-cluster"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = var.public_image_uri
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = local.container_environment
      secrets     = local.container_secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      mountPoints = [
        {
          sourceVolume  = "shared"
          containerPath = "/app/shared"
          readOnly      = false
        }
      ]
    }
  ])

  volume {
    name = "shared"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.shared.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.app.id
      }
    }
  }

  tags = {
    Name = "${var.app_name}-task-def"
  }
}

# ECS Service
resource "aws_ecs_service" "main" {
  name                              = "${var.app_name}-service"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.main.arn
  launch_type                       = "FARGATE"
  desired_count                     = var.desired_count
  enable_execute_command            = true
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  propagate_tags                    = "SERVICE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_efs_mount_target.private_1,
    aws_efs_mount_target.private_2
  ]

  tags = {
    Name = "${var.app_name}-service"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.app_name}-logs"
  }
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.main.name
}
