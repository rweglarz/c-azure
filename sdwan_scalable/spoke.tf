module "vnet_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.dname}-spoke1"
  address_space = [local.vnet_cidr.spoke1]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }

  vnet_peering = {
    transit = {
      peer_vnet_name          = module.vnet_transit.vnet.name
      peer_vnet_id            = module.vnet_transit.vnet.id
      allow_forwarded_traffic = true
    }
  }
}

module "vnet_spoke2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.dname}-spoke2"
  address_space = [local.vnet_cidr.spoke2]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }

  vnet_peering = {
    transit = {
      peer_vnet_name          = module.vnet_transit.vnet.name
      peer_vnet_id            = module.vnet_transit.vnet.id
      allow_forwarded_traffic = true
    }
  }
}

resource "azurerm_subnet_route_table_association" "spoke1" {
  subnet_id      = module.vnet_spoke1.subnets.s0.id
  route_table_id = module.basic.route_table_id.private-via-nh.fw_ilb
}

resource "azurerm_subnet_route_table_association" "spoke2" {
  subnet_id      = module.vnet_spoke2.subnets.s0.id
  route_table_id = module.basic.route_table_id.private-via-nh.fw_ilb
}


module "linux_spoke1" {
  source = "../modules/linux"

  name                = "${var.name}-spoke1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_spoke1.subnets.s0.id
  private_ip_address  = cidrhost(module.vnet_spoke1.subnets.s0.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
}

module "linux_spoke2" {
  source = "../modules/linux"

  name                = "${var.name}-spoke2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_spoke2.subnets.s0.id
  private_ip_address  = cidrhost(module.vnet_spoke2.subnets.s0.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
}


