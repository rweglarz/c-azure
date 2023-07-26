resource "azurerm_virtual_network" "sec" {
  name                = "${var.name}-sec"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.sec_vpc_cidr]
}

resource "azurerm_subnet" "public" {
  name                 = "${var.name}-public"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 2, 0)]
}
resource "azurerm_subnet" "private" {
  name                 = "${var.name}-private"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 2, 1)]
}



resource "azurerm_subnet_network_security_group_association" "sec-private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.all.id
}

resource "azurerm_subnet_network_security_group_association" "sec-public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.all.id
}



resource "azurerm_public_ip" "dnatip" {
  count = 2
  name                 = "${var.name}-cngfw-dnat-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
