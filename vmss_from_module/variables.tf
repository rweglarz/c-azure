variable "subscription_id" {
   type    = string
}

variable "region" {
  type    = string
  default = "North Europe"
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "cidr" {
  description = "vnet cidr"
  type        = string
  default     = "172.29.32.0/23"
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

variable "instance_type" {
  type    = string
  default = "Standard_D3_v2"
}

variable "bootstrap_options_common" {
  type = map(string)
}
variable "bootstrap_options_byol" {
  type = map(string)
}
variable "bootstrap_options_payg" {
  type = map(string)
}

variable "username" {
  type = string
}
variable "password" {
  type = string
}


variable "gcp_project" {
  default = null
}
variable "gcp_panorama_vpc_id" {
  default = null
}


variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}

variable "panos_version" {
  default = "11.1.4"
}

variable "byol_count" {
  default = 0
}

variable "payg_count" {
  default = 2
}

