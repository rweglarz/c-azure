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
  address_prefix      = local.vnet_cidr.hub1
}

resource "azurerm_virtual_hub" "hub2" {
  name                = "${local.dname}-hub2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.region1
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id
  address_prefix      = local.vnet_cidr.hub2
}

resource "azurerm_virtual_hub" "hub3" {
  name                = "${local.dname}-hub3"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = var.region2
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id
  address_prefix      = local.vnet_cidr.hub3
}

resource "azurerm_virtual_hub" "hub4" {
  name                = "${local.dname}-hub4"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = var.region2
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id
  address_prefix      = local.vnet_cidr.hub4
}


resource "azurerm_virtual_hub_connection" "hub1-hub1_sec" {
  name                      = "${local.dname}-hub1-sec"
  virtual_hub_id            = azurerm_virtual_hub.hub1.id
  remote_virtual_network_id = module.hub1_sec.vnet.id
  routing {
    static_vnet_route {
      name = "hub1 sec spokes via nva"
      address_prefixes = [
        cidrsubnet(var.region1_cidr, 2, 0)
      ]
      next_hop_ip_address = local.private_ip.hub1_sec_ilb
    }
  }
  depends_on = [
    azurerm_vpn_gateway_connection.aws1-hub2
  ]
}

resource "azurerm_virtual_hub_connection" "hub2-hub2_spoke1" {
  name                      = "${local.dname}-hub2-spoke1"
  virtual_hub_id            = azurerm_virtual_hub.hub2.id
  remote_virtual_network_id = module.hub2_spoke1.vnet.id
  internet_security_enabled = var.internet_security_enabled
  depends_on = [
    azurerm_virtual_hub_connection.hub1-hub1_sec
  ]
}

resource "azurerm_virtual_hub_connection" "hub2-hub2_spoke2" {
  name                      = "${local.dname}-hub2-spoke2"
  virtual_hub_id            = azurerm_virtual_hub.hub2.id
  remote_virtual_network_id = module.hub2_spoke2.vnet.id
  internet_security_enabled = var.internet_security_enabled
  depends_on = [
    azurerm_virtual_hub_connection.hub2-hub2_spoke1
  ]
}

resource "azurerm_virtual_hub_connection" "hub3-hub3_spoke1" {
  name                      = "${local.dname}-hub3-spoke1"
  virtual_hub_id            = azurerm_virtual_hub.hub3.id
  remote_virtual_network_id = module.hub3_spoke1.vnet.id
  internet_security_enabled = var.internet_security_enabled
  depends_on = [
    azurerm_virtual_hub_connection.hub2-hub2_spoke2
  ]
}

resource "azurerm_virtual_hub_connection" "hub4-hub4_spoke1" {
  name                      = "${local.dname}-hub4-spoke1"
  virtual_hub_id            = azurerm_virtual_hub.hub4.id
  remote_virtual_network_id = module.hub4_spoke1.vnet.id
  internet_security_enabled = var.internet_security_enabled
  depends_on = [
    azurerm_virtual_hub_connection.hub3-hub3_spoke1
  ]
}

resource "azurerm_virtual_hub_connection" "hub4-hub4_spoke2" {
  name                      = "${local.dname}-hub4-spoke2"
  virtual_hub_id            = azurerm_virtual_hub.hub4.id
  remote_virtual_network_id = module.hub4_spoke2.vnet.id
  internet_security_enabled = var.internet_security_enabled
  depends_on = [
    azurerm_virtual_hub_connection.hub2-hub2_spoke1
  ]
}



resource "azurerm_virtual_hub_connection" "hub2-hub2_dns" {
  name                      = "${local.dname}-hub2-dns"
  virtual_hub_id            = azurerm_virtual_hub.hub2.id
  remote_virtual_network_id = module.hub2_dns.vnet.id
  depends_on = [
    azurerm_virtual_hub_connection.hub4-hub4_spoke2
  ]
}



resource "azurerm_virtual_hub_routing_intent" "hub2" {
  count = (var.cloud_ngfw_panorama_config.hub2!=null && try(var.configure_hub_routing_intent.hub2, false)==true) ? 1 : 0
  name           = "${local.dname}-hub2"
  virtual_hub_id = azurerm_virtual_hub.hub2.id

  routing_policy {
    name         = "InternetTrafficPolicy"
    destinations = ["Internet"]
    next_hop     = azurerm_palo_alto_virtual_network_appliance.hub2[0].id
  }
  routing_policy {
    name         = "PrivateTrafficPolicy"
    destinations = ["PrivateTraffic"]
    next_hop     = azurerm_palo_alto_virtual_network_appliance.hub2[0].id
  }
}

resource "azurerm_virtual_hub_routing_intent" "hub4" {
  count = (var.cloud_ngfw_panorama_config.hub4!=null && try(var.configure_hub_routing_intent.hub4, false)==true) ? 1 : 0
  name           = "${local.dname}-hub4"
  virtual_hub_id = azurerm_virtual_hub.hub4.id

  routing_policy {
    name         = "InternetTrafficPolicy"
    destinations = ["Internet"]
    next_hop     = azurerm_palo_alto_virtual_network_appliance.hub4[0].id
  }
  routing_policy {
    name         = "PrivateTrafficPolicy"
    destinations = ["PrivateTraffic"]
    next_hop     = azurerm_palo_alto_virtual_network_appliance.hub4[0].id
  }
}



resource "azurerm_virtual_hub_route_table_route" "hub1-hub1_sec_spokes" {
  route_table_id = azurerm_virtual_hub.hub1.default_route_table_id

  name              = "hub1 sec spokes via nva"
  destinations_type = "CIDR"
  destinations = [
    cidrsubnet(var.region1_cidr, 1, 1)
  ]
  next_hop_type = "ResourceId"
  next_hop      = azurerm_virtual_hub_connection.hub1-hub1_sec.id
  depends_on = [
    azurerm_virtual_hub_connection.hub2-hub2_dns
  ]
}

resource "azurerm_virtual_hub_route_table_route" "hub3-hub1_sec_spokes" {
  route_table_id = azurerm_virtual_hub.hub3.default_route_table_id

  name              = "hub1 sec spokes via nva"
  destinations_type = "CIDR"
  destinations = [
    cidrsubnet(var.region1_cidr, 1, 1)
  ]
  next_hop_type = "ResourceId"
  next_hop      = azurerm_virtual_hub_connection.hub1-hub1_sec.id
  depends_on = [
    azurerm_virtual_hub_connection.hub2-hub2_spoke2
  ]
}
