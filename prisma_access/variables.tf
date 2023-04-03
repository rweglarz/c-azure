variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "vnet_cidr" {
  description = "vnet cidr"
  type        = string
  default     = "10.0.0.0/23"
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

variable "panorama_version" {
  type    = string
  default = "10.2.3"
}


variable "asn" {
  default = {
    vng = "65515"
    pa  = "65534"
  }
}

variable "psk" {
  default = null
}

variable "prisma_access_pub_ips" {
  default = [
    "198.51.100.1",
    "198.51.100.2",
  ]
}

variable "prisma_access_bgp_ips" {
  default = [
    "169.254.22.2",
    "169.254.22.6"
  ]
}

variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}
