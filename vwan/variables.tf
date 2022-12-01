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

variable "hub1_prefix" {
  description = "vpc cidr"
  type        = string
  default     = "172.16.1.0/24"
}
variable "hub1_cidr" {
  description = "vpc cidr"
  type        = string
  default     = "172.16.0.0/20"
}
variable "hub2_prefix" {
  description = "vpc cidr"
  type        = string
  default     = "172.16.17.0/24"
}
variable "hub2_cidr" {
  description = "vpc cidr"
  type        = string
  default     = "172.16.16.0/20"
}

variable "aws_cidr" {
  description = "aws vpc cidr"
  type        = string
  default     = "172.16.100.0/24"
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
    aws_fw1   = 65516
    hub1_vpn1 = 65515
  }
}

variable "peering_address" {
  default = {
    aws_fw1 = [
      "169.254.21.11",
      "169.254.21.12",
    ],
    hub1_vpn1_i0 = [
      "169.254.21.1",
      "169.254.21.2",
    ],
    hub1_vpn1_i1 = [
      "169.254.21.3",
      "169.254.21.4",
    ],
  }
}

variable dns_zone_rg {
  type = string
}
variable dns_zone_name {
  type = string
}

