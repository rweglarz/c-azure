variable "subscription_id" {
  type = string
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "region" {
  type    = string
  default = "North Europe"
}

variable "sec_vnet_cidr" {
  description = "vnet cidr"
  type        = string
  default     = "172.30.0.0/24"
}

variable "app_vnet_cidr" {
  description = "vnet cidr"
  type        = string
  default     = "172.16.0.0/16"
}

variable "unique_vnet_cidr" {
  description = "vnet cidr"
  type        = string
  default     = "10.254.0.0/16"
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

variable "pl-mgmt-csp_nat_ips" {
  type = string
}

