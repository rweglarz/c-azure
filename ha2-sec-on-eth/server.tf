resource "azurerm_route_table" "via-fw" {
  name                = "${var.name}-via-fw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
resource "azurerm_route" "dg-via-floating" {
  name                   = "dg_floating"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.via-fw.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = replace(panos_panorama_ethernet_interface.azure_ha2_eth1_3.static_ips[0], "/\\/../", "")
}
resource "azurerm_route" "ew-via-floating" {
  name                   = "ew_fw"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.via-fw.name
  address_prefix         = "172.16.0.0/12"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = replace(panos_panorama_ethernet_interface.azure_ha2_eth1_3.static_ips[0], "/\\/../", "")
}
resource "azurerm_route" "mgmt-via-ig" {
  for_each               = {for e in var.mgmt_ips: e.cidr => e.description}
  name                   = replace("mgmt-${each.key}", "/[ \\/]/", "_")
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.via-fw.name
  address_prefix         = each.key
  next_hop_type          = "Internet"
}

resource "azurerm_virtual_network" "srv0" {
  name                = "${var.name}-srv0"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.cidr, 2, 1)]
}

resource "azurerm_subnet" "srv0-s1" {
  name                 = "${var.name}-srv0-s1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.srv0.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.srv0.address_space[0], 3, 0)]
}

resource "azurerm_virtual_network_peering" "srv0-fw" {
  name                      = "${var.name}-srv0-fw"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.srv0.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "fw-srv0" {
  name                      = "${var.name}-fw-srv0"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.srv0.id
}

resource "azurerm_subnet_route_table_association" "srv0" {
  subnet_id      = azurerm_subnet.srv0-s1.id
  route_table_id = azurerm_route_table.via-fw.id
}






resource "azurerm_virtual_network" "srv1" {
  name                = "${var.name}-srv1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [cidrsubnet(var.cidr, 2, 2)]
}

resource "azurerm_subnet" "srv1-s1" {
  name                 = "${var.name}-srv1-s1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.srv1.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.srv1.address_space[0], 3, 0)]
}

resource "azurerm_virtual_network_peering" "srv1-fw" {
  name                      = "${var.name}-srv1-fw"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.srv1.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "fw-srv1" {
  name                      = "${var.name}-fw-srv1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.srv1.id
}

resource "azurerm_subnet_route_table_association" "srv1" {
  subnet_id      = azurerm_subnet.srv1-s1.id
  route_table_id = azurerm_route_table.via-fw.id
}


module "srv0" {
  source = "../modules/linux"

  name                = "${var.name}-linux0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.srv0-s1.id
  private_ip_address  = cidrhost(azurerm_subnet.srv0-s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  security_group      = azurerm_network_security_group.mgmt.id
  associate_nsg       = true
}

module "srv1" {
  source = "../modules/linux"

  name                = "${var.name}-linux1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.srv1-s1.id
  private_ip_address  = cidrhost(azurerm_subnet.srv1-s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  security_group      = azurerm_network_security_group.mgmt.id
  associate_nsg       = true
}

module "srv5" {
  source = "../modules/linux"

  name                = "${var.name}-srv5"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.sec_srv5.id
  private_ip_address  = cidrhost(azurerm_subnet.sec_srv5.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  security_group      = azurerm_network_security_group.mgmt.id
  associate_nsg       = true
}

module "srv6" {
  source = "../modules/linux"

  name                = "${var.name}-srv6"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.sec_srv6.id
  private_ip_address  = cidrhost(azurerm_subnet.sec_srv6.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  security_group      = azurerm_network_security_group.mgmt.id
  associate_nsg       = true
}
