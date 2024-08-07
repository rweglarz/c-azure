variable "location" {
  type    = string
  default = "polandcentral"
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type = string
}
variable "cidr" {
  type    = string
  default = "172.29.0.0/22"
}
variable "cidr_vpn" {
  type    = string
  default = "172.30.0.0/23"
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

variable "fw_version" {
  type    = string
  default = "11.1.4"
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
}

variable dns_zone_rg {
  type = string
}
variable dns_zone_name {
  type = string
}

variable inbound_tcp_ports {
  default = [
    22,
  ]
}
variable inbound_udp_ports {
  default = [
    500,
    4500,
  ]
}

variable "vmseries" {
  default = {
    fw0 = {
      zone = 1
    }
    fw1 = {
      zone = 2
    }
  }
}

variable "vpn_psk" {
  type = string
}
