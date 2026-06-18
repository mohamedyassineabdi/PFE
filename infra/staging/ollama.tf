data "aws_ssm_parameter" "ux_ollama_ami" {
  count = var.ux_enable_ollama_host ? 1 : 0
  name  = var.ux_ollama_instance_ami_ssm_parameter
}

resource "aws_security_group" "ux_ollama" {
  count  = var.ux_enable_ollama_host ? 1 : 0
  name   = "${local.name_prefix}-ux-ollama-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 11434
    to_port         = 11434
    protocol        = "tcp"
    security_groups = [aws_security_group.ux_ui_ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ux_ollama" {
  count = var.ux_enable_ollama_host ? 1 : 0
  name  = "${local.name_prefix}-ux-ollama-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ux_ollama_ssm" {
  count      = var.ux_enable_ollama_host ? 1 : 0
  role       = aws_iam_role.ux_ollama[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ux_ollama_secrets" {
  count = var.ux_enable_ollama_host ? 1 : 0
  name  = "${local.name_prefix}-ux-ollama-secrets"
  role  = aws_iam_role.ux_ollama[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.ux_ollama_api_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ux_ollama" {
  count = var.ux_enable_ollama_host ? 1 : 0
  name  = "${local.name_prefix}-ux-ollama-profile"
  role  = aws_iam_role.ux_ollama[0].name
}

resource "aws_instance" "ux_ollama" {
  count                       = var.ux_enable_ollama_host ? 1 : 0
  ami                         = data.aws_ssm_parameter.ux_ollama_ami[0].value
  instance_type               = var.ux_ollama_instance_type
  iam_instance_profile        = aws_iam_instance_profile.ux_ollama[0].name
  subnet_id                   = aws_subnet.public_1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ux_ollama[0].id]

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    dnf update -y
    dnf install -y awscli docker

    systemctl enable --now docker

    mkdir -p /var/lib/ollama
    mkdir -p /etc/ollama

    OLLAMA_API_KEY="$(aws secretsmanager get-secret-value \
      --region ${var.aws_region} \
      --secret-id ${aws_secretsmanager_secret.ux_ollama_api_key.name} \
      --query SecretString \
      --output text || true)"

    printf 'OLLAMA_HOST=0.0.0.0:11434\nOLLAMA_API_KEY=%s\n' "$OLLAMA_API_KEY" >/etc/ollama/ollama.env

    docker rm -f ollama || true

    docker run -d \
      --restart unless-stopped \
      --name ollama \
      --env-file /etc/ollama/ollama.env \
      -p 11434:11434 \
      -v /var/lib/ollama:/root/.ollama \
      ollama/ollama:latest

    # Wait for Ollama to be ready (up to 60s)
    for i in $(seq 1 12); do
      docker exec ollama ollama list >/dev/null 2>&1 && break
      sleep 5
    done

    # Register cloud models (no weights downloaded — SIZE stays "-")
    %{~if var.ux_ollama_bootstrap_model != ""}
    docker exec ollama ollama pull ${var.ux_ollama_bootstrap_model} || true
    %{~endif}
    %{~if var.ux_ai_review_model != "" && var.ux_ai_review_model != var.ux_ollama_bootstrap_model}
    docker exec ollama ollama pull ${var.ux_ai_review_model} || true
    %{~endif}
    %{~if var.ux_gtm_vision_model != "" && var.ux_gtm_vision_model != var.ux_ollama_bootstrap_model && var.ux_gtm_vision_model != var.ux_ai_review_model}
    docker exec ollama ollama pull ${var.ux_gtm_vision_model} || true
    %{~endif}
    %{~if var.ux_ollama_report_model != "" && var.ux_ollama_report_model != var.ux_ollama_bootstrap_model && var.ux_ollama_report_model != var.ux_ai_review_model && var.ux_ollama_report_model != var.ux_gtm_vision_model}
    docker exec ollama ollama pull ${var.ux_ollama_report_model} || true
    %{~endif}
  EOT

  root_block_device {
    volume_size           = var.ux_ollama_root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${local.name_prefix}-ux-ollama"
  }
}
