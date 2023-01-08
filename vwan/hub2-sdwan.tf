resource "azurerm_virtual_network" "hub2_sdwan" {
  name                = "${local.dname}-hub2-sdwan"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  address_space       = [cidrsubnet(var.hub2_cidr, 4, 2)]
}

resource "azurerm_subnet" "hub2_sdwan_mgmt" {
  name                 = "${local.dname}-hub2-sdwan-mgmt"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.hub2_sdwan.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub2_sdwan.address_space[0], 4, 0)]
}

resource "azurerm_subnet" "hub2_sdwan_internet" {
  name                 = "${local.dname}-hub2-sdwan-internet"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.hub2_sdwan.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub2_sdwan.address_space[0], 4, 1)]
}

resource "azurerm_subnet" "hub2_sdwan_private" {
  name                 = "${local.dname}-hub2-sdwan-private"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.hub2_sdwan.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub2_sdwan.address_space[0], 4, 2)]
}

resource "azurerm_subnet_network_security_group_association" "hub2_sdwan_mgmt" {
  subnet_id                 = azurerm_subnet.hub2_sdwan_mgmt.id
  network_security_group_id = azurerm_network_security_group.rg2_mgmt.id
}


locals {
  hub2_sdwan_fw1 = {
    mgmt_ip   = cidrhost(azurerm_subnet.hub2_sdwan_mgmt.address_prefixes[0], 5),
    eth1_1_ip = cidrhost(azurerm_subnet.hub2_sdwan_internet.address_prefixes[0], 5),
    eth1_1_gw = cidrhost(azurerm_subnet.hub2_sdwan_internet.address_prefixes[0], 1),
    eth1_2_ip = cidrhost(azurerm_subnet.hub2_sdwan_private.address_prefixes[0], 5),
  }
  hub2_sdwan_fw2 = {
    mgmt_ip   = cidrhost(azurerm_subnet.hub2_sdwan_mgmt.address_prefixes[0], 6),
    eth1_1_ip = cidrhost(azurerm_subnet.hub2_sdwan_internet.address_prefixes[0], 6),
    eth1_1_gw = cidrhost(azurerm_subnet.hub2_sdwan_internet.address_prefixes[0], 1),
    eth1_2_ip = cidrhost(azurerm_subnet.hub2_sdwan_private.address_prefixes[0], 6),
  }
}


module "hub2_sdwan_fw1" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules//modules/vmseries"

  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  name                = "${local.dname}-hub2-sdwan-fw1"
  username            = var.username
  password            = var.password
  img_version         = var.fw_version
  img_sku             = "byol"
  interfaces = [
    {
      name               = "${local.dname}-hub2-sdwan-fw1-mgmt"
      subnet_id          = azurerm_subnet.hub2_sdwan_mgmt.id
      private_ip_address = local.hub2_sdwan_fw1["mgmt_ip"]
      create_public_ip   = true
    },
    {
      name                 = "${local.dname}-hub2-sdwan-fw1-internet"
      subnet_id            = azurerm_subnet.hub2_sdwan_internet.id
      private_ip_address   = local.hub2_sdwan_fw1["eth1_1_ip"]
      enable_ip_forwarding = true
      create_public_ip     = true
    },
    {
      name                 = "${local.dname}-hub2-sdwan-fw1-private"
      subnet_id            = azurerm_subnet.hub2_sdwan_private.id
      private_ip_address   = local.hub2_sdwan_fw1["eth1_2_ip"]
      enable_ip_forwarding = true
    },
  ]

  bootstrap_options = join(";", concat(
    [for k, v in var.bootstrap_options["common"] : "${k}=${v}"],
    [for k, v in var.bootstrap_options["pan_pub"] : "${k}=${v}"],
    [for k, v in var.bootstrap_options["hub2_sdwan_fw1"] : "${k}=${v}"],
  ))
}

module "hub2_sdwan_fw2" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules//modules/vmseries"

  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  name                = "${local.dname}-hub2-sdwan-fw2"
  username            = var.username
  password            = var.password
  img_version         = var.fw_version
  img_sku             = "byol"
  interfaces = [
    {
      name               = "${local.dname}-hub2-sdwan-fw2-mgmt"
      subnet_id          = azurerm_subnet.hub2_sdwan_mgmt.id
      private_ip_address = local.hub2_sdwan_fw2["mgmt_ip"]
      create_public_ip   = true
    },
    {
      name                 = "${local.dname}-hub2-sdwan-fw2-internet"
      subnet_id            = azurerm_subnet.hub2_sdwan_internet.id
      private_ip_address   = local.hub2_sdwan_fw2["eth1_1_ip"]
      enable_ip_forwarding = true
      create_public_ip     = true
    },
    {
      name                 = "${local.dname}-hub2-sdwan-fw2-private"
      subnet_id            = azurerm_subnet.hub2_sdwan_private.id
      private_ip_address   = local.hub2_sdwan_fw2["eth1_2_ip"]
      enable_ip_forwarding = true
    },
  ]

  bootstrap_options = join(";", concat(
    [for k, v in var.bootstrap_options["common"] : "${k}=${v}"],
    [for k, v in var.bootstrap_options["pan_pub"] : "${k}=${v}"],
    [for k, v in var.bootstrap_options["hub2_sdwan_fw2"] : "${k}=${v}"],
  ))
}


