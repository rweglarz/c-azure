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
  default = "172.16.32.0/24"
}

variable "mgmt_ips" {
  description = "List of IPs allowed external access"
  type        = list(map(string))
}

variable "subscription" {
  type = string
}

variable "fw_version" {
  default = "10.2.4"
}

variable "firewalls" {

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
