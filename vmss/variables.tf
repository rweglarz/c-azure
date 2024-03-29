variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}
variable "vnet_cidr" {
  description = "vpc cidr"
  type        = string
  default     = "172.29.32.0/19"
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

variable "fw_version" {
  type    = string
  default = "10.1.9"
}

variable "fw_instances_bnd" {
  type    = number
  default = 1
}
variable "fw_instances_byol" {
  type    = number
  default = 1
}

variable "instance_type" {
  type    = string
  default = "Standard_D3_v2"
}

variable "bootstrap_options" {
  type = map(map(string))
  default = {
    common = {
      dhcp-accept-server-hostname = "yes"
    }
    bnd = {
    }
    byol = {
      #authcodes =
    }
  }
}

variable "username" {
  type = string
}
variable "password" {
  type = string
}


variable "panorama1_ip" {
  type    = string
  default = ""
}
variable "panorama2_ip" {
  type    = string
  default = ""
}

variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}

variable "pl-mgmt-csp_nat_ips" {
  type = string
}
