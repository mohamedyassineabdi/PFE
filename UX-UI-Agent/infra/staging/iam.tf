# ECS Task Execution Role (for ECS to pull images, write logs)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets_policy" {
  name = "${var.app_name}-ecsTaskExecutionSecretsPolicy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = compact([
          aws_secretsmanager_secret.figma_token.arn,
          aws_secretsmanager_secret.ai_review_api_key.arn,
          aws_secretsmanager_secret.ollama_api_key.arn,
          var.enable_vercel ? aws_secretsmanager_secret.vercel_token[0].arn : "",
          var.enable_vercel ? aws_secretsmanager_secret.vercel_org_id[0].arn : "",
          var.enable_vercel ? aws_secretsmanager_secret.vercel_project_id[0].arn : "",
          var.enable_vercel ? aws_secretsmanager_secret.vercel_scope[0].arn : ""
        ])
      }
    ]
  })
}

# Task Role (for app to access resources)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.app_name}-ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for EFS access
resource "aws_iam_role_policy" "ecs_task_efs_policy" {
  name = "${var.app_name}-ecsTaskEfsPolicy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRead"
        ]
        Resource = aws_efs_file_system.shared.arn
        Condition = {
          StringEquals = {
            "elasticfilesystem:AccessPointArn" = aws_efs_access_point.app.arn
          }
        }
      }
    ]
  })
}
