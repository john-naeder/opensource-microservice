# ============================================================================
# Application Load Balancer
# ============================================================================

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Groups for each service
resource "aws_lb_target_group" "user_service" {
  name     = "${var.project_name}-user-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-user-tg"
  }
}

resource "aws_lb_target_group" "product_service" {
  name     = "${var.project_name}-product-tg"
  port     = 8082
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-product-tg"
  }
}

resource "aws_lb_target_group" "transaction_service" {
  name     = "${var.project_name}-transaction-tg"
  port     = 8083
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-transaction-tg"
  }
}

resource "aws_lb_target_group" "wallet_service" {
  name     = "${var.project_name}-wallet-tg"
  port     = 8084
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-wallet-tg"
  }
}

resource "aws_lb_target_group" "notify_service" {
  name     = "${var.project_name}-notify-tg"
  port     = 8085
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-notify-tg"
  }
}

resource "aws_lb_target_group" "chat_core_service" {
  name     = "${var.project_name}-chat-core-tg"
  port     = 8091
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-chat-core-tg"
  }
}

resource "aws_lb_target_group" "chat_fanout_service" {
  name     = "${var.project_name}-chat-fanout-tg"
  port     = 8092
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-chat-fanout-tg"
  }
}

resource "aws_lb_target_group" "chat_socket_service" {
  name     = "${var.project_name}-chat-socket-tg"
  port     = 8093
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-chat-socket-tg"
  }
}

# HTTP Listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener with host-based routing
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Service not found"
      status_code  = "404"
    }
  }
}

# Listener Rules for path-based routing
resource "aws_lb_listener_rule" "user_service" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/users/*", "/api/auth/*"]
    }
  }
}

resource "aws_lb_listener_rule" "product_service" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.product_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/products/*", "/api/categories/*", "/api/search/*"]
    }
  }
}

resource "aws_lb_listener_rule" "transaction_service" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.transaction_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/transactions/*", "/api/orders/*"]
    }
  }
}

resource "aws_lb_listener_rule" "wallet_service" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 400

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wallet_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/wallet/*", "/api/payments/*"]
    }
  }
}

resource "aws_lb_listener_rule" "notify_service" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 500

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.notify_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/notifications/*"]
    }
  }
}

resource "aws_lb_listener_rule" "chat_core_service" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 600

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chat_core_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/chat/*", "/api/messages/*"]
    }
  }
}

resource "aws_lb_listener_rule" "chat_fanout_service" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 700

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chat_fanout_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/fanout/*"]
    }
  }
}

resource "aws_lb_listener_rule" "chat_socket_service" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 800

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chat_socket_service.arn
  }

  condition {
    path_pattern {
      values = ["/ws/*", "/socket/*"]
    }
  }
}
