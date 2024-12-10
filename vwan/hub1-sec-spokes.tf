module "hub1_sec_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-hub1-sec-spoke1"
  address_space = [local.vnet_cidr.hub1_sec_spoke1]
  bgp_community = "12076:20011"

  subnets = {
    "s1" = {
      idx                       = 0
      network_security_group_id = module.basic_rg1.sg_id.mgmt
      associate_nsg             = true
    },
    "s2" = {
      idx                       = 1
      network_security_group_id = module.basic_rg1.sg_id.mgmt
      associate_nsg             = true
    },
  }
  vnet_peering = {
    sec = {
      peer_vnet_id   = module.hub1_sec.vnet.id
      peer_vnet_name = module.hub1_sec.vnet.name

      allow_forwarded_traffic = true
    }
  }
}

module "hub1_sec_spoke2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-hub1-sec-spoke2"
  address_space = [local.vnet_cidr.hub1_sec_spoke2]
  bgp_community = "12076:20012"

  subnets = {
    "s1" = {
      idx                       = 0
      network_security_group_id = module.basic_rg1.sg_id.mgmt
      associate_nsg             = true
    },
    "s2" = {
      idx                       = 1
      network_security_group_id = module.basic_rg1.sg_id.mgmt
      associate_nsg             = true
    },
  }
  vnet_peering = {
    sec = {
      peer_vnet_id   = module.hub1_sec.vnet.id
      peer_vnet_name = module.hub1_sec.vnet.name

      allow_forwarded_traffic = true
    }
  }
}

resource "azurerm_subnet_route_table_association" "hub1_sec_spoke" {
  for_each = {
    spoke1_s1 = module.hub1_sec_spoke1.subnets.s1.id,
    spoke2_s1 = module.hub1_sec_spoke2.subnets.s1.id,
  }
  subnet_id      = each.value
  route_table_id = module.basic_rg1.route_table_id.mgmt-via-igw-dg-via-nh.hub1_sec
}
