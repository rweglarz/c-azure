module "vnet_spoke0" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = "${var.name}-spoke0"
  address_space = [cidrsubnet(var.cidr, 2, 1)]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }
}

module "vnet_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = "${var.name}-spoke1"
  address_space = [cidrsubnet(var.cidr, 2, 2)]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }
}

module "vnet_peering-spoke0-transit" {
  source = "../modules/vnet_peering"

  on_local = {
    resource_group_name     = azurerm_resource_group.this.name
    virtual_network_name    = module.vnet_spoke0.vnet.name
    virtual_network_id      = module.vnet_spoke0.vnet.id
    use_remote_gateways     = false
    allow_forwarded_traffic = true
  }

  on_remote = {
    resource_group_name    = azurerm_resource_group.this.name
    virtual_network_name   = module.vnet_transit.vnet.name
    virtual_network_id     = module.vnet_transit.vnet.id
    allow_gateway_transit  = true
  }
}

module "vnet_peering-spoke1-transit" {
  source = "../modules/vnet_peering"

  on_local = {
    resource_group_name     = azurerm_resource_group.this.name
    virtual_network_name    = module.vnet_spoke1.vnet.name
    virtual_network_id      = module.vnet_spoke1.vnet.id
    use_remote_gateways     = false
    allow_forwarded_traffic = true
  }

  on_remote = {
    resource_group_name    = azurerm_resource_group.this.name
    virtual_network_name   = module.vnet_transit.vnet.name
    virtual_network_id     = module.vnet_transit.vnet.id
    allow_gateway_transit  = true
  }
}

resource "azurerm_subnet_route_table_association" "spokes" {
  for_each = {
    spoke0 = module.vnet_spoke0.subnets.s0.id
    spoke1 = module.vnet_spoke1.subnets.s0.id
  }
  subnet_id      = each.value
  route_table_id = module.basic.route_table_id.mgmt-via-igw-dg-via-nh.fw
}



module "spoke0_h" {
  source = "../modules/linux"

  name                = "${var.name}-spoke0"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.vnet_spoke0.subnets.s0.id
  private_ip_address  = cidrhost(module.vnet_spoke0.subnets.s0.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
}

module "spoke1_h" {
  source = "../modules/linux"

  name                = "${var.name}-spoke1"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.vnet_spoke1.subnets.s0.id
  private_ip_address  = cidrhost(module.vnet_spoke1.subnets.s0.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
}


