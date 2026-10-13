data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
data "aws_ami" "al2023" {
  owners = ["amazon"]
  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.al2023.value]
  }
}
resource "aws_security_group" "web" {
  name_prefix = "${var.name}-web-"
  description = "nginx HTTP from ALB only"
  vpc_id      = var.vpc_id
}
resource "aws_vpc_security_group_egress_rule" "web" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
module "alb" {
  source            = "../modules/alb"
  name              = var.name
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  backend_sg_id     = aws_security_group.web.id
  backend_port      = 80
  allowed_cidrs     = var.http_allowed_cidrs
}
resource "aws_launch_template" "web" {
  name_prefix            = "${var.name}-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data = base64encode(templatefile("${path.module}/user-data.sh.tftpl", {
    nginx_image = var.nginx_image
  }))
  block_device_mappings {
    device_name = data.aws_ami.al2023.root_device_name
    ebs {
      volume_size           = 10
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name}-web" }
  }
  tag_specifications {
    resource_type = "volume"
    tags          = { Name = "${var.name}-root" }
  }
}
resource "aws_autoscaling_group" "web" {
  name                      = var.name
  min_size                  = 1
  desired_capacity          = 1
  max_size                  = 2
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [module.alb.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 600
  launch_template {
    id      = aws_launch_template.web.id
    version = tostring(aws_launch_template.web.latest_version)
  }
  tag {
    key                 = "Name"
    value               = "${var.name}-web"
    propagate_at_launch = true
  }
  depends_on = [module.alb, aws_vpc_security_group_egress_rule.web]
}
output "nginx_url" { value = module.alb.url }
output "asg_name" { value = aws_autoscaling_group.web.name }
output "target_group_arn" { value = module.alb.target_group_arn }
