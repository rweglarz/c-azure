locals {
  subnet_prefix_length = 27
  cidrs = {
    transit = cidrsubnet(var.cidr, 4, 0)
    spoke1  = cidrsubnet(var.cidr, 4, 1)
    spoke2  = cidrsubnet(var.cidr, 4, 2)
    spoke3  = cidrsubnet(var.cidr, 4, 3)
    spoke4a = cidrsubnet(var.cidr, 5, 4*2+0)
    spoke4b = cidrsubnet(var.cidr, 5, 4*2+1)
    spoke5a = cidrsubnet(var.cidr, 5, 5*2+0)
    spoke5b = cidrsubnet(var.cidr, 5, 5*2+1)
  }
  private_ips = {
    fw   = cidrhost(module.vnet_transit.subnets.data.address_prefixes[0], 5)
    ars1 = sort(azurerm_route_server.transit.virtual_router_ips)[0]
    ars2 = sort(azurerm_route_server.transit.virtual_router_ips)[1]
    ngfw = cidrhost(module.vnet_transit.subnets.data.address_prefixes[0], 6)

    transit_data_gw = cidrhost(module.vnet_transit.subnets.data.address_prefixes[0], 1)
  }
}
