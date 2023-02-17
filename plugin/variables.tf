variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}
variable "vpc_cidr" {
  description = "vpc cidr"
  type        = string
  default     = "172.29.0.0/21"
}
variable "mgmt_ips" {
  description = "List of IPs allowed external access"
  type        = list(map(string))
}
variable "tmp_ips" {
  description = "List of tmp IPs allowed external access"
  type        = list(map(string))
  default     = []
}

variable "subscription" {
  type = string
}

variable "username" {
  type = string
}
variable "password" {
  type = string
}

variable "inb_int_lb" {
  type = string
}
variable "ewo_int_lb" {
  type = string
}
