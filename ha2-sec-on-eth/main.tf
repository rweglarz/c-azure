provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      version = "~>4.0"
    }
    google = {
      version = "~>6.10"
    }
    panos = {
      source = "PaloAltoNetworks/panos"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}

locals {
  name = terraform.workspace == "default" ? var.name : format("%s-%s", var.name, terraform.workspace)
  dns_prefix = terraform.workspace == "default" ? "ha" : format("ha-%s", terraform.workspace)
}

resource "random_id" "did" {
  byte_length = 3 #to workaround delete recreate cross regions
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.name}-${random_id.did.hex}"
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
  name = local.name

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  mgmt_cidrs          = [for r in var.mgmt_ips : "${r.cidr}"]
  route_tables_params = {
    servers = {
      nh = replace(panos_panorama_ethernet_interface.azure_ha2_eth1_3.static_ips[0], "/\\/../", "")
    }
  }
}

resource "panos_vm_auth_key" "this" {
  hours = 24*30*6
}
