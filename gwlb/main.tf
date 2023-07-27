provider "azurerm" {
  features {}
}
data "azurerm_subscriptions" "azsub" {
  display_name_contains = var.azure_subscription
}

resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = "West Europe"
}


resource "azurerm_ssh_public_key" "this" {
  name                = "${var.name}-key"
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
  split_route_tables = {
    ilb = {
      nh = azurerm_lb.fw_int.frontend_ip_configuration[0].private_ip_address
    }
  }
}
