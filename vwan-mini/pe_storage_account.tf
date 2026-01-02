resource "azurerm_storage_account" "this" {
  for_each = local.paas

  name                     = replace("${var.name}-${each.key}", "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = concat(
      [for k,v in var.mgmt_ips: v.cidr if (!contains(["255.255.255.255","255.255.255.254"], cidrnetmask(v.cidr)))],
    )
  }
}

resource "azurerm_private_endpoint" "sa" {
  for_each = local.paas

  name                = "${var.name}-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = each.key
    private_connection_resource_id = azurerm_storage_account.this[each.key].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdns-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.pl["blob"].id
    ]
  }
}

resource "azurerm_storage_container" "this" {
  for_each = local.paas

  name                  = "content"
  storage_account_id    = azurerm_storage_account.this[each.key].id
  container_access_type = "blob"
}

resource "local_file" "example_file" {
  for_each = local.paas
  filename = "${path.module}/t/${each.key}.txt"
  content  = "This is a test file ${each.key}\n"
}

resource "azurerm_storage_blob" "blob" {
  for_each = local.paas

  name                   = "example.txt"
  storage_account_name   = azurerm_storage_account.this[each.key].name
  storage_container_name = azurerm_storage_container.this[each.key].name
  type                   = "Block"
  source                 = local_file.example_file[each.key].filename
}
