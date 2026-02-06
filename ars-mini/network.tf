module "vnet_transit" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-transit"
  address_space = [local.cidrs.transit]
  subnet_mask_length = local.subnet_prefix_length

  subnets = {
    "mgmt" = {
      idx                       = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
    "data" = {
      idx                       = 1
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
    "gwA" = {
      idx                       = 2
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
    "gwB" = {
      idx                       = 3
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
    "RouteServerSubnet" = {
      address_prefixes = [cidrsubnet(local.cidrs.transit, 2, 3)]
    },
  }
}


module "vnet_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-spoke1"
  address_space = [local.cidrs.spoke1]

  subnets = {
    "s0" = {
      idx                       = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
  }
  vnet_peering = {
    transit = {
      peer_vnet_name          = module.vnet_transit.vnet.name
      peer_vnet_id            = module.vnet_transit.vnet.id
      allow_forwarded_traffic = true
      use_remote_gateways     = true
    }
  }
}

module "vnet_spoke2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-spoke2"
  address_space = [local.cidrs.spoke2]

  subnets = {
    "s0" = {
      idx                       = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
  }
  vnet_peering = {
    transit = {
      peer_vnet_name          = module.vnet_transit.vnet.name
      peer_vnet_id            = module.vnet_transit.vnet.id
      allow_forwarded_traffic = true
      use_remote_gateways     = true
    }
  }
}



resource "azurerm_public_ip" "ars_transit" {
  name                = "${var.name}-ars-transit"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "transit" {
  name                             = "${var.name}-transit"
  resource_group_name              = azurerm_resource_group.rg.name
  location                         = azurerm_resource_group.rg.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars_transit.id
  subnet_id                        = module.vnet_transit.subnets.RouteServerSubnet.id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_route_server_bgp_connection" "sdgw" {
  for_each = local.sdgw_init
  name            = each.key
  route_server_id = azurerm_route_server.transit.id
  peer_asn        = each.value.local_asn
  peer_ip         = each.value.local_ip
}

resource "azurerm_subnet_route_table_association" "sdgw" {
  for_each = {
    gwA = module.vnet_transit.subnets.gwA.id,
    gwB = module.vnet_transit.subnets.gwB.id,
  }
  subnet_id      = each.value
  route_table_id = module.basic.route_table_id.mgmt-via-igw-dg-via-nh.fw
}
