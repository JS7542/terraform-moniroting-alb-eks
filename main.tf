resource "terraform_data" "prerequisites" {
  triggers_replace = [var.python_command, filesha256("${path.module}/eks-app/deploy.py")]
  provisioner "local-exec" {
    interpreter = [var.python_command, abspath("${path.module}/eks-app/deploy.py")]
    command     = "check"
  }
}
module "ec2" {
  source             = "./ec2"
  vpc_id             = var.vpc_id
  vpc_cidr           = var.vpc_cidr
  nginx_image        = var.nginx_image
  http_allowed_cidrs = var.http_allowed_cidrs
  depends_on         = [terraform_data.prerequisites]
}
module "eks" {
  source             = "./eks"
  vpc_id             = var.vpc_id
  vpc_cidr           = var.vpc_cidr
  api_allowed_cidrs  = var.api_allowed_cidrs
  kubernetes_version = var.kubernetes_version
  node_instance_type = var.node_instance_type
  node_disk_size     = var.node_disk_size
  depends_on         = [terraform_data.prerequisites]
}
module "eks_app" {
  source                 = "./eks-app"
  name                   = module.eks.name
  vpc_id                 = module.eks.vpc_id
  public_subnet_ids      = module.eks.public_subnet_ids
  node_security_group_id = module.eks.node_security_group_id
  node_asg_name          = module.eks.node_asg_name
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca             = module.eks.cluster_ca
  nginx_image            = var.nginx_image
  http_allowed_cidrs     = var.http_allowed_cidrs
  python_command         = var.python_command
  depends_on             = [module.eks]
}
