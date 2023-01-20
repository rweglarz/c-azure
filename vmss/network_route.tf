resource "azurerm_subnet_route_table_association" "sec_srv" {
  subnet_id      = azurerm_subnet.sec_srv.id
  route_table_id = module.basic.route_table_id["mgmt-via-igw"]["internal"]
}

resource "azurerm_subnet_route_table_association" "spoke_a_s1" {
  subnet_id      = azurerm_subnet.spoke_a_s1.id
  route_table_id = module.basic.route_table_id["mgmt-via-igw"]["internal"]
}

resource "azurerm_subnet_route_table_association" "spoke_a_s2" {
  subnet_id      = azurerm_subnet.spoke_a_s2.id
  route_table_id = module.basic.route_table_id["mgmt-via-igw"]["internal"]
}

resource "azurerm_subnet_route_table_association" "spoke_b_s1" {
  subnet_id      = azurerm_subnet.spoke_b_s1.id
  route_table_id = module.basic.route_table_id["mgmt-via-igw"]["internal"]
}

resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = module.basic.route_table_id["mgmt-via-igw"]["internal"]
}

resource "azurerm_subnet_route_table_association" "appgw" {
  subnet_id      = azurerm_subnet.appgw.id
  route_table_id = module.basic.route_table_id["private-via-fw"]["internal"]
}



resource "azurerm_virtual_network_peering" "sec-spoke_a" {
  name                      = "${var.name}-sec--spoke-a"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_a.id
}

resource "azurerm_virtual_network_peering" "spoke_a-sec" {
  name                      = "${var.name}-spoke-a--sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_a.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}


resource "azurerm_virtual_network_peering" "sec-spoke_b" {
  name                      = "${var.name}-sec--spoke_b"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_b.id
}

resource "azurerm_virtual_network_peering" "spoke_b-sec" {
  name                      = "${var.name}-spoke-b--sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_b.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}


resource "azurerm_virtual_network_peering" "sec-aks" {
  name                      = "${var.name}-sec--aks"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.aks.id
}

resource "azurerm_virtual_network_peering" "aks-sec" {
  name                      = "${var.name}-aks--sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.aks.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}


resource "azurerm_virtual_network_peering" "sec-appgw" {
  name                      = "${var.name}-sec--appgw"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.appgw.id
}

resource "azurerm_virtual_network_peering" "appgw-sec" {
  name                      = "${var.name}-appgw--sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.appgw.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}
