variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}
variable "region1" {
  type    = string
  default = "East US 2"
}
variable "region2" {
  type    = string
  default = "North Europe"
}

variable "subscription" {
  type = string
}

variable "region1_cidr" {
  type     = string
  default  = "172.16.0.0/20"
}
variable "region2_cidr" {
  type     = string
  default  = "172.16.16.0/20"
}
variable "ext_spokes_cidr" {
  type    = string
  default = "172.16.64.0/20"
}

variable "mgmt_ips" {
  description = "List of IPs allowed external access"
  type        = list(map(string))
  default = [
    {
      cidr        = "192.0.2.0/24"
      description = "public ip1"
    },
  ]
}

variable "username" {
  type = string
}
variable "password" {
  type = string
}

variable "bootstrap_options" {
  type = map(map(string))
  default = {
    common = {
      panorama-server             = "192.0.2.10"
      authcodes                   = "D0000000"
      dgname                      = "azure-vwan"
      cgname                      = "cg2"
      plugin-op-commands          = "set-cores:2"
      dhcp-accept-server-hostname = "yes"
    }
    hub2_sdwan_fw1 = {
      dgname  = "azure-vwan-sdwan"
    }
    hub2_sdwan_fw2 = {
      dgname  = "azure-vwan-sdwan"
    }
    hub4_sdwan_fw = {
      dgname  = "azure-vwan-sdwan"
    }
    sdwan_spoke1_fw = {
      dgname  = "azure-vwan-sdwan"
    }
  }
}

variable "aws_availability_zones" {
  default = [
    "eu-central-1a"
  ]
}

variable "psk" {
  type = string
}

variable "asn" {
  default = {
    aws_fw1         = 65001
    aws_fw2         = 65002
    hub2            = 65515 # must be
    hub2_sdwan_fw1  = 65021
    hub2_sdwan_fw2  = 65022
    hub4_sdwan_fw   = 65040
    hub4            = 65515 # must be
    sdwan_spoke1_fw = 65101
  }
}

variable "router_ids" {
  description = "also loopbacks"
  default = {
    aws_fw1         = "192.168.253.11"
    hub2_sdwan_fw1  = "192.168.253.21"
    hub2_sdwan_fw2  = "192.168.253.22"
    hub4_sdwan_fw   = "192.168.253.40"
    sdwan_spoke1_fw = "192.168.253.101"
  }
}

variable "peering_address" {
  default = {
    aws_fw1 = [
      "169.254.21.11",
      "169.254.21.12",
    ],
    hub2_i0 = [
      "169.254.21.1",
      "169.254.21.2",
    ],
    hub2_i1 = [
      "169.254.21.3",
      "169.254.21.4",
    ],
    hub4_i0 = [
      "169.254.21.5",
      "169.254.21.6",
    ],
    hub4_i1 = [
      "169.254.21.7",
      "169.254.21.8",
    ],
  }
}

variable "dns_zone_rg" {
  type = string
}
variable "dns_zone_name" {
  type = string
}

variable "fw_version" {
  type    = string
  default = null
}

variable "pl-mgmt-csp_nat_ips" {
  description = "aws prefix list id to open up sg on panorama for public fw access"
  type    = string
  default = null
}

variable "internet_security_enabled" {
  description = "default route propagation"
  default     = true
}

variable "gateway_load_balancer_frontend_ip_configuration_id" {
  default = null
}

variable "tags" {
  default = {}
}

variable "cloud_ngfw_private_ips" {
  default = {
    hub2 = "172.16.4.228"
  }
}

variable "cloud_ngfw_panorama_config" {
  type = map
}

variable "ssl_certificate_path" {
  default = null
}

variable "ssl_certificate_pass" {
  default = null
}

variable "trusted_root_certificate_path" {
  default = null
}


variable "sdwan_announce_dg" {
  type = bool
  default = false
}


variable "prisma_access" {
  default = {}
#   prisma_access = {
#   pagp1 = {
#     ipsec_policy = {
#       # phase1
#       dh_group = "DHGroup14"
#       ike_encryption_algorithm = "AES256"
#       ike_integrity_algorithm = "SHA256"
#       # phase2
#       encryption_algorithm  = "AES256"
#       integrity_algorithm = "SHA256"
#       pfs_group = "PFS14"
#       sa_lifetime_sec = 27000
#       sa_data_size_kb = 2147483647 #max
#     }
#     links = {
#       pri = {
#         asn = 65534
#         public_ip = "10.0.0.1"
#         peering_address = "192.168.255.3"
#         psk = "qaz123"
#         protocol = "IKEv1"
#         connect_to = {
#           hub2 = {}
#           hub4 = {}
#         }
#       }
#     }
#   }
# }
}
