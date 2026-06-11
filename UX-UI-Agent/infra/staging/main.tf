locals {
  name_prefix        = "${var.app_name}-${var.environment}"
  secret_name_prefix = "${var.app_name}/${var.environment}"
  allowed_origin     = var.app_domain != "" ? format("%s://%s", var.certificate_arn != "" ? "https" : "http", var.app_domain) : ""
}
