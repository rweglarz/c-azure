variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "region" {
  type    = string
  default = "polandcentral"
}

variable "cidr" {
  type    = string
  default = "172.16.0.0/20"
}

variable "mgmt_ips" {
  description = "List of IPs allowed external access"
  type        = list(map(string))
}


variable "username" {}
variable "password" {}

variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}

variable "asn" {
  default = {
    ars     = "65515"
    sdgw_A1 = "65011"
    sdgw_A2 = "65012"
    sdgw_B  = "65021"
  }
}
