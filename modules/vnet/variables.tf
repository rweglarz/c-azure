variable "name" {

}

variable "resource_group_name" {

}

variable "location" {

}

variable "subnets" {

}

variable "address_space" {
}

variable "subnet_mask_length" {
  # gateway subnet size is 27, only basic allows 29
  default = 27
}

variable "dns_servers" {
  default = []
}

variable "bgp_community" {
  default = null
}

variable "vnet_peering" {
  default = {}
}
