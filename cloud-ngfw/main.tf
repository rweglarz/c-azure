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

terraform {
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
      version = "~>1.11"
    }
    azurerm = {
      version = "~>4.18"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}


resource "azurerm_ssh_public_key" "rwe" {
  name                = "rweglarz"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("~/.ssh/id_rsa.pub")
}
