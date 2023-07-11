resource "azurerm_virtual_network" "aks" {
  name                = "${var.name}-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vnet_cidr, 0, 0)]
}

resource "azurerm_subnet" "aks" {
  name                 = "${var.name}-aks"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.aks.address_space[0], 5, 0)]
}
resource "azurerm_subnet" "appgw" {
  name                 = "${var.name}-appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.aks.address_space[0], 5, 1)]
}

resource "azurerm_subnet" "fw_prv" {
  name                 = "${var.name}-fw-prv"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.aks.address_space[0], 5, 2)]
}

resource "azurerm_subnet" "fw_pub" {
  name                 = "${var.name}-fw-pub"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.aks.address_space[0], 5, 3)]
}


resource "azurerm_route_table" "aks" {
  name                = "${var.name}-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "aks_dg" {
  name                   = "dg"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.aks.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "Internet"
}

resource "azurerm_route" "aks_appgw" {
  count = var.fw_prv_ip!=null ? 1 : 0

  name                   = "appgw"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.aks.name
  address_prefix         = azurerm_subnet.appgw.address_prefixes[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.fw_prv_ip
}

resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.aks.id
}


resource "azurerm_route_table" "appgw" {
  name                = "${var.name}-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "appgw_aks" {
  count = var.fw_prv_ip!=null ? 1 : 0
  name                   = "aks"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.appgw.name
  address_prefix         = azurerm_subnet.aks.address_prefixes[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.fw_prv_ip
}

resource "azurerm_subnet_route_table_association" "appgw" {
  subnet_id      = azurerm_subnet.appgw.id
  route_table_id = azurerm_route_table.appgw.id
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
resource "azurerm_subnet_nat_gateway_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = azurerm_nat_gateway.ngw.id
}


output "nat_ip" {
  value = azurerm_public_ip.ngw.ip_address
}
