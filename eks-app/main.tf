locals {
  namespace = jsonencode({
    apiVersion = "v1", kind = "Namespace", metadata = { name = "nginx" }
  })
  manifest = templatefile("${path.module}/nginx.yaml.tftpl", { nginx_image = var.nginx_image })
  kubeconfig = jsonencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{ name = "eks", cluster = {
      server                       = var.cluster_endpoint
      "certificate-authority-data" = var.cluster_ca
    } }]
    users = [{ name = "aws", user = { exec = {
      apiVersion      = "client.authentication.k8s.io/v1beta1"
      command         = "aws"
      args            = ["eks", "get-token", "--region", "eu-north-1", "--cluster-name", var.cluster_name]
      interactiveMode = "Never"
    } } }]
    contexts        = [{ name = "eks", context = { cluster = "eks", user = "aws" } }]
    current-context = "eks"
  })
  shell = var.deployment_shell == "auto" ? (
    can(regex("^[A-Za-z]:", abspath(path.root))) ? "powershell" : "bash"
  ) : var.deployment_shell
  interpreter = local.shell == "powershell" ? [
    "PowerShell", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", abspath("${path.module}/deploy.ps1")
    ] : [
    "bash", abspath("${path.module}/deploy.sh")
  ]
}

# Run CLI operations only after EKS and its managed node group are ready.
# No Kubernetes provider connects to a nonexistent cluster during planning.
resource "terraform_data" "namespace" {
  input = {
    kubeconfig  = local.kubeconfig
    manifest    = local.namespace
    interpreter = local.interpreter
  }
  triggers_replace = [var.cluster_endpoint, var.cluster_name]
  provisioner "local-exec" {
    interpreter = self.input.interpreter
    command     = "namespace"
    environment = {
      KUBECONFIG_JSON = self.input.kubeconfig
      NGINX_MANIFEST  = self.input.manifest
    }
  }
  provisioner "local-exec" {
    when        = destroy
    interpreter = self.input.interpreter
    command     = "delete"
    environment = {
      KUBECONFIG_JSON = self.input.kubeconfig
      NGINX_MANIFEST  = self.input.manifest
    }
  }
}
resource "terraform_data" "nginx" {
  input = {
    kubeconfig  = local.kubeconfig
    manifest    = local.manifest
    interpreter = local.interpreter
  }
  triggers_replace = [
    sha256(local.manifest), filesha256("${path.module}/deploy.sh"), filesha256("${path.module}/deploy.ps1"),
    var.cluster_endpoint, local.shell
  ]
  provisioner "local-exec" {
    interpreter = self.input.interpreter
    command     = "apply"
    environment = {
      KUBECONFIG_JSON = self.input.kubeconfig
      NGINX_MANIFEST  = self.input.manifest
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
