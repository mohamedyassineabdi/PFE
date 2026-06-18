locals {
  portal_auth_allowed_origins = compact(distinct([
    local.portal_external_url,
    "http://localhost:8080",
    "http://127.0.0.1:8080",
  ]))

  ux_effective_ollama_api_host = trimspace(var.ux_ollama_api_host) != "" ? trimspace(var.ux_ollama_api_host) : (
    var.ux_enable_ollama_host ? "http://${aws_instance.ux_ollama[0].private_ip}:11434" : ""
  )
  ux_effective_gtm_vision_base_url = trimspace(var.ux_gtm_vision_base_url) != "" ? trimspace(var.ux_gtm_vision_base_url) : local.ux_effective_ollama_api_host

  ux_environment = concat(
    [
      {
        name  = "HOST"
        value = "0.0.0.0"
      },
      {
        name  = "PORT"
        value = tostring(var.ux_ui_container_port)
      },
      {
        name  = "PUBLIC_BASE_PATH"
        value = local.ux_ui_base_path
      },
      {
        name  = "UX_UI_BASE_PATH"
        value = local.ux_ui_base_path
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
        value = var.ux_enable_vercel ? "0" : "1"
      },
      {
        name  = "GTM_AUTO_DEPLOY"
        value = "0"
      },
      {
        name  = "ALLOWED_ORIGIN"
        value = local.ux_ui_url
      }
    ],
    var.ux_enable_ai_review ? [
      {
        name  = "AI_REVIEW_BACKEND"
        value = var.ux_ai_review_backend
      },
      {
        name  = "AI_REVIEW_BASE_URL"
        value = var.ux_ai_review_backend == "ollama" && trimspace(var.ux_ai_review_base_url) == "" ? local.ux_effective_ollama_api_host : var.ux_ai_review_base_url
      },
      {
        name  = "AI_REVIEW_MODEL"
        value = var.ux_ai_review_model
      },
      {
        name  = "AI_REVIEW_TIMEOUT"
        value = tostring(var.ux_ai_review_timeout)
      }
    ] : [],
    [
      {
        name  = "OLLAMA_API_HOST"
        value = local.ux_effective_ollama_api_host
      },
      {
        name  = "OLLAMA_BASE_URL"
        value = local.ux_effective_ollama_api_host
      },
      {
        name  = "OLLAMA_HOST"
        value = local.ux_effective_ollama_api_host
      },
      {
        name  = "OLLAMA_REPORT_MODEL"
        value = var.ux_ollama_report_model
      },
      {
        name  = "OLLAMA_REPORT_POLISH"
        value = var.ux_enable_figma_ai_review && var.ux_ollama_report_polish ? "true" : "false"
      },
      {
        name  = "OLLAMA_AI_REVIEW"
        value = var.ux_enable_figma_ai_review ? "true" : "false"
      },
      {
        name  = "OLLAMA_AI_REVIEW_MODEL"
        value = var.ux_ollama_ai_review_model
      },
      {
        name  = "GTM_VISION_BASE_URL"
        value = local.ux_effective_gtm_vision_base_url
      },
      {
        name  = "GTM_VISION_MODEL"
        value = var.ux_gtm_vision_model
      }
    ]
  )

  ux_secrets = concat(
    [
      {
        name      = "FIGMA_TOKEN"
        valueFrom = aws_secretsmanager_secret.ux_figma_token.arn
      }
    ],
    var.ux_enable_ai_review ? [
      {
        name      = "AI_REVIEW_API_KEY"
        valueFrom = var.ux_ai_review_backend == "ollama" ? aws_secretsmanager_secret.ux_ollama_api_key.arn : aws_secretsmanager_secret.ux_ai_review_api_key.arn
      }
    ] : [],
    var.ux_enable_figma_ai_review || (var.ux_enable_ai_review && var.ux_ai_review_backend == "ollama") ? [
      {
        name      = "OLLAMA_API_KEY"
        valueFrom = aws_secretsmanager_secret.ux_ollama_api_key.arn
      }
    ] : [],
    var.ux_enable_vercel ? [
      {
        name      = "VERCEL_TOKEN"
        valueFrom = aws_secretsmanager_secret.ux_vercel_token[0].arn
      },
      {
        name      = "VERCEL_ORG_ID"
        valueFrom = aws_secretsmanager_secret.ux_vercel_org_id[0].arn
      },
      {
        name      = "VERCEL_PROJECT_ID"
        valueFrom = aws_secretsmanager_secret.ux_vercel_project_id[0].arn
      },
      {
        name      = "VERCEL_SCOPE"
        valueFrom = aws_secretsmanager_secret.ux_vercel_scope[0].arn
      }
    ] : []
  )

  cx_backend_environment = concat(
    [
      {
        name  = "APP_ENV"
        value = var.cx_app_env
      },
      {
        name  = "APP_NAME"
        value = var.cx_app_name
      },
      {
        name  = "CORS_ALLOWED_ORIGINS"
        value = join(",", local.cx_cors_allowed_origins)
      },
      {
        name  = "MISTRAL_MODEL"
        value = var.cx_mistral_model
      },
      {
        name  = "MISTRAL_BASE_URL"
        value = var.cx_mistral_base_url
      },
      {
        name  = "LANGSEARCH_BASE_URL"
        value = var.cx_langsearch_base_url
      },
      {
        name  = "RUN_DB_MIGRATIONS_ON_STARTUP"
        value = "0"
      }
    ],
    var.cx_metabase_dashboard_id != "" ? [
      {
        name  = "METABASE_DASHBOARD_ID"
        value = var.cx_metabase_dashboard_id
      }
    ] : []
  )

  cx_backend_secrets = [
    {
      name      = "DATABASE_URL"
      valueFrom = aws_secretsmanager_secret.cx_database_url.arn
    },
    {
      name      = "MISTRAL_API_KEY"
      valueFrom = aws_secretsmanager_secret.cx_mistral_api_key.arn
    },
    {
      name      = "LANGSEARCH_API_KEY"
      valueFrom = aws_secretsmanager_secret.cx_langsearch_api_key.arn
    },
    {
      name      = "CONSULTATION_RECEIVER_EMAIL"
      valueFrom = aws_secretsmanager_secret.cx_consultation_receiver_email.arn
    },
    {
      name      = "METABASE_SITE_URL"
      valueFrom = aws_secretsmanager_secret.cx_metabase_site_url.arn
    },
    {
      name      = "METABASE_EMBED_SECRET"
      valueFrom = aws_secretsmanager_secret.cx_metabase_embed_secret.arn
    }
  ]
}

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "portal" {
  name              = "/ecs/${local.name_prefix}/portal"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "portal_auth" {
  name              = "/ecs/${local.name_prefix}/portal-auth"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "ux_ui" {
  name              = "/ecs/${local.name_prefix}/ux-ui"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "cx_frontend" {
  name              = "/ecs/${local.name_prefix}/cx-frontend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "cx_backend" {
  name              = "/ecs/${local.name_prefix}/cx-backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "metabase" {
  count             = var.metabase_enabled ? 1 : 0
  name              = "/ecs/${local.name_prefix}/metabase"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "portal" {
  family                   = "${local.name_prefix}-portal"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.portal_container_cpu
  memory                   = var.portal_container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "portal"
      image     = var.portal_image_uri
      essential = true
      portMappings = [
        {
          containerPort = var.portal_container_port
          hostPort      = var.portal_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "PORTAL_API_BASE"
          value = var.portal_api_base_url
        },
        {
          name  = "PORTAL_UX_UI_URL"
          value = local.ux_ui_url
        },
        {
          name  = "PORTAL_CX_URL"
          value = local.cx_url
        },
        {
          name  = "PORTAL_CX_ADMIN_URL"
          value = local.cx_admin_url
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.portal.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "portal_auth" {
  family                   = "${local.name_prefix}-portal-auth"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.portal_auth_container_cpu
  memory                   = var.portal_auth_container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "portal-auth"
      image     = var.portal_auth_image_uri
      essential = true
      portMappings = [
        {
          containerPort = var.portal_auth_container_port
          hostPort      = var.portal_auth_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "PORT"
          value = tostring(var.portal_auth_container_port)
        },
        {
          name  = "PORTAL_AUTH_DB_PATH"
          value = "/data/portal-auth.db"
        },
        {
          name  = "PORTAL_AUTH_PUBLIC_BASE_URL"
          value = local.portal_external_url
        },
        {
          name  = "PORTAL_AUTH_SESSION_TTL_HOURS"
          value = tostring(var.portal_auth_session_ttl_hours)
        },
        {
          name  = "PORTAL_AUTH_INVITE_TTL_HOURS"
          value = tostring(var.portal_auth_invite_ttl_hours)
        },
        {
          name  = "PORTAL_AUTH_ALLOWED_ORIGINS"
          value = join(",", local.portal_auth_allowed_origins)
        }
      ]
      secrets = [
        {
          name      = "PORTAL_AUTH_BOOTSTRAP_ADMIN_EMAIL"
          valueFrom = aws_secretsmanager_secret.portal_auth_admin_email.arn
        },
        {
          name      = "PORTAL_AUTH_BOOTSTRAP_ADMIN_PASSWORD"
          valueFrom = aws_secretsmanager_secret.portal_auth_admin_password.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.portal_auth.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      mountPoints = [
        {
          sourceVolume  = "data"
          containerPath = "/data"
          readOnly      = false
        }
      ]
    }
  ])

  volume {
    name = "data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.ux_ui_shared.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.portal_auth.id
      }
    }
  }
}

resource "aws_ecs_task_definition" "ux_ui" {
  family                   = "${local.name_prefix}-ux-ui"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ux_ui_container_cpu
  memory                   = var.ux_ui_container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "ux-ui"
      image     = var.ux_ui_image_uri
      essential = true
      portMappings = [
        {
          containerPort = var.ux_ui_container_port
          hostPort      = var.ux_ui_container_port
          protocol      = "tcp"
        }
      ]
      environment = local.ux_environment
      secrets     = local.ux_secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ux_ui.name
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
      file_system_id     = aws_efs_file_system.ux_ui_shared.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.ux_ui.id
      }
    }
  }
}

resource "aws_ecs_task_definition" "cx_frontend" {
  family                   = "${local.name_prefix}-cx-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cx_frontend_container_cpu
  memory                   = var.cx_frontend_container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "cx-frontend"
      image     = var.cx_frontend_image_uri
      essential = true
      portMappings = [
        {
          containerPort = var.cx_frontend_container_port
          hostPort      = var.cx_frontend_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "CX_API_BASE_URL"
          value = local.cx_frontend_api_base_url
        },
        {
          name  = "CX_FRONTEND_BASE_PATH"
          value = local.cx_frontend_base_path
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cx_frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "cx_backend" {
  family                   = "${local.name_prefix}-cx-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cx_backend_container_cpu
  memory                   = var.cx_backend_container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "cx-backend"
      image     = var.cx_backend_image_uri
      essential = true
      portMappings = [
        {
          containerPort = var.cx_backend_container_port
          hostPort      = var.cx_backend_container_port
          protocol      = "tcp"
        }
      ]
      environment = local.cx_backend_environment
      secrets     = local.cx_backend_secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cx_backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "cx_backend_migrate" {
  family                   = "${local.name_prefix}-cx-backend-migrate"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cx_backend_container_cpu
  memory                   = var.cx_backend_container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name        = "cx-backend-migrate"
      image       = var.cx_backend_image_uri
      essential   = true
      command     = ["python", "-m", "app.db.migrate"]
      environment = local.cx_backend_environment
      secrets     = local.cx_backend_secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cx_backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "migration"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "metabase" {
  count                    = var.metabase_enabled ? 1 : 0
  family                   = "${local.name_prefix}-metabase"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.metabase_container_cpu
  memory                   = var.metabase_container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "metabase"
      image     = var.metabase_image_uri
      essential = true
      portMappings = [
        {
          containerPort = var.metabase_container_port
          hostPort      = var.metabase_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "MB_SITE_URL"
          value = local.metabase_external_url
        },
        {
          name  = "MB_JETTY_PORT"
          value = tostring(var.metabase_container_port)
        },
        {
          name  = "MB_DB_TYPE"
          value = "h2"
        },
        {
          name  = "MB_DB_FILE"
          value = "/metabase-data/metabase.db"
        },
        {
          name  = "MB_ENABLE_EMBEDDING_STATIC"
          value = "true"
        },
        {
          name  = "MB_SHOW_STATIC_EMBED_TERMS"
          value = "false"
        }
      ]
      secrets = [
        {
          name      = "MB_EMBEDDING_SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.cx_metabase_embed_secret.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.metabase[0].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      mountPoints = [
        {
          sourceVolume  = "data"
          containerPath = "/metabase-data"
          readOnly      = false
        }
      ]
    }
  ])

  volume {
    name = "data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.ux_ui_shared.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.metabase.id
      }
    }
  }
}

resource "aws_ecs_service" "portal" {
  name                              = "${local.name_prefix}-portal"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.portal.arn
  launch_type                       = "FARGATE"
  desired_count                     = var.portal_desired_count
  enable_execute_command            = true
  health_check_grace_period_seconds = var.portal_health_check_grace_period_seconds
  propagate_tags                    = "SERVICE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.portal_ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.portal.arn
    container_name   = "portal"
    container_port   = var.portal_container_port
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_ecs_service" "portal_auth" {
  name                              = "${local.name_prefix}-portal-auth"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.portal_auth.arn
  launch_type                       = "FARGATE"
  desired_count                     = var.portal_auth_desired_count
  enable_execute_command            = true
  health_check_grace_period_seconds = var.portal_auth_health_check_grace_period_seconds
  propagate_tags                    = "SERVICE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.portal_auth_ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.portal_auth.arn
    container_name   = "portal-auth"
    container_port   = var.portal_auth_container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener_rule.portal_auth,
    aws_lb_listener_rule.portal_auth_fallback,
    aws_efs_mount_target.ux_ui_private_1,
    aws_efs_mount_target.ux_ui_private_2,
  ]
}

resource "aws_ecs_service" "ux_ui" {
  name                              = "${local.name_prefix}-ux-ui"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.ux_ui.arn
  launch_type                       = "FARGATE"
  desired_count                     = var.ux_ui_desired_count
  enable_execute_command            = true
  health_check_grace_period_seconds = var.ux_ui_health_check_grace_period_seconds
  propagate_tags                    = "SERVICE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ux_ui_ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ux_ui.arn
    container_name   = "ux-ui"
    container_port   = var.ux_ui_container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener_rule.ux_ui,
    aws_lb_listener_rule.ux_ui_fallback,
    aws_efs_mount_target.ux_ui_private_1,
    aws_efs_mount_target.ux_ui_private_2,
  ]
}

resource "aws_ecs_service" "cx_frontend" {
  name                              = "${local.name_prefix}-cx-frontend"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.cx_frontend.arn
  launch_type                       = "FARGATE"
  desired_count                     = var.cx_frontend_desired_count
  enable_execute_command            = true
  health_check_grace_period_seconds = var.cx_frontend_health_check_grace_period_seconds
  propagate_tags                    = "SERVICE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.cx_frontend_ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.cx_frontend.arn
    container_name   = "cx-frontend"
    container_port   = var.cx_frontend_container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener_rule.cx_frontend,
    aws_lb_listener_rule.cx_frontend_fallback,
  ]
}

resource "aws_ecs_service" "cx_backend" {
  name                              = "${local.name_prefix}-cx-backend"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.cx_backend.arn
  launch_type                       = "FARGATE"
  desired_count                     = var.cx_backend_desired_count
  enable_execute_command            = true
  health_check_grace_period_seconds = var.cx_backend_health_check_grace_period_seconds
  propagate_tags                    = "SERVICE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.cx_backend_ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.cx_backend.arn
    container_name   = "cx-backend"
    container_port   = var.cx_backend_container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener_rule.cx_backend_on_cx_domain,
    aws_lb_listener_rule.cx_backend_api_domain,
    aws_lb_listener_rule.cx_backend_fallback,
  ]
}

resource "aws_ecs_service" "metabase" {
  count                             = var.metabase_enabled ? 1 : 0
  name                              = "${local.name_prefix}-metabase"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.metabase[0].arn
  launch_type                       = "FARGATE"
  desired_count                     = var.metabase_desired_count
  enable_execute_command            = true
  health_check_grace_period_seconds = var.metabase_health_check_grace_period_seconds
  propagate_tags                    = "SERVICE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.metabase_ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.metabase[0].arn
    container_name   = "metabase"
    container_port   = var.metabase_container_port
  }

  depends_on = [
    aws_lb_listener.metabase,
    aws_efs_mount_target.ux_ui_private_1,
    aws_efs_mount_target.ux_ui_private_2,
  ]
}
