module "basic" {
  source = "../modules/basic"
  name   = var.name

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  mgmt_cidrs          = [for r in var.mgmt_ips : "${r.cidr}"]
  split_route_tables = {
  }
}

locals {
  vnet_address_space = {
    net = [var.cidr]
  }
}

module "net" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = var.name
  address_space = local.vnet_address_space.net

  subnets = {
    "mgmt" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.net[0], 4, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "internet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.net[0], 4, 1)]
    },
    "private" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.net[0], 4, 2)]
    },
  }
}

