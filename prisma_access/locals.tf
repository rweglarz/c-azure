locals {
  vnet_address_space = {
    sec      = [cidrsubnet(var.vnet_cidr, 1, 0)]
    panorama = [cidrsubnet(var.vnet_cidr, 1, 1)]
  }
}
