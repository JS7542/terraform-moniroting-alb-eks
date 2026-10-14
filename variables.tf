variable "vpc_id" {
  description = "Existing VPC ID; null discovers it using the repository CIDR."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "key_name" {
  description = "Existing EC2 key pair in eu-north-1."
  type        = string
  default     = "std20-keypair"
}

variable "internal_ssh_security_group_name" {
  description = "Existing repository SG allowing SSH from the Bastion SG."
  type        = string
  default     = "std20-cicd-internal-ssh-sg"
}

variable "http_allowed_cidrs" {
  type    = set(string)
  default = ["0.0.0.0/0"]
  validation {
    condition     = alltrue([for cidr in var.http_allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "Supply valid IPv4 CIDRs."
  }
}

variable "nginx_image" {
  type    = string
  default = "csjin21c/nginx:1.31.3-v1"
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._/:@-]*$", var.nginx_image))
    error_message = "Supply a container image reference without whitespace or shell characters."
  }
}

variable "kubernetes_version" {
  type    = string
  default = "1.35"
}

variable "node_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "node_disk_size" {
  type    = number
  default = 20
  validation {
    condition     = var.node_disk_size >= 20 && floor(var.node_disk_size) == var.node_disk_size
    error_message = "Use an integer root volume size of at least 20 GiB for the EKS AMI."
  }
}

variable "deployment_shell" {
  type    = string
  default = "auto"
  validation {
    condition     = contains(["auto", "powershell", "bash"], var.deployment_shell)
    error_message = "Use auto, powershell or bash."
  }
}
