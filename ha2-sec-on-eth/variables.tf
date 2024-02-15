variable "azure_subscription" {
   type    = string
   default = "change_me"
}

variable "region" {
  type    = string
  default = "polandcentral"
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type = string
}
variable "cidr" {
  description = "vpc cidr"
  type = string
  default   = "172.29.0.0/22"
}

variable "availabilty_zones" {
  type = list
  default = [1, 2]
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

variable "fw_ver" {
  type = string
}

variable "instance_type" {
  type = string
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
  default = "pl-029b5d80e69d9bc9e"
}

variable dns_zone_rg {
  type = string
}
variable dns_zone_name {
  type = string
}

