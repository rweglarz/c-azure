resource "azurerm_virtual_network" "sec" {
  name                = "${var.name}-sec"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vnet_cidr, 3, 0)]
}
resource "azurerm_virtual_network" "spoke_a" {
  name                = "${var.name}-spoke_a"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vnet_cidr, 5, 4)]
}
resource "azurerm_virtual_network" "spoke_b" {
  name                = "${var.name}-spoke_b"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vnet_cidr, 5, 5)]
}
resource "azurerm_virtual_network" "aks" {
  name                = "${var.name}-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vnet_cidr, 5, 6)]
}
resource "azurerm_virtual_network" "appgw" {
  name                = "${var.name}-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vnet_cidr, 5, 7)]
}


resource "azurerm_subnet" "mgmt" {
  name                 = "${var.name}-sec-mgmt"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 5, 0)]
}
resource "azurerm_subnet" "data" {
  count                = 3
  name                 = "${var.name}-sec-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 5, 1 + count.index)]
}
resource "azurerm_subnet" "vpng" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 5, 4)]
}
resource "azurerm_subnet" "rs" {
  name                 = "RouteServerSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 5, 5)]
}
resource "azurerm_subnet" "srv_sec" {
  count                = 2
  name                 = "${var.name}-srvsec-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 5, 6 + count.index)]
}
resource "azurerm_subnet" "srv_spoke_a" {
  count                = 2
  name                 = "${var.name}-srvspoke_a-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_a.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.spoke_a.address_space[0], 3, count.index)]
}
resource "azurerm_subnet" "srv_spoke_b" {
  count                = 2
  name                 = "${var.name}-srvspoke_b-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_b.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.spoke_b.address_space[0], 3, count.index)]
}
resource "azurerm_subnet" "aks" {
  name                 = "${var.name}-aks"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [azurerm_virtual_network.aks.address_space[0]]
}
resource "azurerm_subnet" "appgw" {
  name                 = "${var.name}-appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.appgw.name
  address_prefixes     = [azurerm_virtual_network.appgw.address_space[0]]
}





resource "azurerm_public_ip" "ngw" {
  name                = "nat-gateway-publicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "ngw" {
  name                    = "nat-gateway"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "ngw" {
  nat_gateway_id       = azurerm_nat_gateway.ngw.id
  public_ip_address_id = azurerm_public_ip.ngw.id
}
resource "azurerm_subnet_nat_gateway_association" "mgmt" {
  subnet_id      = azurerm_subnet.mgmt.id
  nat_gateway_id = azurerm_nat_gateway.ngw.id
}
resource "azurerm_subnet_nat_gateway_association" "sec" {
  subnet_id      = azurerm_subnet.data[0].id
  nat_gateway_id = azurerm_nat_gateway.ngw.id
}




resource "azurerm_network_security_group" "fws-ext" {
  name                = "${var.name}-fws-ext"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                   = "data-inbound"
    priority               = 1000
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "data-outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "fws-ext" {
  subnet_id                 = azurerm_subnet.data[0].id
  network_security_group_id = azurerm_network_security_group.fws-ext.id
}




output "nat_ip" {
  value = azurerm_public_ip.ngw.ip_address
}
