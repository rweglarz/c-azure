module "bs" {
  for_each = var.firewalls
  source = "github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules//modules/bootstrap"

  storage_account_name = replace("${var.name}-${each.key}", "/-/", "")
  storage_share_name   = each.key
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  files                = each.value.bs_files
}

module "fw" {
  for_each = var.firewalls
  source = "github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules//modules/vmseries?ref=bc46ac4"

  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  name                = "${var.name}-${each.key}"
  username            = var.username
  password            = var.password
  img_version         = coalesce(each.value.fw_ver, var.fw_version)
  img_sku             = "byol"
  interfaces = [
    {
      name             = "${var.name}-${each.key}-mgmt"
      subnet_id        = module.net.subnets["mgmt"].id
      create_public_ip = true
    },
    {
      name                 = "${var.name}-${each.key}-internet"
      subnet_id            = module.net.subnets["private"].id
      enable_ip_forwarding = true
    },
    {
      name                 = "${var.name}-${each.key}-private"
      subnet_id            = module.net.subnets["private"].id
      enable_ip_forwarding = true
    },
  ]

  bootstrap_options = join(";", concat([for k, v in each.value.bs_opts : "${k}=${v}"],))
  # [
  #     #"storage-account=${azurerm_storage_account.this.name}",
  #     #"access-key=${azurerm_storage_account.this.primary_access_key}",
  #     "storage-account=${module.bs[each.key].storage_account.name}",
  #     "access-key=${module.bs[each.key].storage_account.primary_access_key}",
  #     "file-share=${module.bs[each.key].storage_share.name}",
  #     "share-directory=None"
  #   ],
  # ))
  diagnostics_storage_uri = module.bs[each.key].storage_account.primary_blob_endpoint
}


output "fws_ips" {
  value = { for k,v in var.firewalls: k=> {
      ip   = module.fw[k].mgmt_ip_address 
      fqdn = trim(azurerm_dns_a_record.this[k].fqdn, ".")
    }
  }
}
