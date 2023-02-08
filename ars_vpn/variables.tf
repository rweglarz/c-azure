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