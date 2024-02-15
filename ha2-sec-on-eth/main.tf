provider "azurerm" {
  features {}
}
data "azurerm_subscriptions" "azsub" {
  display_name_contains = var.azure_subscription
}


terraform {
  required_version = ">= 1.6"
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}


resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.region
}


resource "azurerm_ssh_public_key" "rwe" {
  name                = "rweglarz"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

module "basic" {
  source = "../modules/basic"
  name = var.name

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  mgmt_cidrs          = [for r in var.mgmt_ips : "${r.cidr}"]
  split_route_tables = {
    servers = {
      nh = replace(panos_panorama_ethernet_interface.azure_ha2_eth1_3.static_ips[0], "/\\/../", "")
    }
  }
}
