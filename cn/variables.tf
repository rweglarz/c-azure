variable "region" {
  type    = string
  default = "polandcentral"
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type = string
}
variable "vnet_cidr" {
  description = "vnet cidr"
  type        = string
  default     = "172.29.0.0/19"
}

variable panorama1_ip {
  type = string
}
variable panorama2_ip {
  type = string
}

variable "mgmt_ips" {
  description = "List of IPs allowed external access"
  type = list(map(string))
}
variable "tmp_ips" {
  description = "List of tmp IPs allowed external access"
  type = list(map(string))
  default = []
}

variable "instance_type" {
  type = string
  default = "Standard_D3_v2"
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

variable dns_zone_rg {
  type = string
}
variable dns_zone_name {
  type = string
}

variable fw_prv_ip {
  type    = string
  default = null
}
