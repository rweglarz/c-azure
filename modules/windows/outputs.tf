output "public_ip" {
  value = try(azurerm_public_ip.this[0].ip_address, null)
}

output "private_ip_address" {
  value = azurerm_network_interface.this.ip_configuration[0].private_ip_address
}

output "network_interface_id" {
  value = azurerm_network_interface.this.id
}
