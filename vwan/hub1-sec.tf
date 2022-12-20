resource "azurerm_virtual_network" "hub1_sec" {
  name                = "${var.name}-hub1_sec"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [cidrsubnet(var.hub1_cidr, 4, 2)]
}

resource "azurerm_subnet" "hub1_sec_mgmt" {
  name                 = "${var.name}-hub1_sec_mgmt"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.hub1_sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub1_sec.address_space[0], 5, 0)]
}

resource "azurerm_subnet" "hub1_sec_data" {
  name                 = "${var.name}-hub1_sec_data"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.hub1_sec.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub1_sec.address_space[0], 5, 1)]
}

resource "azurerm_route_table" "hub1_sec_data" {
  name                = "${var.name}-hub1_sec_data"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
}



resource "azurerm_virtual_network" "hub1_sec_spoke1" {
  name                = "${var.name}-hub1_sec_spoke1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [cidrsubnet(var.hub1_cidr, 4, 9)]
}

resource "azurerm_subnet" "hub1_sec_spoke1_s1" {
  name                 = "${var.name}-hub1_sec_spoke1_s1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.hub1_sec_spoke1.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub1_sec_spoke1.address_space[0], 4, 0)]
}



resource "azurerm_virtual_network" "hub1_sec_spoke2" {
  name                = "${var.name}-hub1_sec_spoke2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [cidrsubnet(var.hub1_cidr, 4, 10)]
}


resource "azurerm_subnet_route_table_association" "hub1_sec_data" {
  subnet_id      = azurerm_subnet.hub1_sec_data.id
  route_table_id = azurerm_route_table.hub1_sec_data.id
}

resource "azurerm_virtual_network_peering" "hub1_sec_spoke1-hub1_sec" {
  name                      = "${var.name}-hub1_vnet2-hub1_sec"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = azurerm_virtual_network.hub1_sec_spoke1.name
  remote_virtual_network_id = azurerm_virtual_network.hub1_sec.id
  allow_forwarded_traffic   = true
}
resource "azurerm_virtual_network_peering" "hub1_sec-hub1_sec_spoke1" {
  name                      = "${var.name}-hub1_sec-hub1_spoke1"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = azurerm_virtual_network.hub1_sec.name
  remote_virtual_network_id = azurerm_virtual_network.hub1_sec_spoke1.id
}


module "hub1_sec_fw" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules//modules/vmseries"

  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  name                = "${var.name}-hub1-sec-fw"
  username            = var.username
  password            = var.password
  img_version         = var.fw_version
  img_sku             = "byol"
  interfaces = [
    {
      name             = "${var.name}-hub1_sec_fw_mgmt"
      subnet_id        = azurerm_subnet.hub1_sec_mgmt.id
      create_public_ip = true
    },
    {
      name                 = "${var.name}-hub1_sec_fw_data"
      subnet_id            = azurerm_subnet.hub1_sec_data.id
      private_ip_address   = cidrhost(azurerm_subnet.hub1_sec_data.address_prefixes[0], 5)
      enable_ip_forwarding = true
    },
  ]

  bootstrap_options = join(";", concat(
    [for k, v in var.bootstrap_options["common"] : "${k}=${v}"],
    [for k, v in var.bootstrap_options["pan_pub"] : "${k}=${v}"],
    [for k, v in var.bootstrap_options["hub1"] : "${k}=${v}"],
  ))
}

