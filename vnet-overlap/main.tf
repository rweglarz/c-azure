provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "random_id" "did" {
  byte_length = 3 #to workaround delete recreate cross regions
}
locals {
  dname = "${var.name}-${random_id.did.hex}"
}

resource "azurerm_resource_group" "rg" {
  name     = local.dname
  location = var.region
}

provider "aws" {
  region = "eu-central-1"
}

terraform {
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
    }
    azurerm = {
      version = "~>4.6"
    }
  }
}
provider "panos" {
  json_config_file = "panorama_creds.json"
}


module "basic" {
  source = "../modules/basic"
  name = var.name

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  mgmt_cidrs          = [for r in var.mgmt_ips : "${r.cidr}"]
  route_tables_params = {
    net1_app = {
      nh = module.net1_unique.private_ip_address
    }
    net2_app = {
      nh = module.net2_unique.private_ip_address
    }
    unique = {
      nh = module.sec_1.private_ip_address
    }
  }
}



resource "azurerm_ssh_public_key" "rwe" {
  name                = "rweglarz"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("~/.ssh/id_rsa.pub")
}
