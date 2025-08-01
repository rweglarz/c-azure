locals {

  bgp_peers-transit_fw-transit_ars-f = flatten([
    for k,v in local.transit_fws: [
      for i in [0, 1]: {
        i      = i
        fw     = k
        ars_ip = tolist(azurerm_route_server.transit.virtual_router_ips)[i]
      }
    ]
  ])
  bgp_peers-transit_fw-transit_ars = { 
    for v in local.bgp_peers-transit_fw-transit_ars-f: "${v.fw}-${v.i}" => v
  }
  bgp_peers-transit_fw-p_ars-f = flatten([
    for k,v in local.transit_fws: [
      for i in [0, 1]: {
        i      = i
        fw     = k
        ars_ip = tolist(azurerm_route_server.p.virtual_router_ips)[i]
      }
    ]
  ])
  bgp_peers-transit_fw-p_ars = { 
    for v in local.bgp_peers-transit_fw-p_ars-f: "${v.fw}-${v.i}" => v
  }
}

module "cfg_transit_fw" {
  source = "../../ce-common/modules/pan_vm_template"
  for_each = local.transit_fws

  name = "${local.template_prefix}-transit-${each.key}-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.transit_fws[each.key]["eth1_1_ip"], local.subnet_prefix_length)]
      zone       = "public"
    }
    "ethernet1/2" = {
      static_ips         = [format("%s/%s", local.transit_fws[each.key]["eth1_2_ip"], local.subnet_prefix_length)]
      zone               = "private"
      management_profile = "hc-azure"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets["public"].address_prefixes[0], 1)
    }
    r172 = {
      destination = "172.16.0.0/12"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets["private"].address_prefixes[0], 1)
    }
    hc = {
      destination = "168.63.129.16/32"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets["private"].address_prefixes[0], 1)
    }
  }
}

resource "panos_panorama_template_stack" "transit_fw" {
  for_each = local.transit_fws

  name = "${local.template_prefix}-transit-${each.key}-ts"
  default_vsys = "vsys1"
  templates = [
    module.cfg_transit_fw[each.key].template_name,
    "vm common",
  ]
  description = "pat:acp"
}



resource "panos_panorama_bgp" "transit_fw" {
  for_each = local.transit_fws

  template       = module.cfg_transit_fw[each.key].template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = local.transit_fws[each.key]["eth1_2_ip"]
  as_number = var.asn["transit_fw"]

  allow_redistribute_default_route = true
}

resource "panos_panorama_bgp_peer_group" "transit_fw-transit_ars" {
  for_each = local.transit_fws

  template        = module.cfg_transit_fw[each.key].template_name
  virtual_router  = "vr1"
  name            = "transit_ars"
  type            = "ebgp"

  depends_on = [
    panos_panorama_bgp.transit_fw
  ]
}

resource "panos_panorama_bgp_peer_group" "transit_fw-p_ars" {
  for_each = local.transit_fws

  template        = module.cfg_transit_fw[each.key].template_name
  virtual_router  = "vr1"
  name            = "p_ars"
  type            = "ebgp"

  depends_on = [
    panos_panorama_bgp.transit_fw
  ]
}


resource "panos_panorama_bgp_peer" "transit_fw-transit_ars" {
  for_each = local.bgp_peers-transit_fw-transit_ars

  template                = module.cfg_transit_fw[each.value.fw].template_name
  name                    = "transit_ars-${each.value.ars_ip}"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.transit_fw-transit_ars[each.value.fw].name
  peer_as                 = var.asn["ars"]
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.transit_fws[each.value.fw]["eth1_2_ip"], local.subnet_prefix_length)
  peer_address_ip         = each.value.ars_ip
  max_prefixes            = "unlimited"
  multi_hop               = 1

  enable_sender_side_loop_detection = false
}

resource "panos_panorama_bgp_peer" "transit_fw-p_ars" {
  for_each = local.bgp_peers-transit_fw-p_ars

  template                = module.cfg_transit_fw[each.value.fw].template_name
  name                    = "p_ars-${each.value.ars_ip}"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.transit_fw-p_ars[each.value.fw].name
  peer_as                 = var.asn["ars"]
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.transit_fws[each.value.fw]["eth1_2_ip"], local.subnet_prefix_length)
  peer_address_ip         = each.value.ars_ip
  max_prefixes            = "unlimited"
  multi_hop               = 1

  enable_sender_side_loop_detection = false
}

resource "panos_panorama_bgp_redist_rule" "transit_fw" {
  for_each = local.transit_fws

  template       = module.cfg_transit_fw[each.key].template_name
  virtual_router = "vr1"
  route_table    = "unicast"
  name           = "0.0.0.0/0"
  set_med        = "20"
  depends_on = [
    panos_panorama_bgp.transit_fw
  ]
}



resource "panos_panorama_bgp_export_rule_group" "transit_fw-transit_ars" {
  for_each = local.transit_fws

  template       = module.cfg_transit_fw[each.key].template_name
  virtual_router = "vr1"
  rule {
    name = "r-172.16.0.0_12"
    match_address_prefix {
      prefix = "172.16.0.0/12"
      exact  = false
    }
    match_route_table   = "unicast"
    action              = "allow"
    next_hop            = local.transit_ilb
    as_path_type        = "remove"
    match_as_path_regex = "65515"
    used_by = [
      panos_panorama_bgp_peer_group.transit_fw-transit_ars[each.key].name
    ]
  }
}

resource "panos_panorama_bgp_export_rule_group" "transit_fw-p_ars" {
  for_each = local.transit_fws

  template       = module.cfg_transit_fw[each.key].template_name
  virtual_router = "vr1"
  rule {
    name = "dg"
    match_address_prefix {
      prefix = "0.0.0.0/0"
      exact  = true
    }
    match_route_table   = "unicast"
    action              = "allow"
    next_hop            = local.transit_ilb
    used_by = [
      panos_panorama_bgp_peer_group.transit_fw-p_ars[each.key].name
    ]
  }
  rule {
    name = "r-10"
    match_address_prefix {
      prefix = "10.0.0.0/8"
      exact  = false
    }
    # match_from_peers = [
    #   panos_panorama_bgp_peer.transit_fw[each.key]-transit1_sdgw1.name
    # ]
    match_route_table   = "unicast"
    action              = "allow"
    next_hop            = local.transit_ilb
    as_path_type        = "remove"
    match_as_path_regex = "65515"
    used_by = [
      panos_panorama_bgp_peer_group.transit_fw-p_ars[each.key].name
    ]
  }
}

