variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "region" {
  type    = string
  default = "Germany West Central"
}

variable "region_fl" {
  type    = string
  default = "West Europe"
}

variable "cidr" {
  type    = string
  default = "172.16.0.0/20"
}

variable "mgmt_ips" {
  description = "List of IPs allowed external access"
  type        = list(map(string))
}

variable "subscription" {
  type = string
}

variable "fw_version" {
  default = "10.1.7"
}

variable "psk" {
}

variable "username" {}
variable "password" {}
variable "pl-mgmt-csp_nat_ips" {}

variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}

variable "bootstrap_options" {

}
variable "asn" {
  default = {
    ars              = "65515"
    left_u_ipsec_fw1 = "65001"
    left_u_ipsec_fw2 = "65001"
    right_env_fw1    = "65011"
    right_env_fw2    = "65011"
    right_env1_sdgw1 = "65101"
    right_env1_sdgw2 = "65101"
    right_env2_sdgw1 = "65201"
    right_env2_sdgw2 = "65201"
  }
}

variable "router_ids" {
  default = {
    left_u_ipsec_fw1 = "192.168.0.1"
    left_u_ipsec_fw2 = "192.168.0.2"
    right_env_fw1    = "192.168.1.1"
    right_env_fw2    = "192.168.1.2"
    right_env1_sdgw1 = "192.168.10.1"
    right_env1_sdgw2 = "192.168.10.2"
    right_env2_sdgw1 = "192.168.20.1"
    right_env2_sdgw2 = "192.168.20.2"
  }
}
