locals {
  subnet_prefix_length = 28
  public_ip = {
    aws_fw1 = [
      one([for k, v in module.vm-fw-1.public_ips : v if length(regexall("isp1", k)) > 0]),
      one([for k, v in module.vm-fw-1.public_ips : v if length(regexall("isp2", k)) > 0]),
    ],
    hub1_vpn1 = [
      tolist(azurerm_vpn_gateway.hub1-vpn1.bgp_settings[0].instance_0_bgp_peering_address[0].tunnel_ips)[1],
      tolist(azurerm_vpn_gateway.hub1-vpn1.bgp_settings[0].instance_1_bgp_peering_address[0].tunnel_ips)[1],
    ]
  }
  tunnel-aws_fw1-hub1_vpn1 = {
    tun10 = {
      interface        = "ethernet1/1"
      tunnel_interface = "tunnel.10"
      local_ip         = local.public_ip.aws_fw1[0]
      peer_ip          = local.public_ip.hub1_vpn1[0]
    },
    tun11 = {
      interface        = "ethernet1/1"
      tunnel_interface = "tunnel.11"
      local_ip         = local.public_ip.aws_fw1[0]
      peer_ip          = local.public_ip.hub1_vpn1[1]
    },
    tun20 = {
      interface        = "ethernet1/2"
      tunnel_interface = "tunnel.20"
      local_ip         = local.public_ip.aws_fw1[1]
      peer_ip          = local.public_ip.hub1_vpn1[0]
    },
    tun21 = {
      interface        = "ethernet1/2"
      tunnel_interface = "tunnel.21"
      local_ip         = local.public_ip.aws_fw1[1]
      peer_ip          = local.public_ip.hub1_vpn1[1]
    },
  }
}
