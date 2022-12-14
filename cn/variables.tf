variable "name" {
  description = "Name/Prefix of the deployment"
  type = string
}
variable "vnet_cidr" {
  description = "vpc cidr"
  type = string
}

variable panorama1_ip {
  type = string
}
variable panorama2_ip {
  type = string
}

variable "mgmt_ips" {
  description = "List of IPs allowed external access"
  type = list(map(string))
}
variable "tmp_ips" {
  description = "List of tmp IPs allowed external access"
  type = list(map(string))
  default = []
}

variable "instance_type" {
  type = string
  default = "Standard_D3_v2"
}

variable "username" {
  type = string
}
variable "password" {
  type = string
}
