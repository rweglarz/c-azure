variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "region" {
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
    left_ipsec_fw1 = "65001"
    left_ipsec_fw2 = "65002"
    right_vng      = "65515"
    right_env_fw1  = "65011"
    right_env_fw2  = "65012"
    right_env1_sdgw1  = "65101"
    right_env1_sdgw2  = "65102"
    right_env2_sdgw1  = "65201"
    right_env2_sdgw2  = "65202"
  }
}

variable "router_ids" {
  default = {
    left_ipsec_fw1 = "192.168.1.1"
    left_ipsec_fw2 = "192.168.1.2"
    right_env_fw1  = "192.168.3.1"
    right_env_fw2  = "192.168.3.2"
    right_env1_sdgw1 = "192.168.3.11"
    right_env1_sdgw1 = "192.168.3.12"
  }
}
