resource "azurerm_virtual_network" "hub1_spoke1" {
  name                = "${var.name}-hub1-spoke1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [cidrsubnet(var.hub1_cidr, 4, 3)]
}

resource "azurerm_subnet" "hub1_spoke1_s1" {
  name                 = "${var.name}-hub1_spoke1_s1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.hub1_spoke1.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub1_spoke1.address_space[0], 5, 1)]
}



resource "azurerm_virtual_network" "hub1_spoke2" {
  name                = "${var.name}-hub1_spoke2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [cidrsubnet(var.hub1_cidr, 4, 4)]
}

resource "azurerm_subnet" "hub1_spoke2_s1" {
  name                 = "${var.name}-hub1_spoke2_s1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.hub1_spoke2.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub1_spoke2.address_space[0], 5, 1)]
}
