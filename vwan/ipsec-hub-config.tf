resource "panos_panorama_bgp" "azure_vwan_ipsec_hub1_fw1" {
  template       = module.cfg_ipsec_hub1_fw1.template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = var.router_ids["ipsec_hub1_fw1"]
  as_number = var.asn["ipsec_hub1_fw1"]
}

resource "panos_panorama_bgp" "azure_vwan_ipsec_hub1_fw2" {
  template       = module.cfg_ipsec_hub1_fw2.template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = var.router_ids["ipsec_hub1_fw2"]
  as_number = var.asn["ipsec_hub1_fw2"]
}



resource "panos_panorama_bgp_peer_group" "azure_vwan_ipsec_hub1_fw1" {
  template       = module.cfg_ipsec_hub1_fw1.template_name
  virtual_router = "vr1"
  name           = "ipsec"
  type           = "ebgp"
  depends_on = [
    panos_panorama_bgp.azure_vwan_ipsec_hub1_fw1
  ]
}

resource "panos_panorama_bgp_peer_group" "azure_vwan_ipsec_hub1_fw2" {
  template       = module.cfg_ipsec_hub1_fw2.template_name
  virtual_router = "vr1"
  name           = "ipsec"
  type           = "ebgp"
  depends_on = [
    panos_panorama_bgp.azure_vwan_ipsec_hub1_fw2
  ]
}

resource "panos_panorama_bgp_peer" "azure_ipsec_hub1_fw1-hub1_i1" {
  template                = module.cfg_ipsec_hub1_fw1.template_name
  name                    = "azure-i1"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.azure_vwan_ipsec_hub1_fw1.name
  peer_as                 = azurerm_virtual_hub.hub1.virtual_router_asn
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.ipsec_hub1_fw1["eth1_2_ip"], local.subnet_prefix_length)
  peer_address_ip         = azurerm_virtual_hub.hub1.virtual_router_ips[0]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_peer" "azure_ipsec_hub1_fw1-hub1_i2" {
  template                = module.cfg_ipsec_hub1_fw1.template_name
  name                    = "azure-i2"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.azure_vwan_ipsec_hub1_fw1.name
  peer_as                 = azurerm_virtual_hub.hub2.virtual_router_asn
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.ipsec_hub1_fw1["eth1_2_ip"], local.subnet_prefix_length)
  peer_address_ip         = azurerm_virtual_hub.hub1.virtual_router_ips[1]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}


resource "panos_panorama_bgp_peer" "azure_ipsec_hub1_fw2-hub1_i1" {
  template                = module.cfg_ipsec_hub1_fw2.template_name
  name                    = "azure-i1"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.azure_vwan_ipsec_hub1_fw2.name
  peer_as                 = azurerm_virtual_hub.hub1.virtual_router_asn
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.ipsec_hub1_fw2["eth1_2_ip"], local.subnet_prefix_length)
  peer_address_ip         = azurerm_virtual_hub.hub1.virtual_router_ips[0]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_peer" "azure_ipsec_hub1_fw2-hub1_i2" {
  template                = module.cfg_ipsec_hub1_fw2.template_name
  name                    = "azure-i2"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.azure_vwan_ipsec_hub1_fw2.name
  peer_as                 = azurerm_virtual_hub.hub1.virtual_router_asn
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.ipsec_hub1_fw2["eth1_2_ip"], local.subnet_prefix_length)
  peer_address_ip         = azurerm_virtual_hub.hub1.virtual_router_ips[1]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}


resource "panos_panorama_redistribution_profile_ipv4" "azure_ipsec_hub1_fw1" {
  template       = module.cfg_ipsec_hub1_fw1.template_name
  virtual_router = "vr1"
  name           = "redis-static"
  priority       = 1
  action         = "redist"
  types          = ["static"]
  destinations = [
    "10.66.66.32/28"
  ]
}

resource "panos_panorama_redistribution_profile_ipv4" "azure_ipsec_hub1_fw2" {
  template       = module.cfg_ipsec_hub1_fw2.template_name
  virtual_router = "vr1"
  name           = "redis-static"
  priority       = 1
  action         = "redist"
  types          = ["static"]
  destinations = [
    "10.66.66.32/28"
  ]
}

resource "panos_panorama_bgp_redist_rule" "azure_ipsec_hub1_fw1" {
  template       = module.cfg_ipsec_hub1_fw1.template_name
  virtual_router = "vr1"
  route_table    = "unicast"
  name           = panos_panorama_redistribution_profile_ipv4.azure_ipsec_hub1_fw1.name
  set_med        = "20"
}

resource "panos_panorama_bgp_redist_rule" "azure_ipsec_hub1_fw2" {
  template       = module.cfg_ipsec_hub1_fw2.template_name
  virtual_router = "vr1"
  route_table    = "unicast"
  name           = panos_panorama_redistribution_profile_ipv4.azure_ipsec_hub1_fw2.name
  set_med        = "20"
}
