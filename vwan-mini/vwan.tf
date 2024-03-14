resource "azurerm_virtual_wan" "vwan" {
  name                = "${local.dname}-vwan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
}


resource "azurerm_virtual_hub" "hub1" {
  name                = "${local.dname}-hub1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  virtual_wan_id      = azurerm_virtual_wan.vwan.id
  address_prefix      = local.vnet_cidr.hub1
}


resource "azurerm_virtual_hub" "hub2" {
  name                = "${local.dname}-hub2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  virtual_wan_id      = azurerm_virtual_wan.vwan.id
  address_prefix      = local.vnet_cidr.hub2
}


resource "azurerm_vpn_gateway" "hub1" {
  name                = "${local.dname}-hub1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  virtual_hub_id      = azurerm_virtual_hub.hub1.id
  bgp_settings {
    asn         = var.asn.hub1
    peer_weight = 0
  }
}


resource "azurerm_vpn_site" "onprem" {
  name                = "onprem"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  virtual_wan_id      = azurerm_virtual_wan.vwan.id

  link {
    name       = "eth0"
    ip_address = module.linux_onprem.public_ip
    bgp {
      asn             = var.asn.onprem
      peering_address = module.linux_onprem.private_ip_address
    }
  }
}


resource "azurerm_vpn_gateway_connection" "hub1_onprem" {
  name               = "hub1_onprem"
  vpn_gateway_id     = azurerm_vpn_gateway.hub1.id
  remote_vpn_site_id = azurerm_vpn_site.onprem.id

  vpn_link {
    name             = "l1"
    vpn_site_link_id = azurerm_vpn_site.onprem.link[0].id
    bgp_enabled      = true
    shared_key       = var.psk
  }
}
