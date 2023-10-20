variable "name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "private_ip_address" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "use_public_ip" {
  type = bool
}

variable "tier" {
  type = string
}

variable "virtual_hosts" {
  type    = map(any)
  default = {}
}

variable "managed_by_agic" {
  description = "managed by aks / agic"
  default = false
}

variable "use_https" {
  default = false
}

variable "ssl_certificate_data" {
  default = null
}

variable "ssl_certificate_pass" {
  default = null
}

variable "trusted_root_certificate_data" {
  default = null
}
