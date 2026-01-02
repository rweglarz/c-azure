data "azurerm_client_config" "current" {}


resource "azurerm_key_vault" "this" {
  for_each = local.paas

  name                        = replace("${var.name}-${each.key}", "-", "")
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "Get",
    ]
    secret_permissions = [
      "Get",
    ]
    storage_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_private_endpoint" "kv" {
  for_each = local.paas

  name                = "${var.name}-kv-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = each.key
    private_connection_resource_id = azurerm_key_vault.this[each.key].id
    subresource_names              = ["Vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdns-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.pl["kv"].id
    ]
  }
}
