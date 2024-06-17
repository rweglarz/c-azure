resource "panos_panorama_template" "azure_vwan_hub2_sdwan_fw1" {
  name = "azure-vwan-hub2-sdwan-fw1"
}

resource "panos_panorama_template" "azure_vwan_hub2_sdwan_fw2" {
  name = "azure-vwan-hub2-sdwan-fw2"
}


resource "panos_panorama_template" "azure_vwan_hub4_sdwan_fw" {
  name = "azure-vwan-hub4-sdwan-fw"
}

resource "panos_panorama_template_stack" "azure_vwan_hub2_sdwan_fw1" {
  name         = "azure-vwan-hub2-sdwan-fw1-ts"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.azure_vwan_hub2_sdwan_fw1.name,
    "sdwan-1isp",
    "vm common",
  ]
  description = "pat:acp pat:sdwan:hub:1"
}

resource "panos_panorama_template_stack" "azure_vwan_hub2_sdwan_fw2" {
  name         = "azure-vwan-hub2-sdwan-fw2-ts"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.azure_vwan_hub2_sdwan_fw2.name,
    "sdwan-1isp",
    "vm common",
  ]
  description = "pat:acp pat:sdwan:hub:2"
}

resource "panos_panorama_template_stack" "azure_vwan_hub4_sdwan_fw" {
  name         = "azure-vwan-hub4-sdwan-fw-ts"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.azure_vwan_hub4_sdwan_fw.name,
    "sdwan-1isp",
    "vm common",
  ]
  description = "pat:acp pat:sdwan:hub:3"
}


resource "panos_panorama_template_variable" "azure_vwan_hub2_sdwan_fw1" {
  for_each = {
    eth1_1_ip = format("%s/%s", local.hub2_sdwan_fw1["eth1_1_ip"], local.subnet_prefix_length)
    eth1_1_gw = local.hub2_sdwan_fw1["eth1_1_gw"]
    eth1_2_ip = format("%s/%s", local.hub2_sdwan_fw1["eth1_2_ip"], local.subnet_prefix_length)
    lo1_ip    = format("%s/32", var.router_ids["hub2_sdwan_fw1"])
  }
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
  name           = format("$%s", each.key)
  type           = "ip-netmask"
  value          = each.value
}

resource "panos_panorama_template_variable" "azure_vwan_hub2_sdwan_fw2" {
  for_each = {
    eth1_1_ip = format("%s/%s", local.hub2_sdwan_fw2["eth1_1_ip"], local.subnet_prefix_length)
    eth1_1_gw = local.hub2_sdwan_fw2["eth1_1_gw"]
    eth1_2_ip = format("%s/%s", local.hub2_sdwan_fw2["eth1_2_ip"], local.subnet_prefix_length)
    lo1_ip    = format("%s/32", var.router_ids["hub2_sdwan_fw2"])
  }
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw2.name
  name           = format("$%s", each.key)
  type           = "ip-netmask"
  value          = each.value
}

resource "panos_panorama_template_variable" "azure_vwan_hub4_sdwan_fw" {
  for_each = {
    eth1_1_ip = format("%s/%s", local.hub4_sdwan_fw["eth1_1_ip"], local.subnet_prefix_length)
    eth1_1_gw = local.hub4_sdwan_fw["eth1_1_gw"]
    eth1_2_ip = format("%s/%s", local.hub4_sdwan_fw["eth1_2_ip"], local.subnet_prefix_length)
    lo1_ip    = format("%s/32", var.router_ids["hub4_sdwan_fw"])
  }
  template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
  name           = format("$%s", each.key)
  type           = "ip-netmask"
  value          = each.value
}



resource "panos_panorama_static_route_ipv4" "azure_vwan_hub_sdwan_fw-dg" {
  for_each = {
    hub2-fw1 = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
      next_hop       = local.hub2_sdwan_fw1["eth1_1_gw"]
    }
    hub2-fw2 = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw2.name
      next_hop       = local.hub2_sdwan_fw2["eth1_1_gw"]
    }
    hub4-fw = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
      next_hop       = local.hub4_sdwan_fw["eth1_1_gw"]
    }
  }
  template_stack = each.value.template_stack
  virtual_router = "vr1"
  name           = "dg"
  destination    = "0.0.0.0/0"
  next_hop       = each.value.next_hop
  interface      = "ethernet1/1"
}


resource "panos_panorama_static_route_ipv4" "azure_vwan_hub_sdwan_fw-hub" {
  for_each = {
    hub2-fw1 = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
      destination    = azurerm_virtual_hub.hub2.address_prefix
      next_hop       = local.hub2_sdwan_fw1["eth1_2_gw"]
    }
    hub2-fw2 = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw2.name
      destination    = azurerm_virtual_hub.hub2.address_prefix
      next_hop       = local.hub2_sdwan_fw2["eth1_2_gw"]
    }
    hub4-fw = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
      destination    = azurerm_virtual_hub.hub4.address_prefix
      next_hop       = local.hub4_sdwan_fw["eth1_2_gw"]
    }
  }
  template_stack = each.value.template_stack
  virtual_router = "vr1"
  name           = "hub"
  destination    = each.value.destination
  next_hop       = each.value.next_hop
  interface      = "ethernet1/2"
}



resource "panos_panorama_bgp" "azure_vwan_hub_sdwan_fw" {
  for_each = {
    hub2-fw1 = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
      router_id      = var.router_ids["hub2_sdwan_fw1"]
      as_number      = var.asn["hub2_sdwan_fw1"]
    }
    hub2-fw2 = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw2.name
      router_id      = var.router_ids["hub2_sdwan_fw2"]
      as_number      = var.asn["hub2_sdwan_fw2"]
    }
    hub4-fw = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
      router_id      = var.router_ids["hub4_sdwan_fw"]
      as_number      = var.asn["hub4_sdwan_fw"]
    }
  }
  template_stack = each.value.template_stack
  virtual_router = "vr1"
  install_route  = true

  router_id = each.value.router_id
  as_number = each.value.as_number
}



resource "panos_panorama_bgp_peer_group" "azure_vwan_hub_sdwan_fw" {
  for_each = {
    hub2-fw1 = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
    }
    hub2-fw2 = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw2.name
    }
    hub4-fw = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
    }
  }
  template_stack = each.value.template_stack
  virtual_router = "vr1"
  name           = "azure"
  type           = "ebgp"
  depends_on = [
    panos_panorama_bgp.azure_vwan_hub_sdwan_fw
  ]
}



resource "panos_panorama_bgp_peer" "azure_vwan_hub_sdwan_fw" {
  for_each = {
    hub2-fw1-i0 = {
      template_stack  = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
      bgp_peer_group  = panos_panorama_bgp_peer_group.azure_vwan_hub_sdwan_fw["hub2-fw1"].name
      peer_as         = azurerm_virtual_hub.hub2.virtual_router_asn
      peer_address_ip = azurerm_virtual_hub.hub2.virtual_router_ips[0]
    }
    hub2-fw1-i1 = {
      template_stack  = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
      bgp_peer_group  = panos_panorama_bgp_peer_group.azure_vwan_hub_sdwan_fw["hub2-fw1"].name
      peer_as         = azurerm_virtual_hub.hub2.virtual_router_asn
      peer_address_ip = azurerm_virtual_hub.hub2.virtual_router_ips[1]
    }
    hub2-fw2-i0 = {
      template_stack  = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw2.name
      bgp_peer_group  = panos_panorama_bgp_peer_group.azure_vwan_hub_sdwan_fw["hub2-fw2"].name
      peer_as         = azurerm_virtual_hub.hub2.virtual_router_asn
      peer_address_ip = azurerm_virtual_hub.hub2.virtual_router_ips[0]
    }
    hub2-fw2-i1 = {
      template_stack  = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw2.name
      bgp_peer_group  = panos_panorama_bgp_peer_group.azure_vwan_hub_sdwan_fw["hub2-fw2"].name
      peer_as         = azurerm_virtual_hub.hub2.virtual_router_asn
      peer_address_ip = azurerm_virtual_hub.hub2.virtual_router_ips[1]
    }
    hub4-fw-i0 = {
      template_stack  = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
      bgp_peer_group  = panos_panorama_bgp_peer_group.azure_vwan_hub_sdwan_fw["hub4-fw"].name
      peer_as         = azurerm_virtual_hub.hub4.virtual_router_asn
      peer_address_ip = azurerm_virtual_hub.hub4.virtual_router_ips[0]
    }
    hub4-fw-i1 = {
      template_stack  = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
      bgp_peer_group  = panos_panorama_bgp_peer_group.azure_vwan_hub_sdwan_fw["hub4-fw"].name
      peer_as         = azurerm_virtual_hub.hub4.virtual_router_asn
      peer_address_ip = azurerm_virtual_hub.hub4.virtual_router_ips[1]
    }
  }
  template_stack          = each.value.template_stack
  name                    = each.key
  virtual_router          = "vr1"
  bgp_peer_group          = each.value.bgp_peer_group
  peer_as                 = each.value.peer_as
  local_address_interface = "ethernet1/2"
  local_address_ip        = "$eth1_2_ip"
  peer_address_ip         = each.value.peer_address_ip
  max_prefixes            = "unlimited"
  multi_hop               = 1
  depends_on = [
    panos_panorama_bgp_peer_group.azure_vwan_hub_sdwan_fw
  ]
  lifecycle { create_before_destroy = true }
}



resource "panos_panorama_bgp_import_rule_group" "azure_vwan_hub2_sdwan_fw" {
  for_each = {
    hub2-fw1 = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
      community_value = "49320:64799"
    }
    hub2-fw2 = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw2.name
      community_value = "49320:64800"
    }
    hub4-fw = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
      community_value = "49320:64804"
    }
  }
  template_stack = each.value.template_stack
  virtual_router = "vr1"
  rule {
      name = "r1"
      used_by = [panos_panorama_bgp_peer_group.azure_vwan_hub_sdwan_fw[each.key].name]
      community_type = "overwrite"
      community_value = each.value.community_value
  }
  depends_on = [
    panos_panorama_bgp_peer_group.azure_vwan_hub_sdwan_fw
  ]
  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_bgp_export_rule_group" "azure_vwan_hub_sdwan_fw" {
  for_each = {
    hub2-fw1 = {
      template_stack  = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
      community_value = "49320:64799"
      as_path_value   = 1
    }
    hub2-fw2 = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw2.name
      community_value = "49320:64800"
      as_path_value   = 3
    }
    hub4-fw = {
      template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
      community_value = "49320:64804"
      as_path_value   = 5
    }
  }
  template_stack = each.value.template_stack
  virtual_router = "vr1"
  rule {
    name = "r1"
    match_address_prefix {
      prefix = local.vnet_cidr.sdwan_spoke1
      exact  = false
    }
    match_route_table   = "unicast"
    action              = "allow"
    as_path_type        = each.value.as_path_value > 1 ? "prepend" : null
    as_path_value       = each.value.as_path_value > 1 ? each.value.as_path_value : null
    used_by             = [panos_panorama_bgp_peer_group.azure_vwan_hub_sdwan_fw[each.key].name]
  }
  # rule {
  #   name = "dg"
  #   match_address_prefix {
  #     prefix = "0.0.0.0/0"
  #     exact  = true
  #   }
  #   match_route_table   = "unicast"
  #   action              = var.sdwan_announce_dg ? "allow" : "deny"
  #   as_path_type        = var.sdwan_announce_dg ? "prepend" : "none"
  #   as_path_value       = var.sdwan_announce_dg ? 2 : 1
  #   used_by             = [panos_panorama_bgp_peer_group.azure_vwan_hub2_sdwan_fw1.name]
  # }
}


# resource "panos_panorama_redistribution_profile_ipv4" "azure_vwan_hub2_sdwan_fw-dg" {
#   template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
#   virtual_router = "vr1"
#   name           = "redis-dg"
#   priority       = 1
#   action         = var.sdwan_announce_dg ? "redist" : "no-redist"
#   types          = ["static"]
#   destinations = [
#     "0.0.0.0/0"
#   ]
# }

# resource "panos_panorama_bgp_redist_rule" "azure_vwan_hub2_sdwan_fw" {
#   template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
#   virtual_router = "vr1"
#   route_table    = "unicast"
#   name           = panos_panorama_redistribution_profile_ipv4.azure_vwan_hub2_sdwan_fw-dg.name
# }
