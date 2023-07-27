locals {
  vnet_address_space = {
    sec  = [cidrsubnet(var.vnet_address_space, 4, 0)]
    app1 = [cidrsubnet(var.vnet_address_space, 4, 1)]
    app2 = [cidrsubnet(var.vnet_address_space, 4, 2)]
    sa   = [cidrsubnet(var.vnet_address_space, 4, 3)]
  }
}