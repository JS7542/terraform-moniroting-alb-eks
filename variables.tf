variable "vpc_id" {
  type    = string
  default = null
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "api_allowed_cidrs" {
  description = "Public IPv4/32 of the machine running this apply and kubectl."
  type        = list(string)
  validation {
    condition     = length(var.api_allowed_cidrs) > 0 && alltrue([for cidr in var.api_allowed_cidrs : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"])
    error_message = "Specify your actual public IPv4 CIDR(s); do not use 0.0.0.0/0."
  }
}
variable "http_allowed_cidrs" {
  type    = set(string)
  default = ["0.0.0.0/0"]
}
variable "nginx_image" {
  type    = string
  default = "nginx:1.28-alpine"
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
}
variable "python_command" {
  description = "Python 3 executable (python, python3, or an absolute executable path)."
  type        = string
  default     = "python"
}
