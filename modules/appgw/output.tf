output "id" {
  value = var.managed_by_agic ? azurerm_application_gateway.appgw_agic[0].id : azurerm_application_gateway.appgw_regular[0].id
}
