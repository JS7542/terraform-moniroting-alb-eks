variable "name" {
  type    = string
  default = "std20-nginx-eks"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,23}$", var.name))
    error_message = "Use 1-24 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "cluster_subnet_ids" { type = list(string) }
variable "key_name" { type = string }
variable "internal_ssh_security_group_id" { type = string }

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
