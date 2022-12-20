module "hub2_sec_spoke1_h" {
  source = "../modules/linux"

  name                = "${var.name}-hub2-sec-spoke1"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  subnet_id           = azurerm_subnet.hub2_sec_spoke1_s1.id
  private_ip_address  = cidrhost(azurerm_subnet.hub2_sec_spoke1_s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg2-rwe.public_key
  security_group      = azurerm_network_security_group.rg2-sg.id
}

module "hub2_spoke1_h" {
  source = "../modules/linux"

  name                = "${var.name}-hub2-spoke1"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  subnet_id           = azurerm_subnet.hub2_spoke1_s1.id
  private_ip_address  = cidrhost(azurerm_subnet.hub2_spoke1_s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg2-rwe.public_key
  security_group      = azurerm_network_security_group.rg2-sg.id
}

module "hub2_spoke2_h" {
  source = "../modules/linux"

  name                = "${var.name}-hub2-spoke2"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  subnet_id           = azurerm_subnet.hub2_spoke2_s1.id
  private_ip_address  = cidrhost(azurerm_subnet.hub2_spoke2_s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg2-rwe.public_key
  security_group      = azurerm_network_security_group.rg2-sg.id
}



resource "azurerm_network_security_group" "rg2-sg" {
  name                = "${var.name}-hub2-vnet1-s1-h"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  security_rule {
    name                   = "data-inbound"
    priority               = 1000
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "*"
    source_address_prefixes = concat(
      [for r in var.mgmt_ips : "${r.cidr}"]
    )
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "data-outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
