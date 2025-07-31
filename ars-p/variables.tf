variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
  default     = "ars-p"
}

variable "subscription_id" {
  type = string
}

variable "region1" {
  type    = string
  default = "polandcentral"
}

variable "cidr_azure" {
  type    = string
  default = "172.16.0.0/16"
}
variable "cidr_onprem" {
  type    = string
  default = "10.1.1.0/24"
}
variable "cidr_partners" {
  type    = string
  default = "10.22.0.0/16"
}

variable "gcp_project" {
  default = null
}
variable "gcp_panorama_vpc_id" {
  default = null
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
    ars      = "65515"
    fws      = "65011"
    partner1 = "65031"
    partner2 = "65032"
  }
}

variable "bootstrap_options" {
}
