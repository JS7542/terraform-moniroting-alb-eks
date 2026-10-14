variable "name" {
  type    = string
  default = "std20-nginx-ec2"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,23}$", var.name))
    error_message = "Use 1-24 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "key_name" { type = string }
variable "internal_ssh_security_group_id" { type = string }

variable "nginx_image" {
  type    = string
  default = "nginx:1.31.3-cd"
}

variable "http_allowed_cidrs" {
  type    = set(string)
  default = ["0.0.0.0/0"]
  validation {
    condition     = alltrue([for cidr in var.http_allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "Supply valid IPv4 CIDRs."
  }
}
