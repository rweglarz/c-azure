locals {
  unique_vnet_cidrs = {
    net1 = cidrsubnet(var.unique_vnet_cidr, 8, 0)
    net2 = cidrsubnet(var.unique_vnet_cidr, 8, 1)
  }
  unique_subnet_cidrs = {
    vnet1_subnet1 = cidrsubnet(local.unique_vnet_cidrs.net1, 1, 0)
    vnet2_subnet1 = cidrsubnet(local.unique_vnet_cidrs.net2, 1, 0)
  }
}

#region net1
resource "azurerm_virtual_network" "net1" {
  name                = "${local.dname}-net1"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.app_vnet_cidr, local.unique_vnet_cidrs.net1]
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet" "net1-o1" {
  name                = "overlap1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.net1.name
  address_prefixes     = [cidrsubnet(var.app_vnet_cidr, 4, 0)]
}

resource "azurerm_subnet" "net1-u1" {
  name                = "unique1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.net1.name
  address_prefixes     = [local.unique_subnet_cidrs.vnet1_subnet1]
}
#endregion


#region net2
resource "azurerm_virtual_network" "net2" {
  name                = "${local.dname}-net2"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.app_vnet_cidr, local.unique_vnet_cidrs.net2]
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet" "net2-o1" {
  name                = "overlap1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.net2.name
  address_prefixes     = [cidrsubnet(var.app_vnet_cidr, 4, 0)]
}

resource "azurerm_subnet" "net2-u1" {
  name                = "unique1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.net2.name
  address_prefixes     = [local.unique_subnet_cidrs.vnet2_subnet1]
}
#endregion


#region peering
resource "azurerm_virtual_network_peering" "net1-sec" {
  name                      = "net1-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.net1.name
  remote_virtual_network_id = module.vnet_sec.id

  peer_complete_virtual_networks_enabled = false
  local_subnet_names  = [ azurerm_subnet.net1-u1.name ]
  remote_subnet_names = [ "private" ]
}
resource "azurerm_virtual_network_peering" "sec-net1" {
  name                      = "sec-net1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.vnet_sec.name
  remote_virtual_network_id = azurerm_virtual_network.net1.id

  peer_complete_virtual_networks_enabled = false
  local_subnet_names  = [ "private" ]
  remote_subnet_names = [ azurerm_subnet.net1-u1.name ]
}

resource "azurerm_virtual_network_peering" "net2-sec" {
  name                      = "net2-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.net2.name
  remote_virtual_network_id = module.vnet_sec.id

  peer_complete_virtual_networks_enabled = false
  local_subnet_names  = [ azurerm_subnet.net2-u1.name ]
  remote_subnet_names = [ "private" ]
}
resource "azurerm_virtual_network_peering" "sec-net2" {
  name                      = "sec-net2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.vnet_sec.name
  remote_virtual_network_id = azurerm_virtual_network.net2.id

  peer_complete_virtual_networks_enabled = false
  local_subnet_names  = [ "private" ]
  remote_subnet_names = [ azurerm_subnet.net2-u1.name ]
}
#endregion


#region routing
resource "azurerm_subnet_route_table_association" "net1_app" {
  subnet_id      = azurerm_subnet.net1-o1.id
  route_table_id = module.basic.route_table_id.dg-via-nh.net1_app
}

resource "azurerm_subnet_route_table_association" "net1_unique" {
  subnet_id      = azurerm_subnet.net1-u1.id
  route_table_id = module.basic.route_table_id.mgmt-via-igw-dg-via-nh.unique
}

resource "azurerm_subnet_route_table_association" "net2_app" {
  subnet_id      = azurerm_subnet.net2-o1.id
  route_table_id = module.basic.route_table_id.dg-via-nh.net2_app
}

resource "azurerm_subnet_route_table_association" "net2_unique" {
  subnet_id      = azurerm_subnet.net2-u1.id
  route_table_id = module.basic.route_table_id.mgmt-via-igw-dg-via-nh.unique
}
#endregion
