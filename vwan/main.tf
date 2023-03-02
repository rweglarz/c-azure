provider "azurerm" {
  features {}
}
data "azurerm_subscriptions" "azsub" {
  display_name_contains = var.subscription
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

resource "random_id" "did" {
  byte_length = 3 #to workaround delete recreate cross regions
}
locals {
  dname = "${var.name}-${random_id.did.hex}"
}



resource "azurerm_resource_group" "rg1" {
  name     = "${local.dname}-rg1"
  location = var.region1
}
resource "azurerm_resource_group" "rg2" {
  name     = "${local.dname}-rg2"
  location = var.region2
}


resource "azurerm_ssh_public_key" "rg1" {
  name                = "${local.dname}-rg1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  public_key          = file("~/.ssh/id_rsa.pub")
}
resource "azurerm_ssh_public_key" "rg2" {
  name                = "${local.dname}-rg2"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

