output "public_ip" {
  value = azurerm_public_ip.this.ip_address
}

output "private_ip_address" {
  value = azurerm_network_interface.this.ip_configuration[0].private_ip_address
}
