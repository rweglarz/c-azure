resource "azurerm_virtual_network" "app01" {
  name                = "${var.name}-app01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.app_vpc_cidr, 8, 0)]
}

resource "azurerm_subnet" "app01_s01" {
  name                 = "${var.name}-app01-s01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.app01.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.app01.address_space[0], 4, 0)]
}

resource "azurerm_virtual_network_peering" "app01-sec" {
  name                      = "${var.name}-app01-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.app01.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "sec-app01" {
  name                      = "${var.name}-app01-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.app01.id
}

resource "azurerm_subnet_route_table_association" "app01_s01" {
  subnet_id      = azurerm_subnet.app01_s01.id
  route_table_id = azurerm_route_table.via-fw.id
}

resource "azurerm_subnet_route_table_association" "app02_s01" {
  subnet_id      = azurerm_subnet.app02_s01.id
  route_table_id = azurerm_route_table.via-fw.id
}




resource "azurerm_virtual_network" "app02" {
  name                = "${var.name}-app02"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.app_vpc_cidr, 8, 1)]
}

resource "azurerm_subnet" "app02_s01" {
  name                 = "${var.name}-app02-s01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.app02.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.app02.address_space[0], 4, 0)]
}

resource "azurerm_virtual_network_peering" "app02-sec" {
  name                      = "${var.name}-app02-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.app02.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "sec-app02" {
  name                      = "${var.name}-app02-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.app02.id
}


