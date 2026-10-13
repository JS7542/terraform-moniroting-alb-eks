variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "backend_sg_id" { type = string }
variable "backend_port" { type = number }
variable "allowed_cidrs" { type = set(string) }

resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  description = "Public HTTP entry point for nginx"
  vpc_id      = var.vpc_id
}
resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each          = var.allowed_cidrs
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_egress_rule" "backend" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = var.backend_sg_id
  ip_protocol                  = "tcp"
  from_port                    = var.backend_port
  to_port                      = var.backend_port
}
resource "aws_vpc_security_group_ingress_rule" "backend" {
  security_group_id            = var.backend_sg_id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.backend_port
  to_port                      = var.backend_port
}
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  depends_on         = [aws_vpc_security_group_ingress_rule.http, aws_vpc_security_group_egress_rule.backend]
}
resource "aws_lb_target_group" "nginx" {
  name_prefix          = "nginx-"
  port                 = var.backend_port
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = var.vpc_id
  deregistration_delay = 30
  health_check {
    path                = "/"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  lifecycle { create_before_destroy = true }
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}
output "url" { value = "http://${aws_lb.this.dns_name}" }
output "target_group_arn" { value = aws_lb_target_group.nginx.arn }
