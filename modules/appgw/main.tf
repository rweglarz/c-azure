resource "azurerm_public_ip" "this" {
  count = var.tier == "Standard_v2" ? 1 : 0

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}
