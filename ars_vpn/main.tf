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

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = "West Europe"
}


resource "azurerm_ssh_public_key" "this" {
  name                = var.name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

module "basic" {
  source = "../modules/basic"
  name   = var.name

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  mgmt_cidrs          = [for r in var.mgmt_ips : "${r.cidr}"]
  split_route_tables = {
    left_u = {
      nh                            = local.private_ips.left_u_hub_ilb["obew"]
      disable_bgp_route_propagation = true
    }
    left_b = {
      nh                            = local.private_ips.left_b_hub_ilb["obew"]
      disable_bgp_route_propagation = true
    }
    right = {
      nh = local.private_ips.right_hub_fw["eth1_1_ip"]
    }
  }
}
