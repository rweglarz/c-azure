provider "azurerm" {
  features {}
}

data "azurerm_subscriptions" "azsub" {
  display_name_contains = "AzureSEEMEA"
}

resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = "North Europe"
}

resource "azurerm_ssh_public_key" "this" {
  name                = var.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

terraform {
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
    }
  }
}


provider "panos" {
  json_config_file = "panorama-creds.json"
}


module "basic" {
  source = "../modules/basic"
  name   = var.name

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  mgmt_cidrs = concat(
    [for r in var.mgmt_ips : "${r.cidr}"],
    [for r in var.tmp_ips : "${r.cidr}"],
  )
  split_route_tables = {
    internal = {
      nh                            = azurerm_lb.fw_int.frontend_ip_configuration[1].private_ip_address
      disable_bgp_route_propagation = true
    }
  }
}
