variable "azure_subscription" {
  type = string
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}
variable "vnet_address_space" {
  description = "vpc cidr"
  type        = string
  default     = "172.30.0.0/20"
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

variable "fw_ver" {
  type = string
  default = "10.1.9"
}

variable "instance_type" {
  type    = string
  default = "Standard_D3_v2"
}

variable "bootstrap_options" {
  type = map(string)
}

variable "username" {
  type = string
}
variable "password" {
  type = string
}

variable "pl-mgmt-csp_nat_ips" {
  type = string
}

variable "use_fake_gw" {
  type = number
  default = 0
}


variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}

variable "location" {
  default = "West Europe"
}
