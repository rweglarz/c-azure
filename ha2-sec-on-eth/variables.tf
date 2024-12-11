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
}
variable "cidr" {
  description = "vpc cidr"
  type = string
  default   = "172.29.0.0/22"
}

variable "availabilty_zones" {
  type = list
  default = [1, 2]
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

variable "fw_ver" {
  type = string
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

variable dns_zone_rg {
  type = string
}
variable dns_zone_name {
  type = string
}

variable "gcp_project" {
  default = null
}
variable "gcp_panorama_vpc_id" {
  default = null
}
