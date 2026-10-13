variable "vpc_id" {
  type    = string
  default = null
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
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
variable "deployment_shell" {
  description = "auto selects PowerShell on Windows or Bash on Linux/macOS."
  type        = string
  default     = "auto"
  validation {
    condition     = contains(["auto", "powershell", "bash"], var.deployment_shell)
    error_message = "Use auto, powershell or bash."
  }
}
