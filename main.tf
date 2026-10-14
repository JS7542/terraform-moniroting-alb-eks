module "network" {
  source   = "./modules/network"
  vpc_id   = var.vpc_id
  vpc_cidr = var.vpc_cidr
}

data "aws_key_pair" "existing" {
  key_name = var.key_name
}

# Existing repository SSH SG: inbound TCP/22 from the Bastion SG.
data "aws_security_group" "internal_ssh" {
  filter {
    name   = "group-name"
    values = [var.internal_ssh_security_group_name]
  }

  filter {
    name   = "vpc-id"
    values = [module.network.vpc_id]
  }
}

module "ec2" {
  source                         = "./ec2"
  vpc_id                         = module.network.vpc_id
  public_subnet_ids              = module.network.public_subnet_ids
  private_subnet_ids             = module.network.private_subnet_ids
  nginx_image                    = var.nginx_image
  http_allowed_cidrs             = var.http_allowed_cidrs
  key_name                       = data.aws_key_pair.existing.key_name
  internal_ssh_security_group_id = data.aws_security_group.internal_ssh.id
}

# module "eks" {
#   source                         = "./eks"
#   cluster_subnet_ids             = module.network.cluster_subnet_ids
#   kubernetes_version             = var.kubernetes_version
#   node_instance_type             = var.node_instance_type
#   node_disk_size                 = var.node_disk_size
#   key_name                       = data.aws_key_pair.existing.key_name
#   internal_ssh_security_group_id = data.aws_security_group.internal_ssh.id
# }

# module "eks_app" {
#   source                 = "./eks-app"
#   name                   = module.eks.name
#   vpc_id                 = module.network.vpc_id
#   public_subnet_ids      = module.network.public_subnet_ids
#   node_security_group_id = module.eks.node_security_group_id
#   node_asg_name          = module.eks.node_asg_name
#   cluster_name           = module.eks.cluster_name
#   cluster_endpoint       = module.eks.cluster_endpoint
#   cluster_ca             = module.eks.cluster_ca
#   nginx_image            = var.nginx_image
#   http_allowed_cidrs     = var.http_allowed_cidrs
#   deployment_shell       = var.deployment_shell
#   depends_on             = [module.eks]
# }
