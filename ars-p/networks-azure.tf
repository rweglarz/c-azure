#region vnets, ilb, routing
module "vnet_transit" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${var.name}-transit"
  address_space = [cidrsubnet(var.cidr_azure, 8, 0)]

  subnets = {
    mgmt = {
      idx                       = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
    public = {
      idx                       = 1
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.vpn
    },
    private = {
      idx                       = 2
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.wide-open
    },
    RouteServerSubnet = {
      idx = 3
    },
    GatewaySubnet = {
      idx = 4
    },
  }
}

module "vnet_app" {
  for_each = local.app_vnets
  source   = "../modules/vnet"

  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${var.name}-${each.key}"
  address_space = [cidrsubnet(var.cidr_azure, 8, each.value.idx)]

  subnets = {
    workloads = {
      idx                       = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
  }
}

module "vnet_ars_p" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${var.name}-ars-p"
  address_space = [cidrsubnet(var.cidr_azure, 8, 255)]

  subnets = {
    RouteServerSubnet = {
      idx = 0
    },
  }
}

resource "azurerm_subnet_route_table_association" "app" {
  for_each = module.vnet_app
  
  subnet_id      = module.vnet_app[each.key].subnets["workloads"].id
  route_table_id = module.basic.route_table_id["only-mgmt-via-igw"]["igw"]
}

module "ilb_transit" {
  source = "../modules/ilb"

  name                = "${var.name}-transit"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  subnet_id           = module.vnet_transit.subnets["private"].id
  private_ip_address  = local.transit_ilb
}

resource "azurerm_route_table" "transit_vng" {
  name                          = "${var.name}-transit-vng"
  resource_group_name           = azurerm_resource_group.rg1.name
  location                      = azurerm_resource_group.rg1.location
}

resource "azurerm_route" "transit_vng-app" {
  for_each = module.vnet_app
  name                   = each.key
  resource_group_name    = azurerm_resource_group.rg1.name
  route_table_name       = azurerm_route_table.transit_vng.name
  address_prefix         = tolist(each.value.vnet.address_space)[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.transit_ilb
}

resource "azurerm_subnet_route_table_association" "transit_vng" {
  subnet_id      = module.vnet_transit.subnets["GatewaySubnet"].id
  route_table_id = azurerm_route_table.transit_vng.id
}
#endregion



#region vng
resource "azurerm_public_ip" "vng" {
  for_each = toset(["c1", "c2"])

  name                = "${var.name}-vng-${each.key}"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
  sku                 = "Standard"
}



resource "azurerm_virtual_network_gateway" "transit" {
  name                = "${var.name}-transit"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "VpnGw1"

  ip_configuration {
    name                 = "c1"
    public_ip_address_id = azurerm_public_ip.vng["c1"].id
    subnet_id            = module.vnet_transit.subnets["GatewaySubnet"].id
  }
  ip_configuration {
    name                 = "c2"
    public_ip_address_id = azurerm_public_ip.vng["c2"].id
    subnet_id            = module.vnet_transit.subnets["GatewaySubnet"].id
  }

  bgp_settings {
    asn = var.asn["ars"] # it should be 65515 by default but putting it explicitly to work with ARS
    peering_addresses {
      ip_configuration_name = "c1"
      apipa_addresses = local.peering_addresses["vng"]["c1"]
    }
    peering_addresses {
      ip_configuration_name = "c2"
      apipa_addresses = local.peering_addresses["vng"]["c2"]
    }
  }
}

resource "azurerm_local_network_gateway" "onprem" {
  for_each = toset(["isp1", "isp2"])

  name                = "${var.name}-onprem-${each.key}"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  gateway_address = module.onprem_fw.public_ips[each.key]
  bgp_settings {
    asn                 = var.asn["onprem_fw"]
    bgp_peering_address = each.key=="isp1" ? local.peering_addresses["onprem_fw"][0] : local.peering_addresses["onprem_fw"][1]
  }
}

resource "azurerm_virtual_network_gateway_connection" "onprem" {
  for_each = toset(["isp1", "isp2"])

  name                = "${var.name}-onprem-${each.key}"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.transit.id
  local_network_gateway_id   = azurerm_local_network_gateway.onprem[each.key].id

  enable_bgp = true
  custom_bgp_addresses {
    primary   = each.key=="isp1" ? local.peering_addresses["vng"]["c1"][0] : local.peering_addresses["vng"]["c1"][1]
    secondary = each.key=="isp1" ? local.peering_addresses["vng"]["c2"][0] : local.peering_addresses["vng"]["c2"][1]
  }
  shared_key = random_bytes.psk.hex
}
#endregion



#region ars
resource "azurerm_public_ip" "ars_transit" {
  name                = "${var.name}-ars-transit"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "transit" {
  name                             = "${var.name}-transit"
  resource_group_name              = azurerm_resource_group.rg1.name
  location                         = azurerm_resource_group.rg1.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars_transit.id
  subnet_id                        = module.vnet_transit.subnets["RouteServerSubnet"].id
  branch_to_branch_traffic_enabled = true
}


resource "azurerm_public_ip" "ars_p" {
  name                = "${var.name}-ars-p"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "p" {
  name                             = "${var.name}-p"
  resource_group_name              = azurerm_resource_group.rg1.name
  location                         = azurerm_resource_group.rg1.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars_p.id
  subnet_id                        = module.vnet_ars_p.subnets["RouteServerSubnet"].id
}



resource "azurerm_route_server_bgp_connection" "transit_ars" {
  for_each = local.transit_fws

  name            = each.key
  route_server_id = azurerm_route_server.transit.id
  peer_asn        = var.asn["transit_fw"]
  peer_ip         = each.value["eth1_2_ip"]
}

resource "azurerm_route_server_bgp_connection" "p_ars" {
  for_each = local.transit_fws

  name            = each.key
  route_server_id = azurerm_route_server.p.id
  peer_asn        = var.asn["transit_fw"]
  peer_ip         = each.value["eth1_2_ip"]
}
#endregion



#region vnet peerings
module "vnet_peering-transit-ars_p" {
  source = "../modules/vnet_peering"

  on_local = {
    resource_group_name     = azurerm_resource_group.rg1.name
    virtual_network_name    = module.vnet_transit.vnet.name
    virtual_network_id      = module.vnet_transit.vnet.id
  }

  on_remote = {
    resource_group_name     = azurerm_resource_group.rg1.name
    virtual_network_name    = module.vnet_ars_p.vnet.name
    virtual_network_id      = module.vnet_ars_p.vnet.id
  }
}

module "vnet_peering-app-ars_p" {
  for_each = module.vnet_app
  source   = "../modules/vnet_peering"

  on_local = {
    resource_group_name     = azurerm_resource_group.rg1.name
    virtual_network_name    = each.value.vnet.name
    virtual_network_id      = each.value.vnet.id
    use_remote_gateways     = true
  }

  on_remote = {
    resource_group_name     = azurerm_resource_group.rg1.name
    virtual_network_name    = module.vnet_ars_p.vnet.name
    virtual_network_id      = module.vnet_ars_p.vnet.id
    allow_gateway_transit   = true
  }
}

module "vnet_peering-app-transit" {
  for_each = module.vnet_app
  source   = "../modules/vnet_peering"

  on_local = {
    resource_group_name     = azurerm_resource_group.rg1.name
    virtual_network_name    = each.value.vnet.name
    virtual_network_id      = each.value.vnet.id
    allow_forwarded_traffic = true
  }

  on_remote = {
    resource_group_name     = azurerm_resource_group.rg1.name
    virtual_network_name    = module.vnet_transit.vnet.name
    virtual_network_id      = module.vnet_transit.vnet.id
  }
}
#endregion
