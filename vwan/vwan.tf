resource "azurerm_virtual_wan" "vwan1" {
  name                = "${local.dname}-vwan1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.region1
  #office365_local_breakout_category = "OptimizeAndAllow"
}


resource "azurerm_virtual_hub" "hub1" {
  name                = "${local.dname}-hub1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.region1
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id
  address_prefix      = cidrsubnet(var.hub1_cidr, 4, 0)
}

resource "azurerm_virtual_hub" "hub2" {
  name                = "${local.dname}-hub2"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = var.region2
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id
  address_prefix      = cidrsubnet(var.hub2_cidr, 4, 0)
}


resource "azurerm_virtual_hub_connection" "hub1-hub1_sec" {
  name                      = "${local.dname}-hub1-sec"
  virtual_hub_id            = azurerm_virtual_hub.hub1.id
  remote_virtual_network_id = azurerm_virtual_network.hub1_sec.id
  routing {
    static_vnet_route {
      name = "hub1 sec spokes via nva"
      address_prefixes = [
        cidrsubnet(var.hub1_cidr, 1, 1)
      ]
      next_hop_ip_address = cidrhost(azurerm_subnet.hub1_sec_data.address_prefixes[0], 5)
    }
  }
  depends_on = [
    azurerm_vpn_gateway_connection.aws1-hub1
  ]
}

resource "azurerm_virtual_hub_connection" "hub2-hub2_sec" {
  name                      = "${local.dname}-hub2-sec"
  virtual_hub_id            = azurerm_virtual_hub.hub2.id
  remote_virtual_network_id = azurerm_virtual_network.hub2_sec.id
  routing {
    static_vnet_route {
      name = "hub2 sec spokes via nva"
      address_prefixes = [
        cidrsubnet(var.hub2_cidr, 1, 1)
      ]
      next_hop_ip_address = cidrhost(azurerm_subnet.hub2_sec_data.address_prefixes[0], 5)
    }
  }
}

resource "azurerm_virtual_hub_connection" "hub1-hub1_spoke1" {
  name                      = "${local.dname}-hub1-spoke1"
  virtual_hub_id            = azurerm_virtual_hub.hub1.id
  remote_virtual_network_id = azurerm_virtual_network.hub1_spoke1.id
  depends_on = [
    azurerm_virtual_hub_connection.hub1-hub1_sec
  ]
}

resource "azurerm_virtual_hub_connection" "hub1-hub1_spoke2" {
  name                      = "${local.dname}-hub1-spoke2"
  virtual_hub_id            = azurerm_virtual_hub.hub1.id
  remote_virtual_network_id = azurerm_virtual_network.hub1_spoke2.id
  depends_on = [
    azurerm_virtual_hub_connection.hub1-hub1_spoke1
  ]
}

resource "azurerm_virtual_hub_connection" "hub2-hub2_spoke1" {
  name                      = "${local.dname}-hub2-spoke1"
  virtual_hub_id            = azurerm_virtual_hub.hub2.id
  remote_virtual_network_id = azurerm_virtual_network.hub2_spoke1.id
  depends_on = [
    azurerm_virtual_hub_connection.hub2-hub2_sec
  ]
}

resource "azurerm_virtual_hub_connection" "hub2-hub2_spoke2" {
  name                      = "${local.dname}-hub2-spoke2"
  virtual_hub_id            = azurerm_virtual_hub.hub2.id
  remote_virtual_network_id = azurerm_virtual_network.hub2_spoke2.id
  depends_on = [
    azurerm_virtual_hub_connection.hub2-hub2_spoke1
  ]
}


resource "azurerm_virtual_hub_connection" "hub1-hub1_ipsec" {
  name                      = "${local.dname}-hub1-ipsec"
  virtual_hub_id            = azurerm_virtual_hub.hub1.id
  remote_virtual_network_id = module.ipsec_hub1.vnet.id
  depends_on = [
    azurerm_virtual_hub_connection.hub1-hub1_spoke2
  ]
}


resource "azurerm_virtual_hub_route_table_route" "hub1-hub1_sec_spokes" {
  route_table_id = azurerm_virtual_hub.hub1.default_route_table_id

  name              = "hub1 sec spokes via nva"
  destinations_type = "CIDR"
  destinations = [
    cidrsubnet(var.hub1_cidr, 1, 1)
  ]
  next_hop_type = "ResourceId"
  next_hop      = azurerm_virtual_hub_connection.hub1-hub1_sec.id
  depends_on = [
    azurerm_virtual_hub_connection.hub1-hub1_ipsec
  ]
}

resource "azurerm_virtual_hub_route_table_route" "hub2-hub1_sec_spokes" {
  route_table_id = azurerm_virtual_hub.hub2.default_route_table_id

  name              = "hub1 sec spokes via nva"
  destinations_type = "CIDR"
  destinations = [
    cidrsubnet(var.hub1_cidr, 1, 1)
  ]
  next_hop_type = "ResourceId"
  next_hop      = azurerm_virtual_hub_connection.hub1-hub1_sec.id
  depends_on = [
    azurerm_virtual_hub_connection.hub2-hub2_spoke2
  ]
}

resource "azurerm_virtual_hub_route_table_route" "hub1-hub2_sec_spokes" {
  route_table_id = azurerm_virtual_hub.hub1.default_route_table_id

  name              = "hub2 sec spokes via nva"
  destinations_type = "CIDR"
  destinations = [
    cidrsubnet(var.hub2_cidr, 1, 1)
  ]
  next_hop_type = "ResourceId"
  next_hop      = azurerm_virtual_hub_connection.hub2-hub2_sec.id
  depends_on = [
    azurerm_virtual_hub_route_table_route.hub1-hub1_sec_spokes
  ]
}

resource "azurerm_virtual_hub_route_table_route" "hub2-hub2_sec_spokes" {
  route_table_id = azurerm_virtual_hub.hub2.default_route_table_id

  name              = "hub2 sec spokes via nva"
  destinations_type = "CIDR"
  destinations = [
    cidrsubnet(var.hub2_cidr, 1, 1)
  ]
  next_hop_type = "ResourceId"
  next_hop      = azurerm_virtual_hub_connection.hub2-hub2_sec.id
  depends_on = [
    azurerm_virtual_hub_route_table_route.hub2-hub1_sec_spokes
  ]
}
