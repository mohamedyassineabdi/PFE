resource "aws_security_group" "cx_rds" {
  count  = var.create_cx_rds ? 1 : 0
  name   = "${local.name_prefix}-cx-rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      aws_security_group.cx_backend_ecs.id,
      aws_security_group.metabase_ecs.id,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "cx" {
  count      = var.create_cx_rds ? 1 : 0
  name       = "${local.name_prefix}-cx-db"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_db_instance" "cx" {
  count                      = var.create_cx_rds ? 1 : 0
  identifier                 = "${local.name_prefix}-cx-db"
  engine                     = "postgres"
  engine_version             = var.cx_db_engine_version
  instance_class             = var.cx_db_instance_class
  allocated_storage          = var.cx_db_allocated_storage
  max_allocated_storage      = var.cx_db_allocated_storage + 20
  storage_type               = "gp3"
  storage_encrypted          = true
  db_name                    = var.cx_db_name
  username                   = var.cx_db_username
  password                   = var.cx_db_password
  port                       = 5432
  db_subnet_group_name       = aws_db_subnet_group.cx[0].name
  vpc_security_group_ids     = [aws_security_group.cx_rds[0].id]
  publicly_accessible        = false
  multi_az                   = var.cx_db_multi_az
  skip_final_snapshot        = var.cx_db_skip_final_snapshot
  final_snapshot_identifier  = var.cx_db_skip_final_snapshot ? null : "${local.name_prefix}-cx-db-final"
  backup_retention_period    = var.cx_db_backup_retention_days
  deletion_protection        = false
  auto_minor_version_upgrade = true
  apply_immediately          = true
}
