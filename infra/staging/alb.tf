resource "aws_lb" "main" {
  name                       = "${var.app_name}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  drop_invalid_header_fields = true

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "portal" {
  name        = substr("${local.name_prefix}-portal-tg", 0, 32)
  port        = var.portal_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/healthz"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "portal_auth" {
  name        = substr("${local.name_prefix}-portal-auth-tg", 0, 32)
  port        = var.portal_auth_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/healthz"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "ux_ui" {
  name        = substr("${local.name_prefix}-ux-ui-tg", 0, 32)
  port        = var.ux_ui_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "cx_frontend" {
  name        = substr("${local.name_prefix}-cx-frontend-tg", 0, 32)
  port        = var.cx_frontend_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/healthz"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "cx_backend" {
  name        = substr("${local.name_prefix}-cx-backend-tg", 0, 32)
  port        = var.cx_backend_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/api/v1/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "metabase" {
  count       = var.metabase_enabled ? 1 : 0
  name        = substr("${local.name_prefix}-metabase-tg", 0, 32)
  port        = var.metabase_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = local.use_https ? "redirect" : "forward"
    target_group_arn = local.use_https ? null : aws_lb_target_group.portal.arn

    dynamic "redirect" {
      for_each = local.use_https ? [1] : []

      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = local.use_https ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.portal.arn
  }
}

resource "aws_lb_listener" "metabase" {
  count             = var.metabase_enabled ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = var.metabase_alb_listener_port
  protocol          = local.use_https ? "HTTPS" : "HTTP"
  ssl_policy        = local.use_https ? "ELBSecurityPolicy-TLS13-1-2-2021-06" : null
  certificate_arn   = local.use_https ? var.certificate_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.metabase[0].arn
  }
}

resource "aws_lb_listener_rule" "cx_backend_on_cx_domain" {
  count        = var.cx_domain != "" ? 1 : 0
  listener_arn = local.active_listener_arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cx_backend.arn
  }

  condition {
    host_header {
      values = [var.cx_domain]
    }
  }

  condition {
    path_pattern {
      values = ["/api", "/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "cx_backend_api_domain" {
  count        = var.cx_api_domain != "" ? 1 : 0
  listener_arn = local.active_listener_arn
  priority     = 11

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cx_backend.arn
  }

  condition {
    host_header {
      values = [var.cx_api_domain]
    }
  }
}

resource "aws_lb_listener_rule" "cx_backend_fallback" {
  count        = var.cx_domain == "" && var.cx_api_domain == "" ? 1 : 0
  listener_arn = local.active_listener_arn
  priority     = 12

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cx_backend.arn
  }

  condition {
    path_pattern {
      values = ["/api", "/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "ux_ui" {
  count        = var.ux_ui_domain != "" ? 1 : 0
  listener_arn = local.active_listener_arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ux_ui.arn
  }

  condition {
    host_header {
      values = [var.ux_ui_domain]
    }
  }
}

resource "aws_lb_listener_rule" "ux_ui_fallback" {
  count        = var.ux_ui_domain == "" ? 1 : 0
  listener_arn = local.active_listener_arn
  priority     = 9

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ux_ui.arn
  }

  condition {
    path_pattern {
      values = [
        "/ux-ui*",
        "/api/audits*",
        "/audits*",
        "/artifacts*"
      ]
    }
  }
}

resource "aws_lb_listener_rule" "cx_frontend" {
  count        = var.cx_domain != "" ? 1 : 0
  listener_arn = local.active_listener_arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cx_frontend.arn
  }

  condition {
    host_header {
      values = [var.cx_domain]
    }
  }
}

resource "aws_lb_listener_rule" "cx_frontend_fallback" {
  count        = var.cx_domain == "" ? 1 : 0
  listener_arn = local.active_listener_arn
  priority     = 31

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cx_frontend.arn
  }

  condition {
    path_pattern {
      values = [
        "/cx*",
        "/admin*",
        "/timeline-preview*"
      ]
    }
  }
}

resource "aws_lb_listener_rule" "portal_auth" {
  count        = var.portal_domain != "" ? 1 : 0
  listener_arn = local.active_listener_arn
  priority     = 39

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.portal_auth.arn
  }

  condition {
    host_header {
      values = [var.portal_domain]
    }
  }

  condition {
    path_pattern {
      values = ["/auth", "/auth/*"]
    }
  }
}

resource "aws_lb_listener_rule" "portal_auth_fallback" {
  count        = var.portal_domain == "" ? 1 : 0
  listener_arn = local.active_listener_arn
  priority     = 39

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.portal_auth.arn
  }

  condition {
    path_pattern {
      values = ["/auth", "/auth/*"]
    }
  }
}

resource "aws_lb_listener_rule" "portal" {
  count        = var.portal_domain != "" ? 1 : 0
  listener_arn = local.active_listener_arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.portal.arn
  }

  condition {
    host_header {
      values = [var.portal_domain]
    }
  }
}

resource "aws_route53_record" "portal" {
  count   = var.route53_zone_id != "" && var.portal_domain != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.portal_domain
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ux_ui" {
  count   = var.route53_zone_id != "" && var.ux_ui_domain != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.ux_ui_domain
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cx" {
  count   = var.route53_zone_id != "" && var.cx_domain != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.cx_domain
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cx_api" {
  count   = var.route53_zone_id != "" && var.cx_api_domain != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.cx_api_domain
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
