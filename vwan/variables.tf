variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}
variable "region1" {
  type    = string
  default = "West Europe"
}
variable "region2" {
  type    = string
  default = "North Europe"
}

variable "subscription" {
  type = string
}

variable "region1_cidr" {
  type     = string
  default  = "172.16.0.0/20"
}
variable "region2_cidr" {
  type     = string
  default  = "172.16.16.0/20"
}
variable "ext_spokes_cidr" {
  type    = string
  default = "172.16.64.0/20"
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
  type = map(map(string))
}

variable "aws_availability_zones" {
  default = [
    "eu-central-1a"
  ]
}

variable "psk" {
  type = string
}

variable "asn" {
  default = {
    aws_fw1         = 65001
    hub2_vpn1       = 65515
    hub2_sdwan_fw   = 65021
    hub4_sdwan_fw   = 65022
    ipsec_hub2_fw1  = 65041
    ipsec_hub2_fw2  = 65042
    sdwan_spoke1_fw = 65101
    ipsec_spoke1_fw = 65102
  }
}

variable "router_ids" {
  description = "also loopbacks"
  default = {
    aws_fw1         = "192.168.253.11"
    hub2_sdwan_fw   = "192.168.253.31"
    hub4_sdwan_fw   = "192.168.253.32"
    ipsec_hub2_fw1  = "192.168.253.41"
    ipsec_hub2_fw2  = "192.168.253.42"
    sdwan_spoke1_fw = "192.168.253.101"
    ipsec_spoke1_fw = "192.168.253.102"
  }
}

variable "peering_address" {
  default = {
    aws_fw1 = [
      "169.254.21.11",
      "169.254.21.12",
    ],
    hub2_vpn1_i0 = [
      "169.254.21.1",
      "169.254.21.2",
    ],
    hub2_vpn1_i1 = [
      "169.254.21.3",
      "169.254.21.4",
    ],
    ipsec_hub2_fw1-tun21 = [
      "169.254.31.1"
    ]
    ipsec_hub2_fw2-tun22 = [
      "169.254.31.3"
    ]
    ipsec_spoke1_fw-tun21 = [
      "169.254.31.2"
    ]
    ipsec_spoke1_fw-tun22 = [
      "169.254.31.4"
    ]
  }
}

variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}

variable "fw_version" {
  type    = string
  default = null
}

variable "pl-mgmt-csp_nat_ips" {
  type = string
}

variable "cloud_ngfw_ips" {
  type = map 
}

variable "internet_security_enabled" {
  description = "default route propagation"
  default     = true
}
