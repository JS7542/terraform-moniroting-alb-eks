terraform {
  required_version = ">= 1.10.0, < 2.0.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}
provider "aws" {
  region = "eu-north-1"
  default_tags {
    tags = { Project = "std20-nginx", ManagedBy = "Terraform" }
  }
}
