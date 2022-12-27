resource "azurerm_virtual_network" "hub2_spoke1" {
  name                = "${var.name}-hub2-spoke1"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  address_space       = [cidrsubnet(var.hub2_cidr, 4, 3)]
}

resource "azurerm_subnet" "hub2_spoke1_s1" {
  name                 = "${var.name}-hub2-spoke1-s1"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.hub2_spoke1.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub2_spoke1.address_space[0], 4, 1)]
}



resource "azurerm_virtual_network" "hub2_spoke2" {
  name                = "${var.name}-hub2-spoke2"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  address_space       = [cidrsubnet(var.hub2_cidr, 4, 4)]
}

resource "azurerm_subnet" "hub2_spoke2_s1" {
  name                 = "${var.name}-hub2-spoke2-s1"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.hub2_spoke2.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub2_spoke2.address_space[0], 4, 1)]
}
