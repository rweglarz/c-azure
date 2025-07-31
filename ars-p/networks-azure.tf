#region vnets
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
      idx = 2
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
      idx = 0
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
      apipa_addresses = [
        "169.254.22.1",
        "169.254.22.5"
      ]
    }
    peering_addresses {
      ip_configuration_name = "c2"
      apipa_addresses = [
        "169.254.22.9",
        "169.254.22.13"
      ]
    }
  }
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
  }

  on_remote = {
    resource_group_name     = azurerm_resource_group.rg1.name
    virtual_network_name    = module.vnet_transit.vnet.name
    virtual_network_id      = module.vnet_transit.vnet.id
  }
}
#endregion
