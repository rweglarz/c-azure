resource "panos_panorama_bgp" "left_u_ipsec_fw1" {
  template       = module.cfg_left_u_ipsec_fw1.template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = var.router_ids["left_u_ipsec_fw1"]
  as_number = var.asn["left_u_ipsec_fw1"]
}

resource "panos_panorama_bgp_peer_group" "left_u_ipsec_fw1-vng_right" {
  template        = module.cfg_left_u_ipsec_fw1.template_name
  virtual_router  = "vr1"
  name            = "vng_right"
  type            = "ebgp"
  import_next_hop = "use-peer"
  export_next_hop = "use-self"
  depends_on = [
    panos_panorama_bgp.left_u_ipsec_fw1
  ]
}

resource "panos_panorama_bgp_peer" "left_u_ipsec_fw1-hub1_i1" {
  template                = module.cfg_left_u_ipsec_fw1.template_name
  name                    = "vng-i1"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.left_u_ipsec_fw1-vng_right.name
  peer_as                 = var.asn["ars"]
  local_address_interface = "tunnel.11"
  local_address_ip        = format("%s/%s", local.private_ips.left_u_ipsec_fw1["tun11_ip"], 32)
  peer_address_ip         = azurerm_virtual_network_gateway.right.bgp_settings[0].peering_addresses[0].apipa_addresses[0]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}


resource "panos_panorama_bgp" "left_u_ipsec_fw2" {
  template       = module.cfg_left_u_ipsec_fw2.template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = var.router_ids["left_u_ipsec_fw2"]
  as_number = var.asn["left_u_ipsec_fw2"]
}

resource "panos_panorama_bgp_peer_group" "left_u_ipsec_fw2-vng_right" {
  template        = module.cfg_left_u_ipsec_fw2.template_name
  virtual_router  = "vr1"
  name            = "vng_right"
  type            = "ebgp"
  import_next_hop = "use-peer"
  export_next_hop = "use-self"
  depends_on = [
    panos_panorama_bgp.left_u_ipsec_fw2
  ]
}

resource "panos_panorama_bgp_peer" "left_u_ipsec_fw2-hub1_i1" {
  template                = module.cfg_left_u_ipsec_fw2.template_name
  name                    = "vng-i1"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.left_u_ipsec_fw2-vng_right.name
  peer_as                 = var.asn["ars"]
  local_address_interface = "tunnel.11"
  local_address_ip        = format("%s/%s", local.private_ips.left_u_ipsec_fw2["tun11_ip"], 32)
  peer_address_ip         = azurerm_virtual_network_gateway.right.bgp_settings[0].peering_addresses[1].apipa_addresses[0]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}


resource "panos_panorama_bgp_peer_group" "left_u_ipsec_fw1-left_u_hub_asr" {
  template          = module.cfg_left_u_ipsec_fw1.template_name
  virtual_router    = "vr1"
  name              = "left_u_hub_asr"
  type              = "ebgp"
  import_next_hop   = "original"
  export_next_hop   = "use-self"
  remove_private_as = false
  depends_on = [
    panos_panorama_bgp.left_u_ipsec_fw1
  ]
}

resource "panos_panorama_bgp_peer_group" "left_u_ipsec_fw2-left_u_hub_asr" {
  template          = module.cfg_left_u_ipsec_fw2.template_name
  virtual_router    = "vr1"
  name              = "left_u_hub_asr"
  type              = "ebgp"
  import_next_hop   = "original"
  export_next_hop   = "use-self"
  remove_private_as = false
  depends_on = [
    panos_panorama_bgp.left_u_ipsec_fw2
  ]
}


resource "panos_panorama_bgp_peer" "left_u_ipsec_fw1-left_u_hub_asr" {
  for_each = {
    0 : tolist(azurerm_route_server.left_u_hub.virtual_router_ips)[0],
    1 : tolist(azurerm_route_server.left_u_hub.virtual_router_ips)[1],
  }
  template                = module.cfg_left_u_ipsec_fw1.template_name
  name                    = "left_u_hub_asr-${each.key}"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.left_u_ipsec_fw1-left_u_hub_asr.name
  peer_as                 = var.asn["ars"]
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.private_ips.left_u_ipsec_fw1["eth1_2_ip"], local.subnet_prefix_length)
  peer_address_ip         = each.value
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_peer" "left_u_ipsec_fw2-left_u_hub_asr" {
  for_each = {
    0 : tolist(azurerm_route_server.left_u_hub.virtual_router_ips)[0],
    1 : tolist(azurerm_route_server.left_u_hub.virtual_router_ips)[1],
  }
  template                = module.cfg_left_u_ipsec_fw2.template_name
  name                    = "left_u_hub_asr-${each.key}"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.left_u_ipsec_fw2-left_u_hub_asr.name
  peer_as                 = var.asn["ars"]
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.private_ips.left_u_ipsec_fw2["eth1_2_ip"], local.subnet_prefix_length)
  peer_address_ip         = each.value
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_export_rule_group" "left_u_ipsec_fw1" {
  template       = module.cfg_left_u_ipsec_fw1.template_name
  virtual_router = "vr1"
  rule {
    name = "right-vng"
    match_address_prefix {
      prefix = cidrsubnet(var.cidr, 2, 0)
      exact  = false
    }
    match_route_table   = "unicast"
    action              = "allow"
    match_as_path_regex = "65515"
    as_path_type        = "remove"
    med                 = 90
    used_by = [
      panos_panorama_bgp_peer_group.left_u_ipsec_fw1-vng_right.name
    ]
  }
  rule {
    name = "left-asr"
    match_from_peers = [
      panos_panorama_bgp_peer.left_u_ipsec_fw1-hub1_i1.name
    ]
    match_route_table   = "unicast"
    action              = "allow"
    med                 = 90
    match_as_path_regex = "65515"
    as_path_type        = "remove"
    used_by = [
      panos_panorama_bgp_peer_group.left_u_ipsec_fw1-left_u_hub_asr.name
    ]
  }
}

resource "panos_panorama_bgp_export_rule_group" "left_u_ipsec_fw2" {
  template       = module.cfg_left_u_ipsec_fw2.template_name
  virtual_router = "vr1"
  rule {
    name = "right-vng"
    match_address_prefix {
      prefix = cidrsubnet(var.cidr, 2, 0)
      exact  = false
    }
    match_route_table   = "unicast"
    action              = "allow"
    match_as_path_regex = "65515"
    as_path_type        = "remove"
    med                 = 10
    used_by = [
      panos_panorama_bgp_peer_group.left_u_ipsec_fw2-vng_right.name
    ]
  }
  rule {
    name = "left-asr"
    match_from_peers = [
      panos_panorama_bgp_peer.left_u_ipsec_fw2-hub1_i1.name
    ]
    match_route_table   = "unicast"
    action              = "allow"
    match_as_path_regex = "65515"
    as_path_type        = "remove"
    med                 = 10
    used_by = [
      panos_panorama_bgp_peer_group.left_u_ipsec_fw1-left_u_hub_asr.name
    ]
  }
}
