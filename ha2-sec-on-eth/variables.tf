variable "name" {
  description = "Name/Prefix of the deployment"
  type = string
}
variable "vpc_cidr" {
  description = "vpc cidr"
  type = string
}
variable "srv_vpc_cidr" {
  description = "vpc cidr"
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

variable "fw_ver" {
  type = string
}

variable "instance_type" {
  type = string
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

variable "pl-mgmt-csp_nat_ips" {
  type = string
  default = "pl-029b5d80e69d9bc9e"
}
