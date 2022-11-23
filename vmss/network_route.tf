resource "azurerm_route_table" "srv_sec" {
  name                = "${var.name}-srv-sec"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
resource "azurerm_route" "srv_sec_dg_fw" {
  name                   = "dg_fw"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv_sec.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_lb.fw-int.frontend_ip_configuration[0].private_ip_address
}
resource "azurerm_route" "srv_sec_srv_sec" {
  count                  = length(azurerm_subnet.srv_sec)
  name                   = "srv-${count.index}"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv_sec.name
  address_prefix         = azurerm_subnet.srv_sec[count.index].address_prefixes[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_lb.fw-int.frontend_ip_configuration[0].private_ip_address
}
resource "azurerm_route" "srv_sec_spoke_a" {
  name                   = "spoke"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv_sec.name
  address_prefix         = azurerm_virtual_network.spoke_a.address_space[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_lb.fw-int.frontend_ip_configuration[0].private_ip_address
}
resource "azurerm_subnet_route_table_association" "srv_sec" {
  count          = length(azurerm_subnet.srv_sec)
  subnet_id      = azurerm_subnet.srv_sec[count.index].id
  route_table_id = azurerm_route_table.srv_sec.id
}


resource "azurerm_route_table" "srv_spoke_a" {
  name                = "${var.name}-srv-spoke-a"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
resource "azurerm_route" "srv_spoke_a_dg_fw" {
  name                   = "dg_fw-a"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv_spoke_a.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_lb.fw-int.frontend_ip_configuration[0].private_ip_address
}
resource "azurerm_route" "srv_spoke_srv_spoke" {
  count                  = length(azurerm_subnet.srv_spoke_a)
  name                   = "srv-${count.index}"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv_spoke_a.name
  address_prefix         = azurerm_subnet.srv_spoke_a[count.index].address_prefixes[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_lb.fw-int.frontend_ip_configuration[0].private_ip_address
}
resource "azurerm_route" "srv_spoke_a-srv_spoke_b" {
  name                   = "spoke_b"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv_spoke_a.name
  address_prefix         = azurerm_virtual_network.spoke_b.address_space[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_lb.fw-int.frontend_ip_configuration[0].private_ip_address
}

resource "azurerm_route_table" "srv_spoke_b" {
  name                = "${var.name}-srv-spoke-b"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
resource "azurerm_route" "srv_spoke_b_dg_fw" {
  name                   = "dg_fw-b"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv_spoke_b.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_lb.fw-int.frontend_ip_configuration[1].private_ip_address
}
resource "azurerm_route" "srv_spoke_b_r_1" {
  name                   = "r1"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv_spoke_b.name
  address_prefix         = "192.168.1.1/32"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "172.29.32.102"
}
resource "azurerm_route" "srv_spoke_b_r_2" {
  name                   = "r2"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv_spoke_b.name
  address_prefix         = "192.168.1.2/32"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "172.29.32.103"
}
resource "azurerm_route" "srv_spoke_b-srv_spoke_a" {
  name                   = "spoke_a"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv_spoke_b.name
  address_prefix         = azurerm_virtual_network.spoke_a.address_space[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_lb.fw-int.frontend_ip_configuration[1].private_ip_address
}
/*
resource "azurerm_route" "srv_spoke_srv_sec" {
  count                  = length(azurerm_subnet.srv_spoke)
  name                   = "secsrv-${count.index}"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv_spoke.name
  address_prefix         = azurerm_subnet.srv_sec[count.index].address_prefixes[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_lb.this[0].frontend_ip_configuration[0].private_ip_address
}
*/
resource "azurerm_subnet_route_table_association" "srv_spoke_a" {
  count          = length(azurerm_subnet.srv_spoke_a)
  subnet_id      = azurerm_subnet.srv_spoke_a[count.index].id
  route_table_id = azurerm_route_table.srv_spoke_a.id
}
resource "azurerm_subnet_route_table_association" "srv_spoke_b" {
  count          = length(azurerm_subnet.srv_spoke_b)
  subnet_id      = azurerm_subnet.srv_spoke_b[count.index].id
  route_table_id = azurerm_route_table.srv_spoke_b.id
}

resource "azurerm_route_table" "spoke_a" {
  name                = "${var.name}-spoke_a"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.spoke_a.id
}

resource "azurerm_route_table" "appgw" {
  name                = "${var.name}-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
resource "azurerm_route" "appgw_aks" {
  name                   = "dg_fw"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.appgw.name
  address_prefix         = azurerm_virtual_network.aks.address_space[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_lb.fw-int.frontend_ip_configuration[0].private_ip_address
}
resource "azurerm_subnet_route_table_association" "appgw" {
  subnet_id      = azurerm_subnet.appgw.id
  route_table_id = azurerm_route_table.appgw.id
}





resource "azurerm_virtual_network_peering" "sec-spoke_a" {
  name                      = "${var.name}-sec-spoke_a"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_a.id
}
resource "azurerm_virtual_network_peering" "spoke-sec_a" {
  name                      = "${var.name}-spoke-sec_a"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_a.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}
resource "azurerm_virtual_network_peering" "sec-spoke_b" {
  name                      = "${var.name}-sec-spoke_b"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_b.id
}
resource "azurerm_virtual_network_peering" "spoke-sec_b" {
  name                      = "${var.name}-spoke-sec_b"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_b.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "sec-aks" {
  name                      = "${var.name}-sec-aks"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.aks.id
}
resource "azurerm_virtual_network_peering" "aks-sec" {
  name                      = "${var.name}-aks-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.aks.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}
resource "azurerm_virtual_network_peering" "sec-appgw" {
  name                      = "${var.name}-sec-appgw"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.appgw.id
}
resource "azurerm_virtual_network_peering" "appgw-sec" {
  name                      = "${var.name}-appgw-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.appgw.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}
