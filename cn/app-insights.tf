resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name}-log-analytics"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "this" {
  name                = "${var.name}-app-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "other"
}

output "application_insights_instrumentation" {
  sensitive = true
  value = {
    app_id = azurerm_application_insights.this.app_id,
    key    = azurerm_application_insights.this.instrumentation_key,
  }
}
