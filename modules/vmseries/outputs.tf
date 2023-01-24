output "mgmt_ip_address" {
  value = azurerm_public_ip.this["mgmt"].ip_address
}

output "public_ips" {
  value = { for k, v in azurerm_public_ip.this: k => v.ip_address}
}

output "interfaces" {
  value = local.interfaces
}
