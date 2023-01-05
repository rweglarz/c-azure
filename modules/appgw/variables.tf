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
