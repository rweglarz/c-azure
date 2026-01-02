resource "azurerm_service_plan" "this" {
  count = var.deploy_paas ? 1 : 0

  name                = "${var.name}-appsvc"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}


resource "azurerm_linux_web_app" "this" {
  for_each = local.paas

  name                = replace("${var.name}-${each.key}", "-", "")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.this[0].id

  https_only = false
  public_network_access_enabled = false

  site_config {
    minimum_tls_version = "1.2"
    application_stack {
      python_version = "3.13"
    }
  }
}

resource "azurerm_app_service_source_control" "this" {
  for_each = local.paas

  app_id                 = azurerm_linux_web_app.this[each.key].id
  repo_url               = "https://github.com/Azure-Samples/msdocs-python-flask-webapp-quickstart"
  branch                 = "main"
  use_manual_integration = true
  use_mercurial          = false
}

resource "azurerm_private_endpoint" "appsvc" {
  for_each = local.paas

  name                = "${var.name}-appsvc-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = each.value.subnet_id


  private_service_connection {
    name                           = "appsvc"
    private_connection_resource_id = azurerm_linux_web_app.this[each.key].id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdns-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.pl["appsvc"].id
    ]
  }
}

