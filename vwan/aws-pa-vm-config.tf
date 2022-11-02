resource "panos_panorama_template" "aws" {
  name = "aws-azure-vwan-2isp"
}

locals {
  ip_mask = {
    for ki, vi in module.vm-fw-1.private_ip_list :
    ki => formatlist("%s/%s", module.vm-fw-1.private_ip_list[ki], split("/", module.vpc-fw-1.subnets[ki].cidr_block)[1])
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
}

resource "panos_panorama_tunnel_interface" "aws_tun10" {
  template   = panos_panorama_template.aws.name
  name       = "tunnel.10"
  vsys       = "vsys1"
  static_ips = ["169.254.21.2/30"]
}
resource "panos_panorama_tunnel_interface" "aws_tun11" {
  template   = panos_panorama_template.aws.name
  name       = "tunnel.11"
  vsys       = "vsys1"
  static_ips = ["169.254.28.6/30"]
}
resource "panos_panorama_tunnel_interface" "aws_tun20" {
  template   = panos_panorama_template.aws.name
  name       = "tunnel.20"
  vsys       = "vsys1"
  static_ips = ["169.254.22.2/30"]
}
resource "panos_panorama_tunnel_interface" "aws_tun21" {
  template   = panos_panorama_template.aws.name
  name       = "tunnel.21"
  vsys       = "vsys1"
  static_ips = ["169.254.22.6/30"]
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
    panos_panorama_tunnel_interface.aws_tun10.name,
    panos_panorama_tunnel_interface.aws_tun11.name,
    panos_panorama_tunnel_interface.aws_tun20.name,
    panos_panorama_tunnel_interface.aws_tun21.name,
  ]
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

locals {
  aws_isp1 = one([for k, v in module.vm-fw-1.public_ips : v if length(regexall("isp1", k)) > 0])
  aws_isp2 = one([for k, v in module.vm-fw-1.public_ips : v if length(regexall("isp2", k)) > 0])
  azure_i0 = tolist(azurerm_vpn_gateway.hub1-vpn1.bgp_settings[0].instance_0_bgp_peering_address[0].tunnel_ips)[1]
  azure_i1 = tolist(azurerm_vpn_gateway.hub1-vpn1.bgp_settings[0].instance_1_bgp_peering_address[0].tunnel_ips)[1]
}

resource "panos_panorama_ike_gateway" "aws_tun10" {
  template      = panos_panorama_template.aws.name
  name          = "tun10"
  peer_ip_type  = "ip"
  peer_ip_value = local.azure_i0

  interface      = "ethernet1/1"
  pre_shared_key = local.psk
  version        = "ikev2"

  local_id_type  = "ipaddr"
  local_id_value = local.aws_isp1
  peer_id_type   = "ipaddr"
  peer_id_value  = local.azure_i0


  enable_nat_traversal              = true
  nat_traversal_keep_alive          = 10
  nat_traversal_enable_udp_checksum = true

  enable_dead_peer_detection   = true
  dead_peer_detection_interval = 2
  dead_peer_detection_retry    = 5
}
resource "panos_panorama_ike_gateway" "aws_tun11" {
  template      = panos_panorama_template.aws.name
  name          = "tun11"
  peer_ip_type  = "ip"
  peer_ip_value = local.azure_i1

  interface      = "ethernet1/1"
  pre_shared_key = local.psk
  version        = "ikev2"

  local_id_type  = "ipaddr"
  local_id_value = local.aws_isp1
  peer_id_type   = "ipaddr"
  peer_id_value  = local.azure_i1


  enable_nat_traversal              = true
  nat_traversal_keep_alive          = 10
  nat_traversal_enable_udp_checksum = true

  enable_dead_peer_detection   = true
  dead_peer_detection_interval = 2
  dead_peer_detection_retry    = 5
}

resource "panos_panorama_ike_gateway" "aws_tun20" {
  template      = panos_panorama_template.aws.name
  name          = "tun20"
  peer_ip_type  = "ip"
  peer_ip_value = local.azure_i0

  interface      = "ethernet1/2"
  pre_shared_key = local.psk
  version        = "ikev2"

  local_id_type  = "ipaddr"
  local_id_value = local.aws_isp2
  peer_id_type   = "ipaddr"
  peer_id_value  = local.azure_i0

  enable_nat_traversal              = true
  nat_traversal_keep_alive          = 10
  nat_traversal_enable_udp_checksum = true

  enable_dead_peer_detection   = true
  dead_peer_detection_interval = 2
  dead_peer_detection_retry    = 5
}
resource "panos_panorama_ike_gateway" "aws_tun21" {
  template      = panos_panorama_template.aws.name
  name          = "tun21"
  peer_ip_type  = "ip"
  peer_ip_value = local.azure_i1

  interface      = "ethernet1/2"
  pre_shared_key = local.psk
  version        = "ikev2"

  local_id_type  = "ipaddr"
  local_id_value = local.aws_isp2
  peer_id_type   = "ipaddr"
  peer_id_value  = local.azure_i1

  enable_nat_traversal              = true
  nat_traversal_keep_alive          = 10
  nat_traversal_enable_udp_checksum = true

  enable_dead_peer_detection   = true
  dead_peer_detection_interval = 2
  dead_peer_detection_retry    = 5
}

resource "panos_panorama_ipsec_tunnel" "aws_tun10" {
  name             = "tun10"
  template         = panos_panorama_template.aws.name
  tunnel_interface = panos_panorama_tunnel_interface.aws_tun10.name
  anti_replay      = false
  ak_ike_gateway   = panos_panorama_ike_gateway.aws_tun10.name
}
resource "panos_panorama_ipsec_tunnel" "aws_tun11" {
  name             = "tun11"
  template         = panos_panorama_template.aws.name
  tunnel_interface = panos_panorama_tunnel_interface.aws_tun11.name
  anti_replay      = false
  ak_ike_gateway   = panos_panorama_ike_gateway.aws_tun11.name
}
resource "panos_panorama_ipsec_tunnel" "aws_tun20" {
  name             = "tun20"
  template         = panos_panorama_template.aws.name
  tunnel_interface = panos_panorama_tunnel_interface.aws_tun20.name
  anti_replay      = false
  ak_ike_gateway   = panos_panorama_ike_gateway.aws_tun20.name
}
resource "panos_panorama_ipsec_tunnel" "aws_tun21" {
  name             = "tun21"
  template         = panos_panorama_template.aws.name
  tunnel_interface = panos_panorama_tunnel_interface.aws_tun21.name
  anti_replay      = false
  ak_ike_gateway   = panos_panorama_ike_gateway.aws_tun21.name
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
  ]
}



resource "panos_panorama_bgp" "aws-vr1_bgp" {
  template       = panos_panorama_template.aws.name
  virtual_router = panos_virtual_router.aws-vr1.name
  install_route  = true

  router_id = "169.254.21.2"
  as_number = 65516
}
resource "panos_panorama_bgp_redist_rule" "aws-lo99" {
  template       = panos_panorama_template.aws.name
  virtual_router = panos_virtual_router.aws-vr1.name
  route_table    = "unicast"
  name           = "192.168.99.1/32"
  set_med        = "20"
}
resource "panos_panorama_bgp_peer_group" "aws-vr1-g1" {
  template       = panos_panorama_template.aws.name
  virtual_router = panos_virtual_router.aws-vr1.name
  name           = "azure"
  type           = "ebgp"
}
resource "panos_panorama_bgp_peer" "tun10" {
  template                = panos_panorama_template.aws.name
  name                    = "tun10"
  virtual_router          = panos_virtual_router.aws-vr1.name
  bgp_peer_group          = panos_panorama_bgp_peer_group.aws-vr1-g1.name
  peer_as                 = 65515
  local_address_interface = panos_panorama_tunnel_interface.aws_tun10.name
  local_address_ip        = panos_panorama_tunnel_interface.aws_tun10.static_ips[0]
  peer_address_ip         = "169.254.21.1"
  max_prefixes            = "unlimited"
  multi_hop               = 1
}
resource "panos_panorama_bgp_peer" "tun21" {
  template                = panos_panorama_template.aws.name
  name                    = "tun21"
  virtual_router          = panos_virtual_router.aws-vr1.name
  bgp_peer_group          = panos_panorama_bgp_peer_group.aws-vr1-g1.name
  peer_as                 = 65515
  local_address_interface = panos_panorama_tunnel_interface.aws_tun21.name
  local_address_ip        = panos_panorama_tunnel_interface.aws_tun21.static_ips[0]
  peer_address_ip         = "169.254.22.5"
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

