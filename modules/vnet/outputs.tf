output "vnet" {
  value = azurerm_virtual_network.this
}

output "subnets" {
  value = { for k, v in azurerm_subnet.this : k => v }
}
