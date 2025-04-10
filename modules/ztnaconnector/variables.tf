variable "name" {
  type = string
}

variable "subnet_id" {
  type = string
}
variable "private_ip_address" {
  type = string
}

variable "username" {
  type    = string
}
variable "password" {
  type = string
}
variable "location" {
  type = string
}
variable "resource_group_name" {
  type = string
}

variable "size" {
  type    = string
  default = "Standard_D4s_v3"
  nullable = false
}

variable "public_key" {
  type    = string
  default = null
}

variable "security_group" {
  type    = string
  default = null
}

variable "associate_nsg" {
  type    = bool
  default = false
}

variable "custom_data" {
  type    = string
  default = null
}

variable "enable_ip_forwarding" {
  type    = bool
  default = false
}

variable "tags" {
  default = null
}

variable "sw_version" {
  default = "6.2.51"
}

variable "token" {
}
