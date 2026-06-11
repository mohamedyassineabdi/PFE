data "aws_ssm_parameter" "ollama_ami" {
  count = var.enable_ollama_host ? 1 : 0
  name  = var.ollama_instance_ami_ssm_parameter
}

resource "aws_security_group" "ollama" {
  count  = var.enable_ollama_host ? 1 : 0
  name   = "${var.app_name}-ollama-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 11434
    to_port         = 11434
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-ollama-sg"
  }
}

resource "aws_iam_role" "ollama" {
  count = var.enable_ollama_host ? 1 : 0
  name  = "${local.name_prefix}-ollama-role"

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

resource "aws_iam_role_policy_attachment" "ollama_ssm" {
  count      = var.enable_ollama_host ? 1 : 0
  role       = aws_iam_role.ollama[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ollama_secrets" {
  count = var.enable_ollama_host ? 1 : 0
  name  = "${local.name_prefix}-ollama-secrets"
  role  = aws_iam_role.ollama[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.ollama_api_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ollama" {
  count = var.enable_ollama_host ? 1 : 0
  name  = "${local.name_prefix}-ollama-profile"
  role  = aws_iam_role.ollama[0].name
}

resource "aws_instance" "ollama" {
  count                  = var.enable_ollama_host ? 1 : 0
  ami                    = data.aws_ssm_parameter.ollama_ami[0].value
  instance_type          = var.ollama_instance_type
  iam_instance_profile   = aws_iam_instance_profile.ollama[0].name
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.ollama[0].id]

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
      --secret-id ${aws_secretsmanager_secret.ollama_api_key.name} \
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
  EOT

  root_block_device {
    volume_size           = var.ollama_root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${local.name_prefix}-ollama"
  }
}
