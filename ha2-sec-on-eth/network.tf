module "vnet_sec" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-sec"
  address_space = [cidrsubnet(var.cidr, 2, 0)]

  subnets = {
    "mgmt" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
    "ha2" = {
      idx                       = 1
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
    },
    "public" = {
      idx                       = 2
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
    },
    "private" = {
      idx                       = 3
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
    },
    "srv0" = {
      idx                       = 4
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
    "srv1" = {
      idx                       = 5
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }
}


resource "azurerm_route_table" "servers" {
  name                = "${var.name}-servers"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
resource "azurerm_route" "servers-routes" {
  for_each = {
    srv5  = module.vnet_sec.subnets.srv0.address_prefixes[0]
    srv6  = module.vnet_sec.subnets.srv1.address_prefixes[0]
    psrv0 = tolist(module.vnet_srv5.vnet.address_space)[0]
    psrv1 = tolist(module.vnet_srv6.vnet.address_space)[0]
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.servers.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.fw_ip.private.fws
}
resource "azurerm_route" "servers-mgmt-via-ig" {
  for_each               = {for e in var.mgmt_ips: e.cidr => e.description}
  name                   = replace("mgmt-${each.key}", "/[ \\/]/", "_")
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.servers.name
  address_prefix         = each.key
  next_hop_type          = "Internet"
}
resource "azurerm_route" "servers-dg" {
  name                   = "dg"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.servers.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.fw_ip.private.fws
}



module "vnet_srv5" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-srv5"
  address_space = [cidrsubnet(var.cidr, 2, 1)]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }
  vnet_peering = {
    sec = {
      peer_vnet_id   = module.vnet_sec.vnet.id
      peer_vnet_name = module.vnet_sec.vnet.name

      allow_forwarded_traffic = true
    }
  }
}


module "vnet_srv6" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-srv6"
  address_space = [cidrsubnet(var.cidr, 2, 2)]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }
  vnet_peering = {
    sec = {
      peer_vnet_id   = module.vnet_sec.vnet.id
      peer_vnet_name = module.vnet_sec.vnet.name

      allow_forwarded_traffic = true
    }
  }
}


resource "azurerm_subnet_route_table_association" "servers" {
  for_each = {
    srv0      = module.vnet_sec.subnets.srv0.id
    srv1      = module.vnet_sec.subnets.srv1.id
    srv5      = module.vnet_srv5.subnets.s0.id
    srv6      = module.vnet_srv6.subnets.s0.id
  }
  subnet_id      = each.value
  route_table_id = azurerm_route_table.servers.id
}
