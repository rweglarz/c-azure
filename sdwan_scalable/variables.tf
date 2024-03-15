variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "region" {
  type    = string
  default = "polandcentral"
}

variable "region_cidr" {
  type     = string
  default  = "172.16.0.0/20"
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

variable "bootstrap_options" {
  default = {}
}

variable "psk" {
  type = string
}

variable "asn" {
  default = {
    fw     = 65001
    sdwan1 = 65101
    sdwan2 = 65102
  }
}

variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}

variable "panos_version" {
  type    = string
  default = "11.1.2"
}
variable "fw_count" {
  type    = number
  default = 3
}

variable "pl-mgmt-csp_nat_ips" {
  type = string
}

variable "tags" {
  default = {}
}
