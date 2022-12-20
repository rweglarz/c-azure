resource "azurerm_virtual_wan" "vwan1" {
  name                = "${var.name}-vwan1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.region1
  #office365_local_breakout_category = "OptimizeAndAllow"
}


resource "azurerm_virtual_hub" "hub1" {
  name                = "${var.name}-hub1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = var.region1
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id
  address_prefix      = var.hub1_prefix
}

resource "azurerm_virtual_hub" "hub2" {
  name                = "${var.name}-hub2"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = var.region2
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id
  address_prefix      = var.hub2_prefix
}


resource "azurerm_virtual_hub_connection" "hub1-sec" {
  name                      = "${var.name}-hub1-sec"
  virtual_hub_id            = azurerm_virtual_hub.hub1.id
  remote_virtual_network_id = azurerm_virtual_network.hub1_sec.id
  routing {
    static_vnet_route {
      name = "sec spokes via nva"
      address_prefixes = [
        cidrsubnet(var.hub1_cidr, 1, 1)
      ]
      next_hop_ip_address = cidrhost(azurerm_subnet.hub1_sec_data.address_prefixes[0], 5)
    }
  }
}

resource "azurerm_virtual_hub_connection" "hub1-hub1_spoke1" {
  name                      = "${var.name}-hub1-spoke1"
  virtual_hub_id            = azurerm_virtual_hub.hub1.id
  remote_virtual_network_id = azurerm_virtual_network.hub1_spoke1.id
}

resource "azurerm_virtual_hub_connection" "hub1-hub1_spoke2" {
  name                      = "${var.name}-hub1-spoke2"
  virtual_hub_id            = azurerm_virtual_hub.hub1.id
  remote_virtual_network_id = azurerm_virtual_network.hub1_spoke2.id
}

resource "azurerm_virtual_hub_connection" "hub2-hub2_spoke1" {
  name                      = "${var.name}-hub2-spoke1"
  virtual_hub_id            = azurerm_virtual_hub.hub2.id
  remote_virtual_network_id = azurerm_virtual_network.hub2_spoke1.id
}

resource "azurerm_virtual_hub_connection" "hub2-hub2_spoke2" {
  name                      = "${var.name}-hub2-spoke2"
  virtual_hub_id            = azurerm_virtual_hub.hub2.id
  remote_virtual_network_id = azurerm_virtual_network.hub2_spoke2.id
}


