provider "azurerm" {
  features {}
}
data "azurerm_subscriptions" "azsub" {
  display_name_contains = "AzureSEEMEA"
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



resource "azurerm_resource_group" "rg1" {
  name     = "${var.name}-rg1"
  location = var.region1
}
resource "azurerm_resource_group" "rg2" {
  name     = "${var.name}-rg2"
  location = var.region2
}


resource "azurerm_ssh_public_key" "rg1-rwe" {
  name                = "rg1-rweglarz"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  public_key          = file("~/.ssh/id_rsa.pub")
}
resource "azurerm_ssh_public_key" "rg2-rwe" {
  name                = "rg2-rweglarz"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  public_key          = file("~/.ssh/id_rsa.pub")
}
