provider "azurerm" {
  features {}
}
data "azurerm_subscriptions" "azsub" {
  display_name_contains = var.subscription
}

resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = "Central US"
}


resource "azurerm_ssh_public_key" "rwe" {
  name                = "rweglarz"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("~/.ssh/id_rsa.pub")
}
