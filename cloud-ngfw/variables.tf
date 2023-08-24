variable "subscription" {
  type = string
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}
variable "sec_vpc_cidr" {
  description = "vpc cidr"
  type        = string
  default     = "172.30.0.0/16"
}

variable "app_vpc_cidr" {
  description = "vpc cidr"
  type        = string
  default     = "172.29.0.0/16"
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

variable "username" {
  type = string
}
variable "password" {
  type = string
}

variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}

variable "cloud_ngfw_internal_ip" {
  type  = string
  default = "172.30.64.4"
}

variable "cloud_ngfw_public_ip" {
  type = string
}

variable "pl-mgmt-csp_nat_ips" {
  type = string
}

