resource "azurerm_application_insights" "this" {
  name                = "${var.name}-app-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "other"
}

output "application_insights_instrumentation" {
  sensitive = true
  value = {
    app_id = azurerm_application_insights.this.app_id,
    key    = azurerm_application_insights.this.instrumentation_key,
  }
}
