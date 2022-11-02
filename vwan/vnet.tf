resource "azurerm_virtual_network" "hub1-sec" {
  name                = "${var.name}-hub1-sec"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [cidrsubnet(var.hub1_cidr, 4, 2)]
}
resource "azurerm_virtual_network" "hub1-vnet1" {
  name                = "${var.name}-hub1-vnet1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [cidrsubnet(var.hub1_cidr, 4, 3)]
}
resource "azurerm_virtual_network" "hub1-vnet2" {
  name                = "${var.name}-hub1-vnet2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [cidrsubnet(var.hub1_cidr, 4, 4)]
}


resource "azurerm_subnet" "hub1-sec-mgmt" {
  name                 = "${var.name}-hub1-sec-mgmt"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.hub1-sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub1-sec.address_space[0], 5, 0)]
}
resource "azurerm_subnet" "hub1-sec-data" {
  name                 = "${var.name}-hub1-sec-data"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.hub1-sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub1-sec.address_space[0], 5, 1)]
}
resource "azurerm_subnet" "hub1-vnet1-s1" {
  name                 = "${var.name}-hub1-vnet1-s1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.hub1-vnet1.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub1-vnet1.address_space[0], 5, 0)]
}



resource "azurerm_virtual_network" "hub2-sec" {
  name                = "${var.name}-hub2-sec"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  address_space       = [cidrsubnet(var.hub2_cidr, 4, 2)]
}
resource "azurerm_virtual_network" "hub2-vnet1" {
  name                = "${var.name}-hub2-vnet1"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  address_space       = [cidrsubnet(var.hub2_cidr, 4, 3)]
}
resource "azurerm_virtual_network" "hub2-vnet2" {
  name                = "${var.name}-hub2-vnet2"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  address_space       = [cidrsubnet(var.hub2_cidr, 4, 4)]
}

resource "azurerm_subnet" "hub2-vnet1-s1" {
  name                 = "${var.name}-hub2-vnet1-s1"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.hub2-vnet1.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub2-vnet1.address_space[0], 5, 0)]
}

