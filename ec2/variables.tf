variable "name" {
  type    = string
  default = "std20-nginx-ec2"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,23}$", var.name))
    error_message = "Use 1-24 lowercase letters, digits or hyphens, starting with a letter."
  }
}
variable "vpc_id" {
  description = "Existing VPC ID; null discovers it by CIDR."
  type        = string
  default     = null
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "nginx_image" {
  type    = string
  default = "nginx:1.28-alpine"
}
variable "http_allowed_cidrs" {
  type    = set(string)
  default = ["0.0.0.0/0"]
  validation {
    condition     = alltrue([for cidr in var.http_allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "Supply valid IPv4 CIDRs."
  }
}
