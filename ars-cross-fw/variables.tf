variable "subscription_id" {
   type    = string
}

variable "region" {
  type    = string
  default = "polandcentral"
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type = string
  default = "rwe-cfw"
}
variable "cidr" {
  description = "vpc cidr"
  type = string
  default   = "172.29.0.0/22"
}

variable "mgmt_ips" {
  description = "List of IPs allowed external access"
  type = list(map(string))
}


variable "username" {
  type = string
}
variable "password" {
  type = string
}


variable "psk" {
  type = string
}


variable dns_zone_rg {
  type = string
}
variable dns_zone_name {
  type = string
}


variable "asn" {
  default = {
    onprem = 65001
    avs    = 65444
    fw_sec     = 65111
    fw_transit = 65111
  }
}