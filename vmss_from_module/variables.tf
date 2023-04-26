variable "azure_subscription" {
  type = string
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

variable "bootstrap_options" {
  type = map(string)
}

variable "username" {
  type = string
}
variable "password" {
  type = string
}


variable "panorama1_ip" {
  type = string
}
variable "panorama2_ip" {
  type = string
}


variable "pl-mgmt-csp_nat_ips" {
  type = string
}

variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}

