locals {
  namespace = jsonencode({
    apiVersion = "v1", kind = "Namespace", metadata = { name = "nginx" }
  })
  manifest = templatefile("${path.module}/nginx.yaml.tftpl", { nginx_image = var.nginx_image })
  connection = {
    region   = "eu-north-1"
    name     = var.cluster_name
    endpoint = var.cluster_endpoint
    ca       = var.cluster_ca
  }
}

# Run CLI operations only after EKS and its managed node group are ready.
# No Kubernetes provider connects to a nonexistent cluster during planning.
resource "terraform_data" "namespace" {
  input = {
    connection     = jsonencode(local.connection)
    manifest       = local.namespace
    python_command = var.python_command
    script_path    = abspath("${path.module}/deploy.py")
  }
  triggers_replace = [var.cluster_endpoint, var.cluster_name]
  provisioner "local-exec" {
    interpreter = [self.input.python_command, self.input.script_path]
    command     = "namespace"
    environment = {
      EKS_CONNECTION = self.input.connection
      NGINX_MANIFEST = self.input.manifest
    }
  }
  provisioner "local-exec" {
    when        = destroy
    interpreter = [self.input.python_command, self.input.script_path]
    command     = "delete"
    environment = {
      EKS_CONNECTION = self.input.connection
      NGINX_MANIFEST = self.input.manifest
    }
  }
}
resource "terraform_data" "nginx" {
  input = {
    connection     = jsonencode(local.connection)
    manifest       = local.manifest
    python_command = var.python_command
    script_path    = abspath("${path.module}/deploy.py")
  }
  triggers_replace = [
    sha256(local.manifest), filesha256("${path.module}/deploy.py"),
    var.cluster_endpoint, var.python_command
  ]
  provisioner "local-exec" {
    interpreter = [self.input.python_command, self.input.script_path]
    command     = "apply"
    environment = {
      EKS_CONNECTION = self.input.connection
      NGINX_MANIFEST = self.input.manifest
    }
  }
  depends_on = [terraform_data.namespace]
}
module "alb" {
  source            = "../modules/alb"
  name              = var.name
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  backend_sg_id     = var.node_security_group_id
  backend_port      = 30080
  allowed_cidrs     = var.http_allowed_cidrs
}
resource "aws_autoscaling_attachment" "nginx" {
  autoscaling_group_name = var.node_asg_name
  lb_target_group_arn    = module.alb.target_group_arn
  depends_on             = [terraform_data.nginx, module.alb]
}
output "nginx_url" { value = module.alb.url }
output "target_group_arn" { value = module.alb.target_group_arn }
