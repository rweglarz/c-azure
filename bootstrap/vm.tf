module "bs" {
  for_each = var.firewalls
  source   = "github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules//modules/bootstrap?ref=v1.1.0"

  name                 = replace("${var.name}-${each.key}", "/-/", "")
  storage_share_name   = each.key
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  files                = each.value.bs_files
  storage_allow_vnet_subnet_ids = [
    module.net.subnets.mgmt.id
  ]
  storage_allow_inbound_public_ips = concat(
    [for k,v in var.mgmt_ips: v.cidr if (!contains(["255.255.255.255","255.255.255.254"], cidrnetmask(v.cidr)))],
    [
      "20.105.209.72",   #serial console west-europe
      "52.146.139.220",  #serial console west-europe
  ]
  )
}

locals {
  bootstrap_options = {for fk,fv in var.firewalls: fk =>
    join(";", concat(
    [for k, v in fv.bs_opts : "${k}=${v}"],
    try(fv.full_bs==true ? [
      "storage-account=${module.bs[fk].storage_account.name}",
      "access-key=${module.bs[fk].storage_account.primary_access_key}",
      "file-share=${module.bs[fk].storage_share.name}",
      "share-directory=None"
    ] : null, []),
  ))
  }
}

module "fw" {
  for_each = var.firewalls
  source = "github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules//modules/vmseries?ref=v1.1.0"

  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  name                = "${var.name}-${each.key}"
  username            = var.username
  password            = var.password
  img_version         = coalesce(each.value.fw_ver, var.fw_version)
  img_sku             = "byol"
  vm_size             = try(each.value.vm_size, "Standard_D3_v2")
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

  bootstrap_options = local.bootstrap_options[each.key]
  diagnostics_storage_uri = module.bs[each.key].storage_account.primary_blob_endpoint
}

output "bs" {
  value = { for k,v in var.firewalls: k =>
    join(";", concat(
    [for k, v in v.bs_opts : "${k}=${v}"],
    try(v.full_bs==true ? [
      "storage-account=${module.bs[k].storage_account.name}",
      "access-key=${module.bs[k].storage_account.primary_access_key}",
      "file-share=${module.bs[k].storage_share.name}",
      "share-directory=None"
    ] : null, []),
  ))}
  sensitive = true
}

output "fws_ips" {
  value = { for k,v in var.firewalls: k=> {
      ip   = module.fw[k].mgmt_ip_address
      fqdn = trim(azurerm_dns_a_record.this[k].fqdn, ".")
    }
  }
}
