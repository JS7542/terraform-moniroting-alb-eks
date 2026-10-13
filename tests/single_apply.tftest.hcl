mock_provider "aws" {
  mock_data "aws_vpc" {
    defaults = {
      id                   = "vpc-0123456789abcdef0"
      enable_dns_support   = true
      enable_dns_hostnames = true
    }
  }
  mock_data "aws_ami" {
    defaults = { root_device_name = "/dev/xvda", id = "ami-0123456789abcdef0" }
  }
  mock_data "aws_ssm_parameter" {
    defaults = { value = "ami-0123456789abcdef0" }
  }
}
run "fresh_single_root_plan" {
  command = plan
  variables {
    api_allowed_cidrs = ["203.0.113.10/32"]
  }
}
