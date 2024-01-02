resource "azurerm_virtual_network" "sec" {
  name                = "${var.name}-sec"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.cidr, 2, 0)]
}

resource "azurerm_subnet" "mgmt" {
  name                 = "${var.name}-sec-mgmt"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 3, 0)]
}
resource "azurerm_subnet" "data" {
  count                = 3
  name                 = "${var.name}-sec-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 3, 1+count.index)]
}

resource "azurerm_subnet" "sec_srv5" {
  name                 = "${var.name}-sec-srv5"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 3, 4)]
}
resource "azurerm_subnet" "sec_srv6" {
  name                 = "${var.name}-sec-srv6"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sec.address_space[0], 3, 5)]
}

resource "azurerm_route_table" "srv5_6" {
  name                = "${var.name}-srv-5-6"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
resource "azurerm_route" "srv5_6-srv5" {
  name                   = "srv5"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv5_6.name
  address_prefix         = azurerm_subnet.sec_srv5.address_prefixes[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = replace(panos_panorama_loopback_interface.azure_ha2_lo3.static_ips[0], "/\\/../", "")
}
resource "azurerm_route" "srv5_6-srv6" {
  name                   = "srv6"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv5_6.name
  address_prefix         = azurerm_subnet.sec_srv6.address_prefixes[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = replace(panos_panorama_loopback_interface.azure_ha2_lo3.static_ips[0], "/\\/../", "")
}
resource "azurerm_route" "srv5_6-mgmt-via-ig" {
  for_each               = {for e in var.mgmt_ips: e.cidr => e.description}
  name                   = replace("mgmt-${each.key}", "/[ \\/]/", "_")
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv5_6.name
  address_prefix         = each.key
  next_hop_type          = "Internet"
}
resource "azurerm_route" "srv5_6-dg" {
  name                   = "dg"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv5_6.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = replace(panos_panorama_loopback_interface.azure_ha2_lo3.static_ips[0], "/\\/../", "")
}

resource "azurerm_subnet_route_table_association" "srv5" {
  subnet_id      = azurerm_subnet.sec_srv5.id
  route_table_id = azurerm_route_table.srv5_6.id
}
resource "azurerm_subnet_route_table_association" "srv6" {
  subnet_id      = azurerm_subnet.sec_srv6.id
  route_table_id = azurerm_route_table.srv5_6.id
}
