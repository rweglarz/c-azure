resource "azurerm_virtual_network" "hub1_sec" {
  name                = "${local.dname}-hub1-sec"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [cidrsubnet(var.hub1_cidr, 4, 8)]
}

resource "azurerm_subnet" "hub1_sec_mgmt" {
  name                 = "${local.dname}-hub1-sec-mgmt"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.hub1_sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub1_sec.address_space[0], 4, 0)]
}

resource "azurerm_subnet" "hub1_sec_data" {
  name                 = "${local.dname}-hub1-sec-data"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.hub1_sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub1_sec.address_space[0], 4, 1)]
}

resource "azurerm_route_table" "hub1_sec_data" {
  name                = "${local.dname}-hub1-sec-data"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
}


resource "azurerm_route_table" "hub1_sec_spokes" {
  name                = "${local.dname}-hub1-sec-spokes"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
}

resource "azurerm_route" "hub1_sec_spokes_172" {
  name                   = "172"
  resource_group_name    = azurerm_resource_group.rg1.name
  route_table_name       = azurerm_route_table.hub1_sec_spokes.name
  address_prefix         = "172.16.0.0/12"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = cidrhost(azurerm_subnet.hub1_sec_data.address_prefixes[0], 5)
}

resource "azurerm_subnet_route_table_association" "hub1_sec_spoke1_s1" {
  subnet_id      = azurerm_subnet.hub1_sec_spoke1_s1.id
  route_table_id = azurerm_route_table.hub1_sec_spokes.id
}


resource "azurerm_virtual_network" "hub1_sec_spoke1" {
  name                = "${local.dname}-hub1-sec-spoke1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [cidrsubnet(var.hub1_cidr, 4, 9)]
}

resource "azurerm_subnet" "hub1_sec_spoke1_s1" {
  name                 = "${local.dname}-hub1-sec-spoke1-s1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.hub1_sec_spoke1.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub1_sec_spoke1.address_space[0], 4, 0)]
}



resource "azurerm_virtual_network" "hub1_sec_spoke2" {
  name                = "${local.dname}-hub1-sec-spoke2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [cidrsubnet(var.hub1_cidr, 4, 10)]
}


resource "azurerm_subnet_route_table_association" "hub1_sec_data" {
  subnet_id      = azurerm_subnet.hub1_sec_data.id
  route_table_id = azurerm_route_table.hub1_sec_data.id
}

resource "azurerm_virtual_network_peering" "hub1_sec_spoke1-hub1_sec" {
  name                      = "${local.dname}-hub1-vnet2-hub1-sec"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = azurerm_virtual_network.hub1_sec_spoke1.name
  remote_virtual_network_id = azurerm_virtual_network.hub1_sec.id
  allow_forwarded_traffic   = true
}
resource "azurerm_virtual_network_peering" "hub1_sec-hub1_sec_spoke1" {
  name                      = "${local.dname}-hub1-sec-hub1-spoke1"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = azurerm_virtual_network.hub1_sec.name
  remote_virtual_network_id = azurerm_virtual_network.hub1_sec_spoke1.id
}


resource "azurerm_subnet_network_security_group_association" "hub1_sec_mgmt" {
  subnet_id                 = azurerm_subnet.hub1_sec_mgmt.id
  network_security_group_id = azurerm_network_security_group.rg1_mgmt.id
}


module "hub1_sec_fw" {
  source = "../modules/vmseries"

  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  name                = "${local.dname}-hub1-sec-fw"
  username            = var.username
  password            = var.password
  interfaces = {
    mgmt = {
      device_index = 0
      name         = "${local.dname}-hub1-sec-fw-mgmt"
      subnet_id    = azurerm_subnet.hub1_sec_mgmt.id
      public_ip    = true
    }
    data = {
      device_index         = 1
      name                 = "${local.dname}-hub1-sec-fw-data"
      subnet_id            = azurerm_subnet.hub1_sec_data.id
      private_ip_address   = cidrhost(azurerm_subnet.hub1_sec_data.address_prefixes[0], 5)
      enable_ip_forwarding = true
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["pan_pub"],
    var.bootstrap_options["hub1"],
  )
}

