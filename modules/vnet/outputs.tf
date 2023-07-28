output "name" {
  value = azurerm_virtual_network.this.name
}

output "id" {
  value = azurerm_virtual_network.this.id
}

output "vnet" {
  value = azurerm_virtual_network.this
}

output "subnets" {
  value = { for k, v in azurerm_subnet.this : k => v }
}
