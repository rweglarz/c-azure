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
  default = "ubuntu"
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
  default = "Standard_DS1_v2"
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
