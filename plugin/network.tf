resource "azurerm_virtual_network" "sec" {
  name                = "${var.name}-sec"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vpc_cidr, 1, 0)]
}

resource "azurerm_virtual_network" "appgw_ext" {
  name                = "${var.name}-appgw-ext"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vpc_cidr, 3, 4)]
}

resource "azurerm_virtual_network" "appgw_int" {
  name                = "${var.name}-appgw-int"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vpc_cidr, 3, 5)]
}

resource "azurerm_virtual_network" "w1" {
  name                = "${var.name}-w1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vpc_cidr, 3, 6)]
}

resource "azurerm_virtual_network" "w2" {
  name                = "${var.name}-w2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.vpc_cidr, 3, 7)]
}



resource "azurerm_subnet" "appgw_ext_s1" {
  name                 = "${var.name}-appgw-ext-s1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.appgw_ext.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.appgw_ext.address_space[0], 4, 0)]
}

resource "azurerm_subnet" "appgw_int_s1" {
  name                 = "${var.name}-appgw-int-s1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.appgw_int.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.appgw_int.address_space[0], 4, 0)]
}

resource "azurerm_subnet" "appgw_int_s2" {
  name                 = "${var.name}-appgw-int-s2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.appgw_int.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.appgw_int.address_space[0], 4, 1)]
}

resource "azurerm_subnet" "w1_s1" {
  name                 = "${var.name}-w1-s1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.w1.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.w1.address_space[0], 4, 0)]
}

resource "azurerm_subnet" "w2_s1" {
  name                 = "${var.name}-w2-s1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.w2.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.w2.address_space[0], 4, 0)]
}



resource "azurerm_virtual_network_peering" "appgw_ext-sec" {
  name                      = "${var.name}-appgw_ext-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.appgw_ext.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "sec-appgw_ext" {
  name                      = "${var.name}-sec-appgw_ext"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.appgw_ext.id
}


resource "azurerm_virtual_network_peering" "appgw_int-sec" {
  name                      = "${var.name}-appgw_int-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.appgw_int.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "sec-appgw_int" {
  name                      = "${var.name}-sec-appgw_int"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.appgw_int.id
}


resource "azurerm_virtual_network_peering" "w1-sec" {
  name                      = "${var.name}-w1-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.w1.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "sec-w1" {
  name                      = "${var.name}-sec-w1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.w1.id
}

resource "azurerm_virtual_network_peering" "w2-sec" {
  name                      = "${var.name}-w2-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.w2.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "sec-w2" {
  name                      = "${var.name}-sec-w2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.w2.id
}
