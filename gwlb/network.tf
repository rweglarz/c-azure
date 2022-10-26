resource "azurerm_virtual_network" "sec" {
  name                = "${var.name}-sec"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vpc_cidr, 4, 0)]
}
resource "azurerm_virtual_network" "app" {
  name                = "${var.name}-app"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vpc_cidr, 4, 1)]
}

resource "azurerm_subnet" "mgmt" {
  name                 = "${var.name}-sec-mgmt"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 4, 0)]
}
resource "azurerm_subnet" "data" {
  name                 = "${var.name}-sec"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 4, 1)]
}

resource "azurerm_subnet" "app" {
  name                 = "${var.name}-app"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.app.address_space[0], 4, 0)]
}
resource "azurerm_subnet" "fake-gw" {
  name                 = "${var.name}-fake-gw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.app.address_space[0], 4, 1)]
}


resource "azurerm_public_ip" "this" {
  name                = "${var.name}-natgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "this" {
  name                    = "${var.name}-natgw"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.this.id
}
resource "azurerm_subnet_nat_gateway_association" "this" {
  subnet_id      = azurerm_subnet.mgmt.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}


output "natgateway" {
  value = azurerm_public_ip.this.ip_address
}



resource "azurerm_virtual_network_peering" "p1-a" {
  name                      = "${var.name}-sec-spoke"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.app.id
}
resource "azurerm_virtual_network_peering" "p1-b" {
  name                      = "${var.name}-spoke-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.app.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}


resource "azurerm_route_table" "app" {
  name                = "${var.name}-app-via-fake"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
resource "azurerm_route" "app-dg" {
  count                  = var.use_fake_gw
  name                   = "dg_fake"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.app.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.fake-gw.private_ip_address
}
resource "azurerm_subnet_route_table_association" "app-dg" {
  subnet_id      = azurerm_subnet.app.id
  route_table_id = azurerm_route_table.app.id
}
