variable "subscription_id" {
   type    = string
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "region" {
  type    = string
  default = "north europe"
}

variable "region_cidr" {
  type     = string
  default  = "172.16.0.0/20"
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
  default = {}
}

variable "psk" {
  type = string
}

variable "asn" {
  default = {
    hub1        = 65515 # must be
    hub2        = 65515 # must be
    onprem      = 65001
    hub1_sdwan1 = 65101
    hub1_sdwan2 = 65102
  }
}

variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}

variable "fw_sku" {
  type    = string
  default = "bundle1"
}
variable "fw_panos_version" {
  type    = string
  default = "11.2.8"
}
variable "vmss_size" {
  type    = number
  default = 1
}

variable "tags" {
  default = {}
}


variable "gcp_project" {
  default = null
}
variable "gcp_panorama_vpc_id" {
  default = null
}

variable "cloud_ngfw_panorama_config" {
  type = string
}
variable "configure_hub_routing_intent" {
  type    = bool
  default = true
}

variable "workload_size" {
  # default = "Standard_DS1_v2"
  default = null
}
