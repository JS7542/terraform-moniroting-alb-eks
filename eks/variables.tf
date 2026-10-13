variable "name" {
  type    = string
  default = "std20-nginx-eks"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,23}$", var.name))
    error_message = "Use 1-24 lowercase letters, digits or hyphens, starting with a letter."
  }
}
variable "cluster_subnet_ids" { type = list(string) }
variable "kubernetes_version" {
  type    = string
  default = "1.35"
}
variable "node_instance_type" {
  description = "t3.micro for the requested lab; increase to t3.small or larger if pods lack memory."
  type        = string
  default     = "t3.micro"
}
variable "node_disk_size" {
  type    = number
  default = 20
  validation {
    condition     = var.node_disk_size >= 20 && floor(var.node_disk_size) == var.node_disk_size
    error_message = "EKS AL2023 root volumes must be at least 20 GiB in this configuration."
  }
}
