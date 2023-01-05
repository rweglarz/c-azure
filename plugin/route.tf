resource "azurerm_route_table" "all" {
  name                = "${var.name}-all"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "all_appgw_ext" {
  name                   = "appgw_ext"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.all.name
  address_prefix         = azurerm_virtual_network.appgw_ext.address_space[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.ewo_int_lb
}

resource "azurerm_route" "all_appgw_int" {
  name                   = "appgw_int"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.all.name
  address_prefix         = azurerm_virtual_network.appgw_int.address_space[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.ewo_int_lb
}

resource "azurerm_route" "all_w1" {
  name                   = "w1"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.all.name
  address_prefix         = azurerm_virtual_network.w1.address_space[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.ewo_int_lb
}

resource "azurerm_route" "all_w2" {
  name                   = "w2"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.all.name
  address_prefix         = azurerm_virtual_network.w2.address_space[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.ewo_int_lb
}



resource "azurerm_subnet_route_table_association" "appgw_ext" {
  subnet_id      = azurerm_subnet.appgw_ext_s1.id
  route_table_id = azurerm_route_table.all.id
}
resource "azurerm_subnet_route_table_association" "appgw_int_s1" {
  subnet_id      = azurerm_subnet.appgw_int_s1.id
  route_table_id = azurerm_route_table.all.id
}
resource "azurerm_subnet_route_table_association" "appgw_int_s2" {
  subnet_id      = azurerm_subnet.appgw_int_s2.id
  route_table_id = azurerm_route_table.all.id
}
resource "azurerm_subnet_route_table_association" "w1" {
  subnet_id      = azurerm_subnet.w1_s1.id
  route_table_id = azurerm_route_table.all.id
}


resource "azurerm_route_table" "appgw_ext" {
  name                = "${var.name}-appgw-ext"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "appgw_ext-int" {
  name                   = "to-int-appgw"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.appgw_ext.name
  address_prefix         = "172.29.0.0/24"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.ewo_int_lb
}

/*
resource "azurerm_subnet_route_table_association" "appgw_ext" {
  subnet_id      = azurerm_subnet.appgw_ext_s1.id
  route_table_id = azurerm_route_table.appgw_ext.id
}
*/


resource "azurerm_route_table" "appgw_int" {
  name                = "${var.name}-appgw-int"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "appgw_int-ext" {
  name                   = "to-ext-appgw"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.appgw_int.name
  address_prefix         = "192.168.0.0/22"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.ewo_int_lb
}

/*
resource "azurerm_subnet_route_table_association" "appgw_int" {
  subnet_id      = azurerm_subnet.appgw_int_s2.id
  route_table_id = azurerm_route_table.appgw_int.id
}
*/

