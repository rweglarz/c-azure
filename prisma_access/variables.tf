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
  type = string
  default = "10.2.3"
}

# variable "panorama1_ip" {
#   type = string
# }
# variable "panorama2_ip" {
#   type = string
# }

