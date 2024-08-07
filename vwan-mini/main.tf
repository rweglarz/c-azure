provider "azurerm" {
  features {}
}

provider "aws" {
  region = "eu-central-1"
}

terraform {
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
      version = "~>1.11"
    }
    aws = {
      version = "~>5.40"
    }
    azurerm = {
      version = "~>3.95"
    }
  }
}
provider "panos" {
  json_config_file = "panorama_creds.json"
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
  tags     = var.tags
}

resource "azurerm_ssh_public_key" "this" {
  name                = local.dname
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
  route_tables_params  = {
    hub1 = {
      nh = local.private_ip.hub1_sec_lb
    }
  }
}
