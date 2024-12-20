module "vnet_sec" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.name}-sec"
  address_space = [cidrsubnet(var.cidr, 2, 1)]

  subnets = {
    "fw" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
    # "private" = {
    #   idx                       = 2
    #   network_security_group_id = module.basic.sg_id.wide-open
    #   associate_nsg             = true
    # },
    # "s0" = {
    #   idx                       = 3
    #   network_security_group_id = module.basic.sg_id.mgmt
    #   associate_nsg             = true
    # },
    "RouteServerSubnet" = {
      idx                       = 7
    },
  }
}


resource "azurerm_public_ip" "ars_sec" {
  name                = "${local.name}-ars-sec"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "sec" {
  name                             = "${local.name}-sec"
  resource_group_name              = azurerm_resource_group.rg.name
  location                         = azurerm_resource_group.rg.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars_sec.id
  subnet_id                        = module.vnet_sec.subnets.RouteServerSubnet.id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_route_server_bgp_connection" "sec_oprem" {
  name            = "onprem"
  route_server_id = azurerm_route_server.sec.id
  peer_asn        = var.asn.onprem
  peer_ip         = local.vm_ip.onprem
}



module "vp_sec_transit" {
  source = "../modules/vnet_peering"

  on_local = {
    resource_group_name     = azurerm_resource_group.rg.name
    virtual_network_name    = module.vnet_sec.vnet.name
    virtual_network_id      = module.vnet_sec.vnet.id
    use_remote_gateways     = false
    allow_forwarded_traffic = true
  }

  on_remote = {
    resource_group_name    = azurerm_resource_group.rg.name
    virtual_network_name   = module.vnet_transit.vnet.name
    virtual_network_id     = module.vnet_transit.vnet.id
    allow_gateway_transit  = true
  }
}
