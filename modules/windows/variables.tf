variable "name" {
  type = string
}

variable "computer_name" {
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
  default = "Standard_DS1_v2"
  nullable = false
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

variable "gwlb_fe_id" {
  default = null
}

variable "associate_public_ip" {
  default = true
}

variable "windows_server" {
  description = "use windows server image"
  default = false
}

variable "image_variant" {
  default = "desktop11"
}

variable "image" {
  default = null
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}
