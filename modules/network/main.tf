variable "vpc_id" {
  type    = string
  default = null
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

data "aws_vpc" "existing" {
  id         = var.vpc_id
  cidr_block = var.vpc_id == null ? var.vpc_cidr : null
  lifecycle {
    postcondition {
      condition     = self.enable_dns_support && self.enable_dns_hostnames
      error_message = "EKS requires VPC DNS support and DNS hostnames."
    }
  }
}

# Matches the supplied repository. No VPC/subnet/route resources are created.
locals {
  subnets = {
    public_a  = { az = "eu-north-1a", cidr = "10.20.1.0/24", type = "public" }
    public_b  = { az = "eu-north-1b", cidr = "10.20.2.0/24", type = "public" }
    public_c  = { az = "eu-north-1c", cidr = "10.20.3.0/24", type = "public" }
    private_a = { az = "eu-north-1a", cidr = "10.20.11.0/24", type = "private" }
    private_b = { az = "eu-north-1b", cidr = "10.20.12.0/24", type = "private" }
    private_c = { az = "eu-north-1c", cidr = "10.20.13.0/24", type = "private" }
    cluster_a = { az = "eu-north-1a", cidr = "10.20.21.0/24", type = "cluster" }
    cluster_b = { az = "eu-north-1b", cidr = "10.20.22.0/24", type = "cluster" }
    cluster_c = { az = "eu-north-1c", cidr = "10.20.23.0/24", type = "cluster" }
  }
}

data "aws_subnet" "existing" {
  for_each          = local.subnets
  vpc_id            = data.aws_vpc.existing.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
}

output "vpc_id" { value = data.aws_vpc.existing.id }
output "public_subnet_ids" {
  value = [for key, subnet in local.subnets : data.aws_subnet.existing[key].id if subnet.type == "public"]
}
output "private_subnet_ids" {
  value = [for key, subnet in local.subnets : data.aws_subnet.existing[key].id if subnet.type == "private"]
}
output "cluster_subnet_ids" {
  value = [for key, subnet in local.subnets : data.aws_subnet.existing[key].id if subnet.type == "cluster"]
}
