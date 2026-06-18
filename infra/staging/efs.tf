resource "aws_efs_file_system" "ux_ui_shared" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "${local.name_prefix}-ux-ui-efs"
  }
}

resource "aws_efs_mount_target" "ux_ui_private_1" {
  file_system_id  = aws_efs_file_system.ux_ui_shared.id
  subnet_id       = aws_subnet.private_1.id
  security_groups = [aws_security_group.ux_ui_efs.id]
}

resource "aws_efs_mount_target" "ux_ui_private_2" {
  file_system_id  = aws_efs_file_system.ux_ui_shared.id
  subnet_id       = aws_subnet.private_2.id
  security_groups = [aws_security_group.ux_ui_efs.id]
}

resource "aws_efs_access_point" "ux_ui" {
  file_system_id = aws_efs_file_system.ux_ui_shared.id

  root_directory {
    path = "/app/shared"

    creation_info {
      owner_gid   = var.ux_app_user_gid
      owner_uid   = var.ux_app_user_uid
      permissions = "0755"
    }
  }

  posix_user {
    gid = var.ux_app_user_gid
    uid = var.ux_app_user_uid
  }

  tags = {
    Name = "${local.name_prefix}-ux-ui-access-point"
  }
}

resource "aws_efs_access_point" "portal_auth" {
  file_system_id = aws_efs_file_system.ux_ui_shared.id

  root_directory {
    path = "/portal-auth"

    creation_info {
      owner_gid   = var.ux_app_user_gid
      owner_uid   = var.ux_app_user_uid
      permissions = "0755"
    }
  }

  posix_user {
    gid = var.ux_app_user_gid
    uid = var.ux_app_user_uid
  }

  tags = {
    Name = "${local.name_prefix}-portal-auth-access-point"
  }
}

resource "aws_efs_access_point" "metabase" {
  file_system_id = aws_efs_file_system.ux_ui_shared.id

  root_directory {
    path = "/metabase"

    creation_info {
      owner_gid   = var.ux_app_user_gid
      owner_uid   = var.ux_app_user_uid
      permissions = "0775"
    }
  }

  posix_user {
    gid = var.ux_app_user_gid
    uid = var.ux_app_user_uid
  }

  tags = {
    Name = "${local.name_prefix}-metabase-access-point"
  }
}
