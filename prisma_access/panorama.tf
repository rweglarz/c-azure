module "bootstrap" {
  source = "PaloAltoNetworks/vmseries-modules/azurerm//modules/bootstrap"

  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  storage_account_name = lower(replace("${var.name}-sa", "/-/", ""))
  storage_share_name   = lower("${var.name}-ssn")
}


module "panorama" {
  source = "PaloAltoNetworks/vmseries-modules/azurerm//modules/panorama"

  panorama_name       = "${var.name}-panorama"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  avzone              = 1

  interface = [ // Only one interface in Panorama VM is supported
    {
      name               = "mgmt"
      #name               = "${var.name}-panorama"
      subnet_id          = module.vnet_panorama.subnets["panorama"].id
      private_ip_address = cidrhost(module.vnet_panorama.subnets["panorama"].address_prefixes[0], 5)
      public_ip          = true
      public_ip_name     = "${var.name}-panorama"
    }
  ]
  panorama_size               = "Standard_D5_v2"
  username                    = var.username
  password                    = var.password
  panorama_version            = var.panorama_version
  boot_diagnostic_storage_uri = module.bootstrap.storage_account.primary_blob_endpoint
  logging_disks = {
    logs-1 = {
      size : "256"
      zone : "1"
      lun : "1"
    }
  }
}

output "panorama_ip" {
  description = "Panorama IP"
  value       = module.panorama.mgmt_ip_address
}

