locals {
  subnet_prefix_length = 28
  vnet_address_space = {
    ipsec_hub1   = [cidrsubnet(var.hub1_cidr, 4, 2)]
    ipsec_hub2   = [cidrsubnet(var.hub2_cidr, 4, 2)]
    ipsec_spoke1 = [cidrsubnet(var.ext_spokes_cidr, 4, 2)]
    sdwan_spoke1 = [cidrsubnet(var.ext_spokes_cidr, 4, 1)]
  }

  public_ip = {
    aws_fw1 = [
      one([for k, v in module.vm-fw-1.public_ips : v if length(regexall("isp1", k)) > 0]),
      one([for k, v in module.vm-fw-1.public_ips : v if length(regexall("isp2", k)) > 0]),
    ],
    hub1_vpn1 = [
      [for ip in azurerm_vpn_gateway.hub1-vpn1.bgp_settings[0].instance_0_bgp_peering_address[0].tunnel_ips: ip if cidrhost("${ip}/12",0)!=cidrhost("172.16.0.0/12",0)][0],
      [for ip in azurerm_vpn_gateway.hub1-vpn1.bgp_settings[0].instance_1_bgp_peering_address[0].tunnel_ips: ip if cidrhost("${ip}/12",0)!=cidrhost("172.16.0.0/12",0)][0],
    ]
    ipsec_hub1_fw1 = [
      one([for k, v in module.ipsec_hub1_fw1.public_ips : v if length(regexall("internet", k)) > 0]),
    ],
    ipsec_hub1_fw2 = [
      one([for k, v in module.ipsec_hub1_fw2.public_ips : v if length(regexall("internet", k)) > 0]),
    ],
    ipsec_spoke1_fw = [
      one([for k, v in module.ipsec_spoke1_fw.public_ips : v if length(regexall("internet", k)) > 0]),
    ],
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
  bootstrap_options = {
    sdwan_spoke1_fw = {
      tplname = panos_panorama_template_stack.azure_vwan_sdwan_spoke1_fw.name
    }
  }
}
