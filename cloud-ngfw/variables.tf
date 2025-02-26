variable "subscription_id" {
  type = string
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "region" {
  type    = string
  default = "North Europe"
}

variable "sec_vpc_cidr" {
  description = "vpc cidr"
  type        = string
  default     = "172.30.0.0/16"
}

variable "app_vpc_cidr" {
  description = "vpc cidr"
  type        = string
  default     = "172.29.0.0/16"
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

variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}

variable "cloud_ngfw_panorama_config" {
  description = "if null, will deploy cloud-ngfw managed by local rulestack"
  type        = string
  default     = null
}

variable "cloud_ngfw_internal_ip" {
  description = "used for UDR when deployment via azure portal == scm"
  type        = string
  default     = null
}

variable "scm_tenant" {
  description = "used only to not deploy panorama for now"
  type        = string
  default     = null
}

variable "cloud_ngfw_public_ingress_ip_number" {
  type    = number
  default = 2
  validation {
    condition     = var.cloud_ngfw_public_ingress_ip_number >= 2
    error_message = "2 services are eposed by default"
  }
}

variable "cloud_ngfw_public_egress_ip_number" {
  type    = number
  default = 0
  description = "additional IPs used for outbound"
}

variable "server_count" {
  type    = number
  default = 1
}

variable "server_size" {
  type    = string
  default = null
}

variable "gcp_project" {
  default = null
}
variable "gcp_panorama_vpc_id" {
  default = null
}
