module "vnet_sec" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-sec"
  address_space = local.vnet_address_space.sec

  subnets = {
    "mgmt" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.sec[0], 3, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "internet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 1)]
    },
    "internal" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 2)]
    },
    "jump" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.sec[0], 3, 3)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "RouteServerSubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 6)]
    },
    "GatewaySubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 7)]
    },
  }
}

module "vnet_panorama" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-panorama"
  address_space = local.vnet_address_space.panorama

  subnets = {
    "panorama" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.panorama[0], 3, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
  }
}

