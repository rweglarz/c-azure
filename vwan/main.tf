provider "azurerm" {
  features {}
}
data "azurerm_subscriptions" "azsub" {
  display_name_contains = "AzureSEEMEA"
}

provider "aws" {
  region = "eu-central-1"
}

terraform {
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
    }
  }
}
provider "panos" {
  json_config_file = "panorama_creds.json"
}



resource "azurerm_resource_group" "rg1" {
  name     = "${var.name}-rg1"
  location = var.region1
}
resource "azurerm_resource_group" "rg2" {
  name     = "${var.name}-rg2"
  location = var.region2
}


resource "azurerm_ssh_public_key" "rg1-rwe" {
  name                = "rg1-rweglarz"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  public_key          = file("~/.ssh/id_rsa.pub")
}
resource "azurerm_ssh_public_key" "rg2-rwe" {
  name                = "rg2-rweglarz"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  public_key          = file("~/.ssh/id_rsa.pub")
}


resource "azurerm_network_security_group" "rg1_mgmt" {
  name                = "${var.name}-rg1-mgmt"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  security_rule {
    name                   = "inbound-172"
    priority               = 1000
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "*"
    source_address_prefixes = [
      "172.16.0.0/12",
    ]
    destination_address_prefix = "*"
  }

  security_rule {
    name                   = "inbound-mgmt-ips"
    priority               = 1001
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

resource "azurerm_network_security_group" "rg2_mgmt" {
  name                = "${var.name}-rg2-mgmt"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  security_rule {
    name                   = "inbound-172"
    priority               = 1000
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "*"
    source_address_prefixes = [
      "172.16.0.0/12",
    ]
    destination_address_prefix = "*"
  }

  security_rule {
    name                   = "inbound-mgmt-ips"
    priority               = 1001
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

