resource "azurerm_application_insights" "vmss" {
  name                = "${var.name}-app-insights-vmss"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "other"
}

resource "azurerm_application_insights" "cn" {
  name                = "${var.name}-app-insights-cn"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "other"
}



output "application_insights_instrumentation_key" {
  sensitive = true

  value = {
    cn   = azurerm_application_insights.cn.instrumentation_key
    vmss = azurerm_application_insights.vmss.instrumentation_key
  }
}
