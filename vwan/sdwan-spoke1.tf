resource "azurerm_virtual_network" "sdwan_spoke1" {
  name                = "${local.dname}-sdwan-spoke1"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  address_space       = [cidrsubnet(var.ext_spokes_cidr, 4, 1)]
}

resource "azurerm_subnet" "sdwan_spoke1_mgmt" {
  name                 = "${local.dname}-sdwan-spoke1-mgmt"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.sdwan_spoke1.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sdwan_spoke1.address_space[0], 4, 0)]
}

resource "azurerm_subnet" "sdwan_spoke1_internet" {
  name                 = "${local.dname}-sdwan-spoke1-internet"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.sdwan_spoke1.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sdwan_spoke1.address_space[0], 4, 1)]
}

resource "azurerm_subnet" "sdwan_spoke1_private" {
  name                 = "${local.dname}-sdwan-spoke1-private"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.sdwan_spoke1.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.sdwan_spoke1.address_space[0], 4, 2)]
}

resource "azurerm_subnet_network_security_group_association" "sdwan_spoke1_mgmt" {
  subnet_id                 = azurerm_subnet.sdwan_spoke1_mgmt.id
  network_security_group_id = azurerm_network_security_group.rg2_mgmt.id
}


locals {
  sdwan_spoke1_fw = {
    mgmt_ip   = cidrhost(azurerm_subnet.sdwan_spoke1_mgmt.address_prefixes[0], 5),
    eth1_1_ip = cidrhost(azurerm_subnet.sdwan_spoke1_internet.address_prefixes[0], 5),
    eth1_1_gw = cidrhost(azurerm_subnet.sdwan_spoke1_internet.address_prefixes[0], 1),
    eth1_2_ip = cidrhost(azurerm_subnet.sdwan_spoke1_private.address_prefixes[0], 5),
  }
}


module "sdwan_spoke1_fw" {
  source = "../modules/vmseries"

  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  name                = "${local.dname}-sdwan-spoke1-fw"
  username            = var.username
  password            = var.password
  interfaces = {
    mgmt = {
      device_index       = 0
      name               = "${local.dname}-sdwan-spoke1-fw-mgmt"
      subnet_id          = azurerm_subnet.sdwan_spoke1_mgmt.id
      private_ip_address = local.sdwan_spoke1_fw["mgmt_ip"]
      public_ip          = true
    }
    internet = {
      device_index         = 1
      name                 = "${local.dname}-sdwan-spoke1-fw-internet"
      subnet_id            = azurerm_subnet.sdwan_spoke1_internet.id
      private_ip_address   = local.sdwan_spoke1_fw["eth1_1_ip"]
      enable_ip_forwarding = true
      public_ip            = true
    }
    private = {
      device_index         = 2
      name                 = "${local.dname}-sdwan-spoke1-fw-private"
      subnet_id            = azurerm_subnet.sdwan_spoke1_private.id
      private_ip_address   = local.sdwan_spoke1_fw["eth1_2_ip"]
      enable_ip_forwarding = true
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["sdwan_spoke1"],
  )
}

