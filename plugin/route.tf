resource "azurerm_route_table" "all_via_inbound" {
  name                = "${var.name}-all-via-inbound"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "all_via_inbound" {
  for_each = {
    appgw_ext = azurerm_virtual_network.appgw_ext.address_space[0]
    appgw_int = azurerm_virtual_network.appgw_int.address_space[0]
    w1        = azurerm_virtual_network.w1.address_space[0]
    w2        = azurerm_virtual_network.w2.address_space[0]
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.all_via_inbound.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.inb_int_lb
}

resource "azurerm_route_table" "all_via_ewo" {
  name                = "${var.name}-all-via-ewo"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "all_via_ewo" {
  for_each = {
    appgw_ext = azurerm_virtual_network.appgw_ext.address_space[0]
    appgw_int = azurerm_virtual_network.appgw_int.address_space[0]
    w1        = azurerm_virtual_network.w1.address_space[0]
    w2        = azurerm_virtual_network.w2.address_space[0]
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.all_via_ewo.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.ewo_int_lb
}

resource "azurerm_route_table" "appgw_int_2" {
  name                = "${var.name}-appgw_int_2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "appgw_int_2-via_inbound" {
  for_each = {
    appgw_ext = azurerm_virtual_network.appgw_ext.address_space[0]
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.appgw_int_2.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.inb_int_lb
}

resource "azurerm_route" "appgw_int_2-via_ewo" {
  for_each = {
    appgw_int = azurerm_virtual_network.appgw_int.address_space[0]
    w1        = azurerm_virtual_network.w1.address_space[0]
    w2        = azurerm_virtual_network.w2.address_space[0]
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.appgw_int_2.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.ewo_int_lb
}




resource "azurerm_subnet_route_table_association" "appgw_ext" {
  subnet_id      = azurerm_subnet.appgw_ext_s1.id
  route_table_id = azurerm_route_table.all_via_inbound.id
}
resource "azurerm_subnet_route_table_association" "appgw_int_s1" {
  subnet_id      = azurerm_subnet.appgw_int_s1.id
  route_table_id = azurerm_route_table.all_via_ewo.id
}
resource "azurerm_subnet_route_table_association" "appgw_int_s2" {
  subnet_id      = azurerm_subnet.appgw_int_s2.id
  route_table_id = azurerm_route_table.appgw_int_2.id
}
resource "azurerm_subnet_route_table_association" "w1" {
  subnet_id      = azurerm_subnet.w1_s1.id
  route_table_id = azurerm_route_table.all_via_ewo.id
}
