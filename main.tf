module "network" {
  source   = "./modules/network"
  vpc_id   = var.vpc_id
  vpc_cidr = var.vpc_cidr
}
module "ec2" {
  source             = "./ec2"
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  nginx_image        = var.nginx_image
  http_allowed_cidrs = var.http_allowed_cidrs
}
module "eks" {
  source             = "./eks"
  cluster_subnet_ids = module.network.cluster_subnet_ids
  kubernetes_version = var.kubernetes_version
  node_instance_type = var.node_instance_type
  node_disk_size     = var.node_disk_size
}
module "eks_app" {
  source                 = "./eks-app"
  name                   = module.eks.name
  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  node_security_group_id = module.eks.node_security_group_id
  node_asg_name          = module.eks.node_asg_name
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca             = module.eks.cluster_ca
  nginx_image            = var.nginx_image
  http_allowed_cidrs     = var.http_allowed_cidrs
  deployment_shell       = var.deployment_shell
  depends_on             = [module.eks]
}
