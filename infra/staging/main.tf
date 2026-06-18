locals {
  name_prefix        = "${var.app_name}-${var.environment}"
  secret_name_prefix = "${var.app_name}/${var.environment}"
  use_https          = trimspace(var.certificate_arn) != ""
  protocol           = local.use_https ? "https" : "http"

  portal_url            = var.portal_domain != "" ? "${local.protocol}://${var.portal_domain}" : ""
  portal_external_url   = local.portal_url != "" ? local.portal_url : "${local.protocol}://${aws_lb.main.dns_name}"
  ux_ui_base_path       = var.ux_ui_domain != "" ? "" : "/ux-ui"
  ux_ui_url             = var.ux_ui_domain != "" ? "${local.protocol}://${var.ux_ui_domain}" : "${local.portal_external_url}${local.ux_ui_base_path}"
  cx_frontend_base_path = var.cx_domain != "" ? "" : "/cx"
  cx_url                = var.cx_domain != "" ? "${local.protocol}://${var.cx_domain}" : "${local.portal_external_url}${local.cx_frontend_base_path}/"
  cx_api_url            = var.cx_api_domain != "" ? "${local.protocol}://${var.cx_api_domain}/api/v1" : ""
  cx_api_public_url     = local.cx_api_url != "" ? local.cx_api_url : "${local.portal_external_url}/api/v1"
  metabase_port_suffix  = var.metabase_alb_listener_port == (local.use_https ? 443 : 80) ? "" : ":${var.metabase_alb_listener_port}"
  metabase_external_url = var.metabase_enabled ? "${local.protocol}://${aws_lb.main.dns_name}${local.metabase_port_suffix}" : ""

  cx_frontend_api_base_url = local.cx_api_url != "" ? local.cx_api_url : (
    var.cx_domain != "" ? "${local.cx_url}/api/v1" : "/api/v1"
  )
  cx_admin_url = var.cx_domain != "" ? "${local.cx_url}/admin" : "${local.portal_external_url}${local.cx_frontend_base_path}/admin"

  cx_cors_allowed_origins = compact(distinct([
    local.portal_external_url,
    local.cx_url,
    "http://localhost:5173",
    "http://127.0.0.1:5173",
  ]))

  active_listener_arn = local.use_https ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
}
