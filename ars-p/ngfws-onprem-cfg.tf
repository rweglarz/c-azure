module "cfg_onprem_fw" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "${local.template_prefix}-onprem-fw-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.onprem_fw["eth1_1_ip"], local.subnet_prefix_length)]
      zone       = "public"
    }
    "ethernet1/2" = {
      static_ips = [format("%s/%s", local.onprem_fw["eth1_2_ip"], local.subnet_prefix_length)]
      zone       = "public"
    }
    "ethernet1/3" = {
      static_ips = [format("%s/%s", local.onprem_fw["eth1_3_ip"], local.subnet_prefix_length)]
      zone       = "private"
    }
    "tunnel.11" = {
      zone       = "vpn"
    }
    "tunnel.12" = {
      zone       = "vpn"
    }
    "tunnel.21" = {
      zone       = "vpn"
    }
    "tunnel.22" = {
      zone       = "vpn"
    }
    "loopback.1" = {
      static_ips = ["${local.peering_addresses.onprem_fw[0]}/32"]
      zone       = "vpn"
    }
    "loopback.2" = {
      static_ips = ["${local.peering_addresses.onprem_fw[1]}/32"]
      zone       = "vpn"
    }
  }
  routes = {
    dg1 = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_onprem.subnets["isp1"].address_prefixes[0], 1)
    }
    dg2 = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_onprem.subnets["isp2"].address_prefixes[0], 1)
    }
    r10 = {
      destination = "10.0.0.0/8"
      interface   = "ethernet1/3"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_onprem.subnets["private"].address_prefixes[0], 1)
    }
    vng_isp1_c1 = {
      destination = format("%s/32", local.peering_addresses["vng"]["c1"][0])
      interface   = "tunnel.11"
    }
    vng_isp1_c2 = {
      destination = format("%s/32", local.peering_addresses["vng"]["c2"][0])
      interface   = "tunnel.12"
    }
    vng_isp2_c1 = {
      destination = format("%s/32", local.peering_addresses["vng"]["c1"][1])
      interface   = "tunnel.21"
    }
    vng_isp2_c2 = {
      destination = format("%s/32", local.peering_addresses["vng"]["c2"][1])
      interface   = "tunnel.22"
    }
  }
  enable_ecmp = true
}

resource "panos_panorama_template_stack" "onprem_fw" {
  name = "${local.template_prefix}-onprem-fw-ts"
  default_vsys = "vsys1"
  templates = [
    module.cfg_onprem_fw.template_name,
    "vm common",
  ]
  description = "pat:acp"
}


locals {
  tunnel-onprem-vng = {
    tun-isp1-c1 = {
      interface        = "ethernet1/1"
      tunnel_interface = "tunnel.11"
      local_ip         = module.onprem_fw.public_ips["isp1"]
      peer_ip          = azurerm_public_ip.vng["c1"].ip_address
      vng_peering_ip   = local.peering_addresses["vng"]["c1"][0]
      local_peering_ip = format("%s/32", local.peering_addresses["onprem_fw"][0])
      loopback_interface = "loopback.1"
    },
    tun-isp1-c2 = {
      interface        = "ethernet1/1"
      tunnel_interface = "tunnel.12"
      local_ip         = module.onprem_fw.public_ips["isp1"]
      peer_ip          = azurerm_public_ip.vng["c2"].ip_address
      vng_peering_ip   = local.peering_addresses["vng"]["c2"][0]
      loopback_interface = "loopback.1"
    },
    tun-isp2-c1 = {
      interface        = "ethernet1/2"
      tunnel_interface = "tunnel.21"
      local_ip         = module.onprem_fw.public_ips["isp2"]
      peer_ip          = azurerm_public_ip.vng["c1"].ip_address
      vng_peering_ip   = local.peering_addresses["vng"]["c1"][1]
      loopback_interface = "loopback.2"
    },
    tun-isp2-12 = {
      interface        = "ethernet1/2"
      tunnel_interface = "tunnel.22"
      local_ip         = module.onprem_fw.public_ips["isp2"]
      peer_ip          = azurerm_public_ip.vng["c2"].ip_address
      vng_peering_ip   = local.peering_addresses["vng"]["c2"][1]
      loopback_interface = "loopback.2"
    },
  }
}


#region tunnel
resource "panos_ike_crypto_profile" "onprem_azure" {
  template  = module.cfg_onprem_fw.template_name
  name      = "azure"

  dh_groups = [
      "group2",
  ]
  authentications = [
      "sha256",
  ]
  encryptions = ["aes-128-cbc", "aes-256-cbc"]
  lifetime_value = 8
  authentication_multiple = 3
}

# resource "panos_ipsec_crypto_profile" "onprem_azure" {
#     name = "azure"
#     authentications = ["sha1", "sha256"]
#     encryptions     = ["aes-128-cbc"]
#     dh_group        = "group2"
#     lifetime_type   = "hours"
#     lifetime_value  = 1
# }

resource "panos_panorama_ike_gateway" "onprem_vng" {
  for_each = local.tunnel-onprem-vng

  template      = module.cfg_onprem_fw.template_name
  name          = each.key
  peer_ip_type  = "ip"
  peer_ip_value = each.value.peer_ip

  interface      = each.value.interface
  pre_shared_key = random_bytes.psk.hex
  version        = "ikev2"

  local_id_type  = "ipaddr"
  local_id_value = each.value.local_ip
  peer_id_type   = "ipaddr"
  peer_id_value  = each.value.peer_ip


  enable_nat_traversal              = true
  nat_traversal_keep_alive          = 10
  nat_traversal_enable_udp_checksum = true

  enable_dead_peer_detection   = true
  dead_peer_detection_interval = 2
  dead_peer_detection_retry    = 5

  ikev2_crypto_profile = panos_ike_crypto_profile.onprem_azure.name
}

resource "panos_panorama_ipsec_tunnel" "onprem_vng" {
  for_each = local.tunnel-onprem-vng

  name             = each.key
  template         = module.cfg_onprem_fw.template_name
  tunnel_interface = each.value.tunnel_interface
  anti_replay      = false
  ak_ike_gateway   = each.key
  ak_ipsec_crypto_profile = "azure"

  depends_on = [
    panos_panorama_ike_gateway.onprem_vng
  ]
}
#endregion



#region bgp
resource "panos_panorama_bgp" "onprem_fw" {
  template       = module.cfg_onprem_fw.template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = local.onprem_fw["eth1_3_ip"]
  as_number = var.asn["onprem_fw"]
}

resource "panos_panorama_bgp_peer_group" "onprem_fw-vng" {
  template        = module.cfg_onprem_fw.template_name
  virtual_router  = "vr1"
  name            = "onprem_ars"
  type            = "ebgp"

  depends_on = [
    panos_panorama_bgp.onprem_fw
  ]
}

resource "panos_panorama_bgp_peer" "onprem_fw-vng" {
  for_each = local.tunnel-onprem-vng

  template                = module.cfg_onprem_fw.template_name
  name                    = "vng-${each.key}"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.onprem_fw-vng.name
  peer_as                 = var.asn["ars"]
  local_address_interface = each.value.loopback_interface
  local_address_ip        = module.cfg_onprem_fw.interfaces[each.value.loopback_interface].static_ips[0]
  peer_address_ip         = each.value.vng_peering_ip
  max_prefixes            = "unlimited"
  multi_hop               = 1

  enable_sender_side_loop_detection = true

  depends_on = [
    panos_panorama_bgp.onprem_fw
  ]
}

resource "panos_panorama_bgp_redist_rule" "onprem_fw" {
  template       = module.cfg_onprem_fw.template_name
  virtual_router = "vr1"
  route_table    = "unicast"
  name           = var.cidr_onprem
  set_med        = "20"
  depends_on = [
    panos_panorama_bgp.onprem_fw
  ]
}

#endregion
