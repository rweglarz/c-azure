provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    aws = {
      version = "~>5.58"
    }
    azurerm = {
      version = "~>3.112"
    }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.region
}

resource "azurerm_ssh_public_key" "rg" {
  name                = var.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

module "basic" {
  source = "../modules/basic"
  name   = var.name

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  mgmt_cidrs          = [for r in var.mgmt_ips : "${r.cidr}"]
  route_tables_params = {
    fw = {
      nh = local.private_ips.fw
      bgp_route_propagation_enabled = true
    }
  }
}
