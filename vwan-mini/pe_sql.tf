resource "random_password" "sql_password" {
  length      = 20
  special     = true
  min_numeric = 1
  min_upper   = 1
  min_lower   = 1
  min_special = 1
}

resource "azurerm_mssql_server" "this" {
  for_each = local.paas

  name                         = replace("${var.name}-${each.key}", "-", "")
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  administrator_login          = "adm"
  administrator_login_password = random_password.sql_password.result
  version                      = "12.0"
}

resource "azurerm_mssql_database" "db" {
  for_each = local.paas

  name      = "test"
  server_id = azurerm_mssql_server.this[each.key].id
}

resource "azurerm_private_endpoint" "sql" {
  for_each = local.paas

  name                = "${var.name}-sql-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = each.key
    private_connection_resource_id = azurerm_mssql_server.this[each.key].id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdns-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.pl["sql"].id
    ]
  }
}
