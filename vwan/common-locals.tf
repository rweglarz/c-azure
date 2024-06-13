locals {
  dns_ttl              = 90
  subnet_prefix_length = 28
  vnet_cidr = {
    hub1            = cidrsubnet(var.region1_cidr, 4, 0)
    hub1_sec        = cidrsubnet(var.region1_cidr, 4, 1)
    hub1_sec_spoke1 = cidrsubnet(var.region1_cidr, 5, 2*2 + 0)
    hub1_sec_spoke2 = cidrsubnet(var.region1_cidr, 5, 2*2 + 1)
    hub2            = cidrsubnet(var.region1_cidr, 4, 4)
    hub2_spoke1     = cidrsubnet(var.region1_cidr, 5, 5*2 + 0)
    hub2_spoke2     = cidrsubnet(var.region1_cidr, 5, 5*2 + 1)
    hub2_sdwan      = cidrsubnet(var.region1_cidr, 4, 7)
    hub2_dns        = cidrsubnet(var.region1_cidr, 4, 8)

    hub3            = cidrsubnet(var.region2_cidr, 4, 0)
    hub4            = cidrsubnet(var.region2_cidr, 4, 4)
    hub4_spoke1     = cidrsubnet(var.region2_cidr, 5, 5*2 + 0)
    hub4_spoke2     = cidrsubnet(var.region2_cidr, 5, 5*2 + 1)
    hub4_sdwan      = cidrsubnet(var.region2_cidr, 4, 7)

    sdwan_spoke1    = cidrsubnet(var.ext_spokes_cidr, 4, 1)
  }

  public_ip = {
    aws_fw1 = [
      one([for k, v in module.vm-fw-1.public_ips : v if length(regexall("isp1", k)) > 0]),
      one([for k, v in module.vm-fw-1.public_ips : v if length(regexall("isp2", k)) > 0]),
    ],
    hub2 = [
      [for ip in azurerm_vpn_gateway.hub2.bgp_settings[0].instance_0_bgp_peering_address[0].tunnel_ips: ip if cidrhost("${ip}/12",0)!=cidrhost("172.16.0.0/12",0)][0],
      [for ip in azurerm_vpn_gateway.hub2.bgp_settings[0].instance_1_bgp_peering_address[0].tunnel_ips: ip if cidrhost("${ip}/12",0)!=cidrhost("172.16.0.0/12",0)][0],
    ]
    hub4 = [
      [for ip in azurerm_vpn_gateway.hub4.bgp_settings[0].instance_0_bgp_peering_address[0].tunnel_ips: ip if cidrhost("${ip}/12",0)!=cidrhost("172.16.0.0/12",0)][0],
      [for ip in azurerm_vpn_gateway.hub4.bgp_settings[0].instance_1_bgp_peering_address[0].tunnel_ips: ip if cidrhost("${ip}/12",0)!=cidrhost("172.16.0.0/12",0)][0],
    ]
  }

  tunnel-aws_fw1-hub2 = {
    tun10 = {
      interface        = "ethernet1/1"
      tunnel_interface = "tunnel.10"
      local_ip         = local.public_ip.aws_fw1[0]
      peer_ip          = local.public_ip.hub2[0]
    },
    tun11 = {
      interface        = "ethernet1/1"
      tunnel_interface = "tunnel.11"
      local_ip         = local.public_ip.aws_fw1[0]
      peer_ip          = local.public_ip.hub2[1]
    },
    tun20 = {
      interface        = "ethernet1/2"
      tunnel_interface = "tunnel.20"
      local_ip         = local.public_ip.aws_fw1[1]
      peer_ip          = local.public_ip.hub2[0]
    },
    tun21 = {
      interface        = "ethernet1/2"
      tunnel_interface = "tunnel.21"
      local_ip         = local.public_ip.aws_fw1[1]
      peer_ip          = local.public_ip.hub2[1]
    },
  }
  bootstrap_options = {
    common = merge(
      var.bootstrap_options.common,
      {
        vm-auth-key = panos_vm_auth_key.this.auth_key
      }
    )
    aws_fw = {
      tplname = panos_panorama_template_stack.azure_vwan_aws_fw.name
    }
    }
    hub4_sdwan_fw = {
      tplname = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
    }
    sdwan_spoke1_fw = {
      tplname = panos_panorama_template_stack.azure_vwan_sdwan_spoke1_fw.name
    }
  }
}
