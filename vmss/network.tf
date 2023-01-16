resource "azurerm_virtual_network" "sec" {
  name                = "${var.name}-sec"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vnet_cidr, 3, 0)]
}

resource "azurerm_virtual_network" "spoke_a" {
  name                = "${var.name}-spoke-a"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vnet_cidr, 5, 4)]
}

resource "azurerm_virtual_network" "spoke_b" {
  name                = "${var.name}-spoke-b"
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

resource "azurerm_virtual_network" "dmz" {
  name                = "${var.name}-dmz"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vnet_cidr, 5, 8)]
}




resource "azurerm_subnet" "sec_mgmt" {
  name                 = "${var.name}-sec-mgmt"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 4, 0)]
}

resource "azurerm_subnet" "sec_internet" {
  name                 = "${var.name}-sec-internet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 4, 1)]
}

resource "azurerm_subnet" "sec_internal" {
  name                 = "${var.name}-sec-internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 4, 2)]
}

resource "azurerm_subnet" "sec_dmz" {
  name                 = "${var.name}-sec-dmz"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 4, 3)]
}

resource "azurerm_subnet" "sec_vpng" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 4, 4)]
}

resource "azurerm_subnet" "sec_srv" {
  name                 = "${var.name}-sec-srv"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 4, 6)]
}

resource "azurerm_subnet" "spoke_a_s1" {
  name                 = "${var.name}-spoke-a-s1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_a.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.spoke_a.address_space[0], 4, 0)]
}

resource "azurerm_subnet" "spoke_a_s2" {
  name                 = "${var.name}-spoke-a-s2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_a.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.spoke_a.address_space[0], 4, 1)]
}

resource "azurerm_subnet" "spoke_b_s1" {
  name                 = "${var.name}-spoke-b-s1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_b.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.spoke_b.address_space[0], 4, 0)]
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
  name                = "${var.name}-nat-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "ngw" {
  name                    = "${var.name}-nat-gateway"
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
  subnet_id      = azurerm_subnet.sec_mgmt.id
  nat_gateway_id = azurerm_nat_gateway.ngw.id
}
resource "azurerm_subnet_nat_gateway_association" "sec" {
  subnet_id      = azurerm_subnet.sec_internet.id
  nat_gateway_id = azurerm_nat_gateway.ngw.id
}



resource "azurerm_subnet_network_security_group_association" "sec_internet" {
  subnet_id                 = azurerm_subnet.sec_internet.id
  network_security_group_id = module.basic.sg_id["wide-open"]
}




output "nat_ip" {
  value = azurerm_public_ip.ngw.ip_address
}
