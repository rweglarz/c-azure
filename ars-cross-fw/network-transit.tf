module "vnet_transit" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.name}-transit"
  address_space = [cidrsubnet(var.cidr, 2, 0)]

  subnets = {
    "onprem" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
    "fw" = {
      idx                       = 1
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
    "GatewaySubnet" = {
      idx                       = 6
    },
    "RouteServerSubnet" = {
      idx                       = 7
    },
  }
}




resource "azurerm_public_ip" "vpn-a" {
  name                = "${local.name}-a"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "vpn-b" {
  name                = "${local.name}-b"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "transit" {
  name                = "${local.name}-transit"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "VpnGw1"

  ip_configuration {
    name = "i0"
    public_ip_address_id          = azurerm_public_ip.vpn-a.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.vnet_transit.subnets.GatewaySubnet.id
  }
  ip_configuration {
    name = "i1"
    public_ip_address_id          = azurerm_public_ip.vpn-b.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.vnet_transit.subnets.GatewaySubnet.id
  }
}

resource "azurerm_local_network_gateway" "avs" {
  name                = "${local.name}-avs"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  gateway_address = azurerm_public_ip.avs.ip_address
  bgp_settings {
    asn                 = var.asn.avs
    bgp_peering_address = module.vm_linux.avs.private_ip_address
  }
}

resource "azurerm_virtual_network_gateway_connection" "avs" {
  name                = "${var.name}-avs"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.transit.id
  local_network_gateway_id   = azurerm_local_network_gateway.avs.id

  enable_bgp = true

  shared_key = var.psk
}




resource "azurerm_public_ip" "ars_transit" {
  name                = "${local.name}-ars-transit"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "transit" {
  name                             = "${local.name}-transit"
  resource_group_name              = azurerm_resource_group.rg.name
  location                         = azurerm_resource_group.rg.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars_transit.id
  subnet_id                        = module.vnet_transit.subnets.RouteServerSubnet.id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_route_server_bgp_connection" "transit_oprem" {
  name            = "onprem"
  route_server_id = azurerm_route_server.transit.id
  peer_asn        = var.asn.onprem
  peer_ip         = local.vm_ip.onprem
}




resource "azurerm_route_table" "on_prem" {
  name                = "${var.name}-on-prem"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  bgp_route_propagation_enabled = false
}

resource "azurerm_route" "on_prem_prv" {
  name                   = "prv"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.on_prem.name
  address_prefix         = "10.0.0.0/8"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.vm_ip.fw_transit
}

resource "azurerm_subnet_route_table_association" "on_prem" {
  for_each = toset([
    module.vnet_transit.subnets.onprem.id
  ])
  subnet_id      = each.key
  route_table_id = azurerm_route_table.on_prem.id
}




resource "azurerm_route_table" "gw" {
  name                = "${var.name}-gw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  bgp_route_propagation_enabled = true
}

resource "azurerm_route" "gw_prv" {
  name                   = "prv"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.gw.name
  address_prefix         = "10.0.0.0/8"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.vm_ip.fw_transit
}

resource "azurerm_subnet_route_table_association" "gw" {
  for_each = toset([
    module.vnet_transit.subnets.GatewaySubnet.id
  ])
  subnet_id      = each.key
  route_table_id = azurerm_route_table.gw.id
}



resource "azurerm_route_table" "fw_transit" {
  name                = "${var.name}-fw-transit"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  bgp_route_propagation_enabled = true
}

resource "azurerm_route" "fw_transit_prv" {
  for_each = toset([
    "10.0.0.0/8",
    # "0.0.0.0/0",
    # "0.0.0.0/1",
    # "128.0.0.0/1",
  ])
  name                   = "prv"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.fw_transit.name
  address_prefix         = each.key
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.vm_ip.onprem
}

resource "azurerm_subnet_route_table_association" "fw_transit" {
  for_each = toset([
    module.vnet_transit.subnets.fw.id
  ])
  subnet_id      = each.key
  route_table_id = azurerm_route_table.fw_transit.id
}

