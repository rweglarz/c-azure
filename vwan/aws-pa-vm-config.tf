resource "panos_panorama_template" "aws" {
  name = "aws-azure-vwan-2isp"
}

locals {
  ip_mask = {
    for ki, vi in module.vm-fw-1.private_ip_list :
    ki => formatlist("%s/%s", module.vm-fw-1.private_ip_list[ki], split("/", module.vpc-fw-1.subnets[ki].cidr_block)[1])
  }
}
resource "panos_panorama_management_profile" "aws_ping" {
  template   = panos_panorama_template.aws.name

  name = "ping"
  ping = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "panos_panorama_management_profile" "aws_ssh" {
  template   = panos_panorama_template.aws.name

  name = "ssh"
  ping = true
  ssh  = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "panos_panorama_ethernet_interface" "aws_eth1_1" {
  template   = panos_panorama_template.aws.name
  name       = "ethernet1/1"
  vsys       = "vsys1"
  mode       = "layer3"
  static_ips = [local.ip_mask["isp1"][0]]
}
resource "panos_panorama_ethernet_interface" "aws_eth1_2" {
  template   = panos_panorama_template.aws.name
  name       = "ethernet1/2"
  vsys       = "vsys1"
  mode       = "layer3"
  static_ips = [local.ip_mask["isp2"][0]]
}
resource "panos_panorama_ethernet_interface" "aws_eth1_3" {
  template   = panos_panorama_template.aws.name
  name       = "ethernet1/3"
  vsys       = "vsys1"
  mode       = "layer3"
  static_ips = [local.ip_mask["priv"][0]]
  management_profile = panos_panorama_management_profile.aws_ssh.name
}

resource "panos_panorama_tunnel_interface" "aws_tun10" {
  template = panos_panorama_template.aws.name
  name     = "tunnel.10"
  vsys     = "vsys1"
}
resource "panos_panorama_tunnel_interface" "aws_tun11" {
  template = panos_panorama_template.aws.name
  name     = "tunnel.11"
  vsys     = "vsys1"
}
resource "panos_panorama_tunnel_interface" "aws_tun20" {
  template = panos_panorama_template.aws.name
  name     = "tunnel.20"
  vsys     = "vsys1"
}
resource "panos_panorama_tunnel_interface" "aws_tun21" {
  template = panos_panorama_template.aws.name
  name     = "tunnel.21"
  vsys     = "vsys1"
}

resource "panos_panorama_loopback_interface" "aws_isp1" {
  name       = "loopback.1"
  template   = panos_panorama_template.aws.name
  static_ips = ["${var.peering_address.aws_fw1[0]}/32"]
}
resource "panos_panorama_loopback_interface" "aws_isp2" {
  name       = "loopback.2"
  template   = panos_panorama_template.aws.name
  static_ips = ["${var.peering_address.aws_fw1[1]}/32"]
}


resource "panos_virtual_router" "aws-vr1" {
  template = panos_panorama_template.aws.name
  name     = "vr1"

  enable_ecmp             = true
  ecmp_max_path           = 4
  ecmp_strict_source_path = true

  interfaces = [
    panos_panorama_ethernet_interface.aws_eth1_1.name,
    panos_panorama_ethernet_interface.aws_eth1_2.name,
    panos_panorama_ethernet_interface.aws_eth1_3.name,
    panos_panorama_tunnel_interface.aws_tun10.name,
    panos_panorama_tunnel_interface.aws_tun11.name,
    panos_panorama_tunnel_interface.aws_tun20.name,
    panos_panorama_tunnel_interface.aws_tun21.name,
    panos_panorama_loopback_interface.aws_isp1.name,
    panos_panorama_loopback_interface.aws_isp2.name,
  ]
}
resource "panos_panorama_static_route_ipv4" "aws-vr1-tun10" {
  template       = panos_panorama_template.aws.name
  virtual_router = panos_virtual_router.aws-vr1.name
  name           = "hub2-i0-0"
  destination    = "${var.peering_address.hub2_i0[0]}/32"
  interface      = panos_panorama_tunnel_interface.aws_tun10.name
  type           = ""
}
resource "panos_panorama_static_route_ipv4" "aws-vr1-tun11" {
  template       = panos_panorama_template.aws.name
  virtual_router = panos_virtual_router.aws-vr1.name
  name           = "hub2-i0-1"
  destination    = "${var.peering_address.hub2_i0[1]}/32"
  interface      = panos_panorama_tunnel_interface.aws_tun11.name
  type           = ""
}
resource "panos_panorama_static_route_ipv4" "aws-vr1-tun20" {
  template       = panos_panorama_template.aws.name
  virtual_router = panos_virtual_router.aws-vr1.name
  name           = "hub2-i1-0"
  destination    = "${var.peering_address.hub2_i1[0]}/32"
  interface      = panos_panorama_tunnel_interface.aws_tun20.name
  type           = ""
}
resource "panos_panorama_static_route_ipv4" "aws-vr1-tun21" {
  template       = panos_panorama_template.aws.name
  virtual_router = panos_virtual_router.aws-vr1.name
  name           = "hub2-i1-1"
  destination    = "${var.peering_address.hub2_i1[1]}/32"
  interface      = panos_panorama_tunnel_interface.aws_tun21.name
  type           = ""
}

resource "panos_panorama_static_route_ipv4" "aws-vr1-eth1_1-dg" {
  template       = panos_panorama_template.aws.name
  virtual_router = panos_virtual_router.aws-vr1.name
  name           = "dg isp1"
  destination    = "0.0.0.0/0"
  next_hop       = cidrhost(module.vpc-fw-1.subnets["isp1"].cidr_block, 1)
  interface      = panos_panorama_ethernet_interface.aws_eth1_1.name
}
resource "panos_panorama_static_route_ipv4" "aws-vr1-eth1_2-dg" {
  template       = panos_panorama_template.aws.name
  virtual_router = panos_virtual_router.aws-vr1.name
  name           = "dg isp2"
  destination    = "0.0.0.0/0"
  next_hop       = cidrhost(module.vpc-fw-1.subnets["isp2"].cidr_block, 1)
  interface      = panos_panorama_ethernet_interface.aws_eth1_2.name
}


resource "panos_panorama_ike_gateway" "aws_fw1-hub2" {
  for_each = local.tunnel-aws_fw1-hub2

  template      = panos_panorama_template.aws.name
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
  template         = panos_panorama_template.aws.name
  tunnel_interface = each.value.tunnel_interface
  anti_replay      = false
  ak_ike_gateway   = each.key

  depends_on = [
    panos_panorama_ike_gateway.aws_fw1-hub2
  ]
}


resource "panos_zone" "internet" {
  template = panos_panorama_template.aws.name
  name     = "internet"
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.aws_eth1_1.name,
    panos_panorama_ethernet_interface.aws_eth1_2.name,
  ]
}
resource "panos_zone" "vpn" {
  template = panos_panorama_template.aws.name
  name     = "vpn"
  mode     = "layer3"
  interfaces = [
    panos_panorama_tunnel_interface.aws_tun10.name,
    panos_panorama_tunnel_interface.aws_tun11.name,
    panos_panorama_tunnel_interface.aws_tun20.name,
    panos_panorama_tunnel_interface.aws_tun21.name,
    panos_panorama_loopback_interface.aws_isp1.name,
    panos_panorama_loopback_interface.aws_isp2.name,
  ]
}
resource "panos_zone" "data" {
  template = panos_panorama_template.aws.name
  name     = "data"
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.aws_eth1_3.name,
  ]
}



resource "panos_panorama_bgp" "aws-vr1_bgp" {
  template       = panos_panorama_template.aws.name
  virtual_router = panos_virtual_router.aws-vr1.name
  install_route  = true

  router_id = "169.254.21.2"
  as_number = var.asn["aws_fw1"]
}
resource "panos_panorama_bgp_redist_rule" "aws-vr1-all" {
  template       = panos_panorama_template.aws.name
  virtual_router = panos_virtual_router.aws-vr1.name
  route_table    = "unicast"
  name           = module.vpc-fw-1.vpc.cidr_block
  set_med        = "20"
  depends_on = [
    panos_panorama_bgp.aws-vr1_bgp
  ]
}
resource "panos_panorama_bgp_peer_group" "aws-vr1-g1" {
  template       = panos_panorama_template.aws.name
  virtual_router = panos_virtual_router.aws-vr1.name
  name           = "azure"
  type           = "ebgp"
  depends_on = [
    panos_panorama_bgp.aws-vr1_bgp
  ]
}
resource "panos_panorama_bgp_peer" "tun10" {
  template                = panos_panorama_template.aws.name
  name                    = "tun10"
  virtual_router          = panos_virtual_router.aws-vr1.name
  bgp_peer_group          = panos_panorama_bgp_peer_group.aws-vr1-g1.name
  peer_as                 = var.asn.hub2
  local_address_interface = panos_panorama_loopback_interface.aws_isp1.name
  local_address_ip        = panos_panorama_loopback_interface.aws_isp1.static_ips[0]
  peer_address_ip         = var.peering_address.hub2_i0[0]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}
resource "panos_panorama_bgp_peer" "tun11" {
  template                = panos_panorama_template.aws.name
  name                    = "tun11"
  virtual_router          = panos_virtual_router.aws-vr1.name
  bgp_peer_group          = panos_panorama_bgp_peer_group.aws-vr1-g1.name
  peer_as                 = var.asn.hub2
  local_address_interface = panos_panorama_loopback_interface.aws_isp1.name
  local_address_ip        = panos_panorama_loopback_interface.aws_isp1.static_ips[0]
  peer_address_ip         = var.peering_address.hub2_i0[1]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}
resource "panos_panorama_bgp_peer" "tun20" {
  template                = panos_panorama_template.aws.name
  name                    = "tun20"
  virtual_router          = panos_virtual_router.aws-vr1.name
  bgp_peer_group          = panos_panorama_bgp_peer_group.aws-vr1-g1.name
  peer_as                 = var.asn.hub2
  local_address_interface = panos_panorama_loopback_interface.aws_isp2.name
  local_address_ip        = panos_panorama_loopback_interface.aws_isp2.static_ips[0]
  peer_address_ip         = var.peering_address.hub2_i1[0]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}
resource "panos_panorama_bgp_peer" "tun21" {
  template                = panos_panorama_template.aws.name
  name                    = "tun21"
  virtual_router          = panos_virtual_router.aws-vr1.name
  bgp_peer_group          = panos_panorama_bgp_peer_group.aws-vr1-g1.name
  peer_as                 = var.asn.hub2
  local_address_interface = panos_panorama_loopback_interface.aws_isp2.name
  local_address_ip        = panos_panorama_loopback_interface.aws_isp2.static_ips[0]
  peer_address_ip         = var.peering_address.hub2_i1[1]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_export_rule_group" "aws_vr1_bgp_ex" {
  template                = panos_panorama_template.aws.name
  virtual_router = "vr1"
  rule {
    name = "r1"
    match_address_prefix {
      prefix = module.vpc-fw-1.vpc.cidr_block
      exact  = false
    }
    match_route_table   = "unicast"
    action              = "allow"
    used_by             = [panos_panorama_bgp_peer_group.aws-vr1-g1.name]
  }

  lifecycle { create_before_destroy = true }
}

