module "vnet_peering-left_u-left_b" {
  source = "../modules/vnet_peering"

  on_local = {
    resource_group_name     = azurerm_resource_group.rg1.name
    virtual_network_name    = module.vnet_left_u_hub.vnet.name
    virtual_network_id      = module.vnet_left_u_hub.vnet.id
    allow_forwarded_traffic = true
  }

  on_remote = {
    resource_group_name     = azurerm_resource_group.rg2.name
    virtual_network_name    = module.vnet_left_b_hub.vnet.name
    virtual_network_id      = module.vnet_left_b_hub.vnet.id
    allow_forwarded_traffic = true
  }
}


resource "azurerm_route_table" "left_u_hub" {
  name                = "${var.name}-left_u_hub"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
}

resource "azurerm_route" "left_u_hub" {
  for_each = {
    srv1 = module.vnet_left_b_srv_1.vnet.address_space[0]
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.rg1.name
  route_table_name       = azurerm_route_table.left_u_hub.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.private_ips.left_b_hub_ilb["obew"]
}

resource "azurerm_subnet_route_table_association" "left_u_hub" {
  subnet_id      = module.vnet_left_u_hub.subnets["data"].id
  route_table_id = azurerm_route_table.left_u_hub.id
}


resource "azurerm_route_table" "left_b_hub" {
  name                = "${var.name}-left_b_hub"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
}

resource "azurerm_route" "left_b_hub" {
  for_each = {
    srv1 = module.vnet_left_u_srv_1.vnet.address_space[0]
    sdgw = "10.0.0.0/8"
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.rg2.name
  route_table_name       = azurerm_route_table.left_b_hub.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.private_ips.left_u_hub_ilb["obew"]
}

resource "azurerm_subnet_route_table_association" "left_b_hub" {
  subnet_id      = module.vnet_left_b_hub.subnets["data"].id
  route_table_id = azurerm_route_table.left_b_hub.id
}
