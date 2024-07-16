locals {
  subnet_prefix_length = 27
  private_ips = {
    fw   = cidrhost(module.vnet_transit.subnets.data.address_prefixes[0], 5)
    ars1 = sort(azurerm_route_server.transit.virtual_router_ips)[0]
    ars2 = sort(azurerm_route_server.transit.virtual_router_ips)[1]
  }
}
