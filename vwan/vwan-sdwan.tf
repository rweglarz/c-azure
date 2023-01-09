resource "azurerm_virtual_hub_connection" "hub2-sdwan" {
  name                      = "${local.dname}-hub2-sdwan"
  virtual_hub_id            = azurerm_virtual_hub.hub2.id
  remote_virtual_network_id = azurerm_virtual_network.hub2_sdwan.id
}

resource "azurerm_virtual_hub_bgp_connection" "hub2-hub2_sdwan_fw1" {
  name                          = "${local.dname}-hub2-hub2-sdwan-fw1"
  virtual_hub_id                = azurerm_virtual_hub.hub2.id
  virtual_network_connection_id = azurerm_virtual_hub_connection.hub2-sdwan.id
  peer_asn                      = var.asn["hub2_sdwan_fw1"]
  peer_ip                       = local.hub2_sdwan_fw1["eth1_2_ip"]
}

resource "azurerm_virtual_hub_bgp_connection" "hub2-hub2_sdwan_fw2" {
  name                          = "${local.dname}-hub2-hub2-sdwan-fw2"
  virtual_hub_id                = azurerm_virtual_hub.hub2.id
  virtual_network_connection_id = azurerm_virtual_hub_connection.hub2-sdwan.id
  peer_asn                      = var.asn["hub2_sdwan_fw2"]
  peer_ip                       = local.hub2_sdwan_fw2["eth1_2_ip"]
}



