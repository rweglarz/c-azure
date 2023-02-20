module "cfg_right_env_fw1" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-ars-right-env-fw1-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.private_ips.right_env_fw1["eth1_1_ip"], local.subnet_prefix_length)]
      zone       = "core"
    }
    "ethernet1/2" = {
      static_ips = [format("%s/%s", local.private_ips.right_env_fw1["eth1_2_ip"], local.subnet_prefix_length)]
      zone       = "env1"
    }
    "ethernet1/3" = {
      static_ips = [format("%s/%s", local.private_ips.right_env_fw1["eth1_3_ip"], local.subnet_prefix_length)]
      zone       = "env2"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.private_ips.right_env_fw1["eth1_1_gw"]
    }
    sdgw = {
      destination = module.vnet_right_env_sdgw.vnet.address_space[0]
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.private_ips.right_env_fw1["eth1_2_gw"]
    }
  }
  enable_ecmp = false
}

resource "panos_panorama_template_stack" "azure_right_env_fw1" {
  name         = "azure-ars-right-env-fw1"
  default_vsys = "vsys1"
  templates = [
    module.cfg_right_env_fw1.template_name,
    "vm common",
  ]
  description = "pat:acp"
}

resource "panos_panorama_bgp" "right_env_fw1" {
  template       = module.cfg_right_env_fw1.template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = var.router_ids["right_env_fw1"]
  as_number = var.asn["right_env_fw1"]
}

resource "panos_panorama_bgp_peer_group" "right_env_fw1-right_hub_asr" {
  template        = module.cfg_right_env_fw1.template_name
  virtual_router  = "vr1"
  name            = "right_hub_asr"
  type            = "ebgp"
  export_next_hop = "use-self"
  depends_on = [
    panos_panorama_bgp.right_env_fw1
  ]
}

resource "panos_panorama_bgp_peer_group" "right_env_fw1-right_env_fw_asr" {
  template        = module.cfg_right_env_fw1.template_name
  virtual_router  = "vr1"
  name            = "right_env_fw_asr"
  type            = "ebgp"
  export_next_hop = "resolve"
  depends_on = [
    panos_panorama_bgp.right_env_fw1
  ]
}

resource "panos_panorama_bgp_peer" "right_env_fw1-right_hub_asr" {
  for_each = {
    0 : tolist(azurerm_route_server.right_hub.virtual_router_ips)[0],
    1 : tolist(azurerm_route_server.right_hub.virtual_router_ips)[1],
  }
  template                = module.cfg_right_env_fw1.template_name
  name                    = "right_hub_asr-${each.value}"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.right_env_fw1-right_hub_asr.name
  peer_as                 = var.asn["ars"]
  local_address_interface = "ethernet1/1"
  local_address_ip        = format("%s/%s", local.private_ips.right_env_fw1["eth1_1_ip"], local.subnet_prefix_length)
  peer_address_ip         = each.value
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_peer" "right_env_fw1-right_env_fw_asr" {
  for_each = {
    0 : tolist(azurerm_route_server.right_env_fw.virtual_router_ips)[0],
    1 : tolist(azurerm_route_server.right_env_fw.virtual_router_ips)[1],
  }
  template                = module.cfg_right_env_fw1.template_name
  name                    = "right_env_fw_asr-${each.value}"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.right_env_fw1-right_env_fw_asr.name
  peer_as                 = var.asn["ars"]
  local_address_interface = "ethernet1/1"
  local_address_ip        = format("%s/%s", local.private_ips.right_env_fw1["eth1_1_ip"], local.subnet_prefix_length)
  peer_address_ip         = each.value
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_peer_group" "right_env_fw1-right_env1_sdgw" {
  template        = module.cfg_right_env_fw1.template_name
  virtual_router  = "vr1"
  name            = "right_env1_sdgw"
  type            = "ebgp"
  export_next_hop = "use-self"
  depends_on = [
    panos_panorama_bgp.right_env_fw1
  ]
}

resource "panos_panorama_bgp_peer" "right_env_fw1-right_env1_sdgw1" {
  template                = module.cfg_right_env_fw1.template_name
  name                    = "right_env1_sdgw1"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.right_env_fw1-right_env1_sdgw.name
  peer_as                 = var.asn["right_env1_sdgw1"]
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.private_ips.right_env_fw1["eth1_2_ip"], local.subnet_prefix_length)
  peer_address_ip         = local.private_ips.right_env1_sdgw1["eth0"]
  max_prefixes            = "unlimited"
  multi_hop               = 2
}

resource "panos_panorama_bgp_peer" "right_env_fw1-right_env1_sdgw2" {
  template                = module.cfg_right_env_fw1.template_name
  name                    = "right_env1_sdgw2"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.right_env_fw1-right_env1_sdgw.name
  peer_as                 = var.asn["right_env1_sdgw2"]
  local_address_interface = "ethernet1/2"
  local_address_ip        = format("%s/%s", local.private_ips.right_env_fw1["eth1_2_ip"], local.subnet_prefix_length)
  peer_address_ip         = local.private_ips.right_env1_sdgw2["eth0"]
  max_prefixes            = "unlimited"
  multi_hop               = 2
}


resource "panos_panorama_bgp_aggregate" "right_env_fw1-10_1_0_0_19" {
  template       = module.cfg_right_env_fw1.template_name
  virtual_router = "vr1"
  name           = "10_1_0_0_19"
  prefix         = "10.1.0.0/19"
  summary        = true
  depends_on = [
    panos_panorama_bgp.right_env_fw1
  ]
}

resource "panos_panorama_bgp_aggregate" "right_env_fw1-10_1_32_0_19" {
  template       = module.cfg_right_env_fw1.template_name
  virtual_router = "vr1"
  name           = "10_1_32_0_19"
  prefix         = "10.1.32.0/19"
  summary        = true
  depends_on = [
    panos_panorama_bgp.right_env_fw1
  ]
}

resource "panos_panorama_bgp_aggregate_suppress_filter" "right_env_fw1-sdgw1-10_1_0_0_19" {
  template       = module.cfg_right_env_fw1.template_name
  virtual_router = "vr1"
  bgp_aggregate  = panos_panorama_bgp_aggregate.right_env_fw1-10_1_0_0_19.name
  name           = "sdgw1-10_1_0_0_19"
  address_prefix {
    prefix = "10.1.0.0/19"
    exact  = false
  }
  from_peers = [
    panos_panorama_bgp_peer.right_env_fw1-right_env1_sdgw1.name
  ]
}

resource "panos_panorama_bgp_aggregate_suppress_filter" "right_env_fw1-sdgw2-10_1_0_0_19" {
  template       = module.cfg_right_env_fw1.template_name
  virtual_router = "vr1"
  bgp_aggregate  = panos_panorama_bgp_aggregate.right_env_fw1-10_1_0_0_19.name
  name           = "sdgw2-10_1_0_0_19"
  address_prefix {
    prefix = "10.1.0.0/19"
    exact  = false
  }
  from_peers = [
    panos_panorama_bgp_peer.right_env_fw1-right_env1_sdgw2.name
  ]
}

resource "panos_panorama_bgp_aggregate_suppress_filter" "right_env_fw1-sdgw1-10_1_32_0_19" {
  template       = module.cfg_right_env_fw1.template_name
  virtual_router = "vr1"
  bgp_aggregate  = panos_panorama_bgp_aggregate.right_env_fw1-10_1_32_0_19.name
  name           = "sdgw1-10_1_32_0_19"
  address_prefix {
    prefix = "10.1.32.0/19"
    exact  = false
  }
  from_peers = [
    panos_panorama_bgp_peer.right_env_fw1-right_env1_sdgw1.name
  ]
}

resource "panos_panorama_bgp_aggregate_suppress_filter" "right_env_fw1-sdgw2-10_1_32_0_19" {
  template       = module.cfg_right_env_fw1.template_name
  virtual_router = "vr1"
  bgp_aggregate  = panos_panorama_bgp_aggregate.right_env_fw1-10_1_32_0_19.name
  name           = "sdgw2-10_1_32_0_19"
  address_prefix {
    prefix = "10.1.32.0/19"
    exact  = false
  }
  from_peers = [
    panos_panorama_bgp_peer.right_env_fw1-right_env1_sdgw2.name
  ]
}


resource "panos_panorama_bgp_export_rule_group" "right_env_fw1-ars" {
  template       = module.cfg_right_env_fw1.template_name
  virtual_router = "vr1"
  rule {
    name = "sdgw1-10_1_0_0_19"
    match_address_prefix {
      prefix = "10.1.0.0/19"
      exact  = true
    }
    match_from_peers = [
      panos_panorama_bgp_peer.right_env_fw1-right_env1_sdgw1.name
    ]
    match_route_table = "unicast"
    action            = "allow"
    next_hop          = local.private_ips.right_env1_sdgw1["eth0"]
    used_by = [
      panos_panorama_bgp_peer_group.right_env_fw1-right_env_fw_asr.name
    ]
  }
  rule {
    name = "sdgw2-10_1_0_0_19"
    match_address_prefix {
      prefix = "10.1.0.0/19"
      exact  = true
    }
    match_from_peers = [
      panos_panorama_bgp_peer.right_env_fw1-right_env1_sdgw2.name
    ]
    match_route_table = "unicast"
    action            = "allow"
    next_hop          = local.private_ips.right_env1_sdgw2["eth0"]
    used_by = [
      panos_panorama_bgp_peer_group.right_env_fw1-right_env_fw_asr.name
    ]
  }
  rule {
    name = "sdgw1-10_1_32_0_19"
    match_address_prefix {
      prefix = "10.1.32.0/19"
      exact  = true
    }
    match_from_peers = [
      panos_panorama_bgp_peer.right_env_fw1-right_env1_sdgw1.name
    ]
    match_route_table = "unicast"
    action            = "allow"
    next_hop          = local.private_ips.right_env1_sdgw1["eth0"]
    used_by = [
      panos_panorama_bgp_peer_group.right_env_fw1-right_env_fw_asr.name
    ]
  }
  rule {
    name = "sdgw2-10_1_32_0_19"
    match_address_prefix {
      prefix = "10.1.32.0/19"
      exact  = true
    }
    match_from_peers = [
      panos_panorama_bgp_peer.right_env_fw1-right_env1_sdgw2.name
    ]
    match_route_table = "unicast"
    action            = "allow"
    next_hop          = local.private_ips.right_env1_sdgw2["eth0"]
    used_by = [
      panos_panorama_bgp_peer_group.right_env_fw1-right_env_fw_asr.name
    ]
  }
}

