provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    aws = {
    }
    panos = {
      source = "PaloAltoNetworks/panos"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}


data "azurerm_subscriptions" "azsub" {
  display_name_contains = var.subscription
}

resource "azurerm_resource_group" "rg1" {
  name     = "${var.name}-rg1"
  location = var.region_m
}

resource "azurerm_resource_group" "rg2" {
  name     = "${var.name}-rg2"
  location = var.region_b
}


resource "azurerm_ssh_public_key" "rg1" {
  name                = var.name
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

resource "azurerm_ssh_public_key" "rg2" {
  name                = var.name
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

module "basic_rg1" {
  source = "../modules/basic"
  name   = var.name

  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  mgmt_cidrs          = [for r in var.mgmt_ips : "${r.cidr}"]
  split_route_tables = {
    left_u = {
      nh                            = local.private_ips.left_u_hub_ilb["obew"]
      disable_bgp_route_propagation = true
    }
    right = {
      nh = local.private_ips.right_hub_fw["eth1_1_ip"]
    }
  }
}

module "basic_rg2" {
  source = "../modules/basic"
  name   = var.name

  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  mgmt_cidrs          = [for r in var.mgmt_ips : "${r.cidr}"]
  split_route_tables = {
    left_b = {
      nh                            = local.private_ips.left_b_hub_ilb["obew"]
      disable_bgp_route_propagation = true
    }
    right = {
      nh = local.private_ips.right_hub_fw["eth1_1_ip"]
    }
  }
}
