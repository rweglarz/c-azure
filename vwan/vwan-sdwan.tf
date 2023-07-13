resource "azurerm_virtual_hub_connection" "hub2-sdwan" {
  name                      = "${local.dname}-hub2-sdwan"
  virtual_hub_id            = azurerm_virtual_hub.hub2.id
  remote_virtual_network_id = module.hub2_sdwan.vnet.id
}

resource "azurerm_virtual_hub_connection" "hub4-sdwan" {
  name                      = "${local.dname}-hub4-sdwan"
  virtual_hub_id            = azurerm_virtual_hub.hub4.id
  remote_virtual_network_id = module.hub4_sdwan.vnet.id
}

resource "azurerm_virtual_hub_bgp_connection" "hub2-hub2_sdwan_fw" {
  name                          = "${local.dname}-hub2-hub2-sdwan-fw"
  virtual_hub_id                = azurerm_virtual_hub.hub2.id
  virtual_network_connection_id = azurerm_virtual_hub_connection.hub2-sdwan.id
  peer_asn                      = var.asn["hub2_sdwan_fw"]
  peer_ip                       = local.hub2_sdwan_fw["eth1_2_ip"]
}

resource "azurerm_virtual_hub_bgp_connection" "hub4-hub4_sdwan_fw2" {
  name                          = "${local.dname}-hub4-hub4-sdwan-fw2"
  virtual_hub_id                = azurerm_virtual_hub.hub4.id
  virtual_network_connection_id = azurerm_virtual_hub_connection.hub4-sdwan.id
  peer_asn                      = var.asn["hub4_sdwan_fw"]
  peer_ip                       = local.hub4_sdwan_fw["eth1_2_ip"]
}


resource "azurerm_virtual_hub_bgp_connection" "hub2-ipsec_hub2_fw1" {
  name                          = "${local.dname}-hub2-ipsec-hub2-fw1"
  virtual_hub_id                = azurerm_virtual_hub.hub2.id
  virtual_network_connection_id = azurerm_virtual_hub_connection.hub2-hub2_ipsec.id
  peer_asn                      = var.asn["ipsec_hub2_fw1"]
  peer_ip                       = local.ipsec_hub2_fw1["eth1_2_ip"]
}

resource "azurerm_virtual_hub_bgp_connection" "hub2-ipsec_hub2_fw2" {
  name                          = "${local.dname}-hub2-ipsec-hub2-fw2"
  virtual_hub_id                = azurerm_virtual_hub.hub2.id
  virtual_network_connection_id = azurerm_virtual_hub_connection.hub2-hub2_ipsec.id
  peer_asn                      = var.asn["ipsec_hub2_fw2"]
  peer_ip                       = local.ipsec_hub2_fw2["eth1_2_ip"]
}

