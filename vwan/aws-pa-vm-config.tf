module "cfg_aws_fw" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-vwan-aws-2isp"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [local.ip_mask["isp1"][0]]
      zone       = "public"
    }
    "ethernet1/2" = {
      static_ips = [local.ip_mask["isp2"][0]]
      zone       = "public"
    }
    "ethernet1/3" = {
      static_ips = [local.ip_mask["priv"][0]]
      zone       = "private"
    }
    "tunnel.10" = {
      zone       = "vpn"
    }
    "tunnel.11" = {
      zone       = "vpn"
    }
    "tunnel.20" = {
      zone       = "vpn"
    }
    "tunnel.21" = {
      zone       = "vpn"
    }
    "loopback.1" = {
      static_ips = ["${var.peering_address.aws_fw1[0]}/32"]
      zone       = "vpn"
    }
    "loopback.2" = {
      static_ips = ["${var.peering_address.aws_fw1[1]}/32"]
      zone       = "vpn"
    }
  }
  routes = {
    dg_isp1 = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = cidrhost(module.aws_vpc.subnets["isp1"].cidr_block, 1)
    }
    dg_isp2 = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(module.aws_vpc.subnets["isp2"].cidr_block, 1)
    }
    local = {
      destination  = module.aws_vpc.vpc.cidr_block
      interface   = "ethernet1/3"
      type        = "ip-address"
      next_hop    = cidrhost(module.aws_vpc.subnets["priv"].cidr_block, 1)
    }
    hub2-i0-0 = {
      destination = "${var.peering_address.hub2_i0[0]}/32"
      interface   = "tunnel.10"
    }
    hub2-i0-1 = {
      destination = "${var.peering_address.hub2_i0[1]}/32"
      interface   = "tunnel.11"
    }
    hub2-i1-0 = {
      destination = "${var.peering_address.hub2_i1[0]}/32"
      interface   = "tunnel.20"
    }
    hub2-i1-1 = {
      destination = "${var.peering_address.hub2_i1[1]}/32"
      interface   = "tunnel.21"
    }
  }
  enable_ecmp             = true
}


resource "panos_panorama_template_stack" "azure_vwan_aws_fw" {
  name         = "azure-vwan-aws-fw-ts"
  default_vsys = "vsys1"
  templates = [
    module.cfg_aws_fw.template_name,
    "vm common",
  ]
  description = "pat:acp"
}

locals {
  ip_mask = {
    for ki, vi in module.aws_fw.private_ip_list :
    ki => formatlist("%s/%s", module.aws_fw.private_ip_list[ki], split("/", module.aws_vpc.subnets[ki].cidr_block)[1])
  }
}


resource "panos_panorama_ike_gateway" "aws_fw1-hub2" {
  for_each = local.tunnel-aws_fw1-hub2

  template      = module.cfg_aws_fw.template_name
  name          = each.key
  peer_ip_type  = "ip"
  peer_ip_value = each.value.peer_ip

  interface      = each.value.interface
  pre_shared_key = var.psk
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
}

resource "panos_panorama_ipsec_tunnel" "aws_fw1-hub2" {
  for_each = local.tunnel-aws_fw1-hub2

  name             = each.key
  template         = module.cfg_aws_fw.template_name
  tunnel_interface = each.value.tunnel_interface
  anti_replay      = false
  ak_ike_gateway   = each.key

  depends_on = [
    panos_panorama_ike_gateway.aws_fw1-hub2
  ]
}

resource "panos_panorama_bgp" "aws-vr1_bgp" {
  template       = module.cfg_aws_fw.template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = var.router_ids["aws_fw1"]
  as_number = var.asn["aws_fw1"]
}
resource "panos_panorama_bgp_redist_rule" "aws-vr1-all" {
  template       = module.cfg_aws_fw.template_name
  virtual_router = "vr1"
  route_table    = "unicast"
  name           = module.aws_vpc.vpc.cidr_block
  set_med        = "20"
  depends_on = [
    panos_panorama_bgp.aws-vr1_bgp
  ]
}
resource "panos_panorama_bgp_peer_group" "aws-vr1-g1" {
  template       = module.cfg_aws_fw.template_name
  virtual_router = "vr1"
  name           = "azure"
  type           = "ebgp"
  depends_on = [
    panos_panorama_bgp.aws-vr1_bgp
  ]
}
resource "panos_panorama_bgp_peer" "tun10" {
  template                = module.cfg_aws_fw.template_name
  name                    = "tun10"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.aws-vr1-g1.name
  peer_as                 = var.asn.hub2
  local_address_interface = "loopback.1"
  local_address_ip        = module.cfg_aws_fw.interfaces["loopback.1"].static_ips[0]
  peer_address_ip         = var.peering_address.hub2_i0[0]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}
resource "panos_panorama_bgp_peer" "tun11" {
  template                = module.cfg_aws_fw.template_name
  name                    = "tun11"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.aws-vr1-g1.name
  peer_as                 = var.asn.hub2
  local_address_interface = "loopback.1"
  local_address_ip        = module.cfg_aws_fw.interfaces["loopback.1"].static_ips[0]
  peer_address_ip         = var.peering_address.hub2_i0[1]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}
resource "panos_panorama_bgp_peer" "tun20" {
  template                = module.cfg_aws_fw.template_name
  name                    = "tun20"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.aws-vr1-g1.name
  peer_as                 = var.asn.hub2
  local_address_interface = "loopback.2"
  local_address_ip        = module.cfg_aws_fw.interfaces["loopback.2"].static_ips[0]
  peer_address_ip         = var.peering_address.hub2_i1[0]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}
resource "panos_panorama_bgp_peer" "tun21" {
  template                = module.cfg_aws_fw.template_name
  name                    = "tun21"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.aws-vr1-g1.name
  peer_as                 = var.asn.hub2
  local_address_interface = "loopback.2"
  local_address_ip        = module.cfg_aws_fw.interfaces["loopback.2"].static_ips[0]
  peer_address_ip         = var.peering_address.hub2_i1[1]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_export_rule_group" "aws_vr1_bgp_ex" {
  template                = module.cfg_aws_fw.template_name
  virtual_router = "vr1"
  rule {
    name = "r1"
    match_address_prefix {
      prefix = module.aws_vpc.vpc.cidr_block
      exact  = false
    }
    match_route_table   = "unicast"
    action              = "allow"
    used_by             = [panos_panorama_bgp_peer_group.aws-vr1-g1.name]
  }

  lifecycle { create_before_destroy = true }
}

