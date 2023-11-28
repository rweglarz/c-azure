provider "azurerm" {
  features {}
}

data "azurerm_subscriptions" "azsub" {
  display_name_contains = var.subscription
}


resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.region
  tags = {
    StoreStatus = "DND"
  }
}

resource "azurerm_ssh_public_key" "this" {
  name                = var.name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  public_key          = file("~/.ssh/id_rsa.pub")
}
