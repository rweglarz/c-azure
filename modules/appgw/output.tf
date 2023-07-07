output "id" {
  value = var.managed_by_agic ? azurerm_application_gateway.appgw_agic[0].id : azurerm_application_gateway.appgw_regular[0].id
}

output "public_ip_address" {
  value = var.tier == "Standard_v2" ? azurerm_public_ip.this[0].ip_address : null
}

output "backend_address_pools" {
  value = var.managed_by_agic ? azurerm_application_gateway.appgw_agic[0].backend_address_pool[*] : azurerm_application_gateway.appgw_regular[0].backend_address_pool[*]
}
