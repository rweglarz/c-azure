resource "azurerm_virtual_network_peering" "on_local" {
  name                      = "to-${var.on_remote.virtual_network_name}"
  resource_group_name       = var.on_local.resource_group_name
  virtual_network_name      = var.on_local.virtual_network_name
  remote_virtual_network_id = var.on_remote.virtual_network_id

  allow_virtual_network_access = var.on_local.allow_virtual_network_access
  allow_forwarded_traffic      = var.on_local.allow_forwarded_traffic     
  allow_gateway_transit        = var.on_local.allow_gateway_transit       
  use_remote_gateways          = var.on_local.use_remote_gateways         
}

resource "azurerm_virtual_network_peering" "on_remote" {
  name                      = "to-${var.on_local.virtual_network_name}"
  resource_group_name       = var.on_remote.resource_group_name
  virtual_network_name      = var.on_remote.virtual_network_name
  remote_virtual_network_id = var.on_local.virtual_network_id

  allow_virtual_network_access = var.on_remote.allow_virtual_network_access
  allow_forwarded_traffic      = var.on_remote.allow_forwarded_traffic     
  allow_gateway_transit        = var.on_remote.allow_gateway_transit       
  use_remote_gateways          = var.on_remote.use_remote_gateways         

  depends_on = [ 
    azurerm_virtual_network_peering.on_local
  ]
}
