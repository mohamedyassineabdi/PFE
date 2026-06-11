# EFS File System
resource "aws_efs_file_system" "shared" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "${var.app_name}-efs"
  }
}

# Mount targets in private subnets
resource "aws_efs_mount_target" "private_1" {
  file_system_id  = aws_efs_file_system.shared.id
  subnet_id       = aws_subnet.private_1.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "private_2" {
  file_system_id  = aws_efs_file_system.shared.id
  subnet_id       = aws_subnet.private_2.id
  security_groups = [aws_security_group.efs.id]
}

# Access point for app
resource "aws_efs_access_point" "app" {
  file_system_id = aws_efs_file_system.shared.id
  root_directory {
    path = "/app/shared"
    creation_info {
      owner_gid   = var.app_user_gid
      owner_uid   = var.app_user_uid
      permissions = "0755"
    }
  }
  posix_user {
    gid = var.app_user_gid
    uid = var.app_user_uid
  }

  tags = {
    Name = "${var.app_name}-access-point"
  }
}

output "efs_id" {
  value = aws_efs_file_system.shared.id
}
