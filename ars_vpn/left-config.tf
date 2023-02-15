resource "panos_panorama_bgp" "left_ipsec_fw1" {
  template       = module.cfg_left_ipsec_fw1.template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = var.router_ids["left_ipsec_fw1"]
  as_number = var.asn["left_ipsec_fw1"]
}

resource "panos_panorama_bgp_peer_group" "left_ipsec_fw1-vng_right" {
  template       = module.cfg_left_ipsec_fw1.template_name
  virtual_router = "vr1"
  name           = "vng_right"
  type           = "ebgp"
  depends_on = [
    panos_panorama_bgp.left_ipsec_fw1
  ]
}

resource "panos_panorama_bgp_peer" "left_ipsec_fw1-hub1_i1" {
  template                = module.cfg_left_ipsec_fw1.template_name
  name                    = "vng-i1"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.left_ipsec_fw1-vng_right.name
  peer_as                 = var.asn["right_vng"]
  local_address_interface = "tunnel.11"
  local_address_ip        = format("%s/%s", local.private_ips.left_ipsec_fw1["tun11_ip"], 32)
  peer_address_ip         = azurerm_virtual_network_gateway.right.bgp_settings[0].peering_addresses[0].apipa_addresses[0]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}


resource "panos_panorama_bgp" "left_ipsec_fw2" {
  template       = module.cfg_left_ipsec_fw2.template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = var.router_ids["left_ipsec_fw2"]
  as_number = var.asn["left_ipsec_fw2"]
}

resource "panos_panorama_bgp_peer_group" "left_ipsec_fw2-vng_right" {
  template       = module.cfg_left_ipsec_fw2.template_name
  virtual_router = "vr1"
  name           = "vng_right"
  type           = "ebgp"
  depends_on = [
    panos_panorama_bgp.left_ipsec_fw2
  ]
}

resource "panos_panorama_bgp_peer" "left_ipsec_fw2-hub1_i1" {
  template                = module.cfg_left_ipsec_fw2.template_name
  name                    = "vng-i1"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.left_ipsec_fw2-vng_right.name
  peer_as                 = var.asn["right_vng"]
  local_address_interface = "tunnel.11"
  local_address_ip        = format("%s/%s", local.private_ips.left_ipsec_fw2["tun11_ip"], 32)
  peer_address_ip         = azurerm_virtual_network_gateway.right.bgp_settings[0].peering_addresses[1].apipa_addresses[0]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}


resource "panos_panorama_bgp_peer_group" "left_ipsec_fw1-left_hub_asr" {
  template        = module.cfg_left_ipsec_fw2.template_name
  virtual_router  = "vr1"
  name            = "left_hub_asr"
  type            = "ebgp"
  export_next_hop = "use-self"
  depends_on = [
    panos_panorama_bgp.left_ipsec_fw1
  ]
}

resource "panos_panorama_bgp_peer_group" "left_ipsec_fw2-left_hub_asr" {
  template        = module.cfg_left_ipsec_fw2.template_name
  virtual_router  = "vr1"
  name            = "left_hub_asr"
  type            = "ebgp"
  export_next_hop = "use-self"
  depends_on = [
    panos_panorama_bgp.left_ipsec_fw2
  ]
}


resource "panos_panorama_bgp_peer" "left_ipsec_fw1-left_hub_asr" {
  for_each = {
    0 : tolist(azurerm_route_server.left_hub.virtual_router_ips)[0],
    1 : tolist(azurerm_route_server.left_hub.virtual_router_ips)[1],
  }
  template                = module.cfg_left_ipsec_fw1.template_name
  name                    = "left_hub_asr-${each.value}"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.left_ipsec_fw1-left_hub_asr.name
  peer_as                 = var.asn["ars"]
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.private_ips.left_ipsec_fw1["eth1_2_ip"], local.subnet_prefix_length)
  peer_address_ip         = each.value
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_peer" "left_ipsec_fw2-left_hub_asr" {
  for_each = {
    0 : tolist(azurerm_route_server.left_hub.virtual_router_ips)[0],
    1 : tolist(azurerm_route_server.left_hub.virtual_router_ips)[1],
  }
  template                = module.cfg_left_ipsec_fw2.template_name
  name                    = "left_hub_asr-${each.key}"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.left_ipsec_fw2-left_hub_asr.name
  peer_as                 = var.asn["ars"]
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.private_ips.left_ipsec_fw2["eth1_2_ip"], local.subnet_prefix_length)
  peer_address_ip         = each.value
  max_prefixes            = "unlimited"
  multi_hop               = 1
}
