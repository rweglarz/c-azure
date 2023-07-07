module "appgw1" {
  source = "../modules/appgw"

  name                = "${var.name}-appgw-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_sec.subnets["appgw1"].id
  tier                = "Standard_v2"
  use_public_ip       = true
  private_ip_address  = cidrhost(module.vnet_sec.subnets["appgw1"].address_prefixes[0], 5)

  virtual_hosts = {
    "dummy" = {
      priority = 11
      host_names = [
        "dummy.internal",
      ]
      ip_addresses = []
      backend_port = 81
    }
  }

  managed_by_agic = false
}

module "appgw2" {
  source = "../modules/appgw"

  name                = "${var.name}-appgw-2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_sec.subnets["appgw2"].id
  tier                = "Standard_v2"
  use_public_ip       = true
  private_ip_address  = cidrhost(module.vnet_sec.subnets["appgw2"].address_prefixes[0], 5)

  virtual_hosts = {
    "dummy" = {
      priority = 11
      host_names = [
        "dummy.internal",
      ]
      ip_addresses = []
      backend_port = 82
    }
  }

  managed_by_agic = false
}
