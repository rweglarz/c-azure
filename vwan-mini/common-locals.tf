locals {
  dns_ttl              = 90
  subnet_prefix_length = 28
  vnet_cidr = {
    hub1            = cidrsubnet(var.region_cidr, 4, 0)
    hub1_sec        = cidrsubnet(var.region_cidr, 4, 1)
    hub1_spoke1     = cidrsubnet(var.region_cidr, 5, 2*2 + 0)
    hub1_spoke2     = cidrsubnet(var.region_cidr, 5, 2*2 + 1)
    hub1_sdwan      = cidrsubnet(var.region_cidr, 4, 3)
    hub2            = cidrsubnet(var.region_cidr, 4, 4)
    hub2_spoke1     = cidrsubnet(var.region_cidr, 5, 5*2 + 0)
    hub2_spoke2     = cidrsubnet(var.region_cidr, 5, 5*2 + 1)
  }


  public_ip = {
    hub1 = [
      azurerm_vpn_gateway.hub1.ip_configuration[0].public_ip_address,
      azurerm_vpn_gateway.hub1.ip_configuration[1].public_ip_address,
    ]
  }
  private_ip = {
    onprem      = cidrhost(module.vnet_onprem.subnets.public.address_prefixes[0], 5)
    hub1_sec_lb = cidrhost(module.vnet_hub1_sec.subnets.private.address_prefixes[0], 5)
    hub1_sdwan1 = cidrhost(module.vnet_hub1_sdwan.subnets.s0.address_prefixes[0], 5)
    hub1_sdwan2 = cidrhost(module.vnet_hub1_sdwan.subnets.s0.address_prefixes[0], 6)
  }
  peering_address = {
    hub1_vng = [
      tolist(azurerm_vpn_gateway.hub1.bgp_settings[0].instance_0_bgp_peering_address[0].default_ips)[0],
      tolist(azurerm_vpn_gateway.hub1.bgp_settings[0].instance_1_bgp_peering_address[0].default_ips)[0],
    ]
    hub1 = [
      azurerm_virtual_hub.hub1.virtual_router_ips[0],
      azurerm_virtual_hub.hub1.virtual_router_ips[1],
    ]
  }

  linux_init_p = {
    onprem = {
      local_ip  = local.private_ip.onprem
      local_asn = var.asn.onprem
      router_id = local.private_ip.onprem
      local_id  = module.linux_onprem.public_ip
      vpn_psk   = var.psk
      peers = {
        vngi0 = {
          peer_ip  = local.peering_address.hub1_vng[0]
          peer_asn = 65515
        }
        vngi1 = {
          peer_ip  = local.peering_address.hub1_vng[1]
          peer_asn = 65515
        }
      }
      tunnels = {
        vngi0 = {
          peer_ip = local.public_ip.hub1[0]
          if_id   = 101
        }
        vngi1 = {
          peer_ip = local.public_ip.hub1[1]
          if_id   = 102
        }
      }
      lo_ips = [
        "10.1.0.1/25",
        "10.0.0.1/8",
      ]
    }
    sdwan1 = {
      local_ip  = local.private_ip.hub1_sdwan1
      local_asn = var.asn.hub1_sdwan1
      peer1_ip  = local.peering_address.hub1[0]
      peer2_ip  = local.peering_address.hub1[1]
      peer1_asn = var.asn.hub1
      peer2_asn = var.asn.hub1
      lo_ips = [
        "10.1.1.1/25",
        "10.1.11.1/25",
        "10.1.21.1/25",
      ]
    }
    sdwan2 = {
      local_ip  = local.private_ip.hub1_sdwan2
      local_asn = var.asn.hub1_sdwan2
      peer1_ip  = local.peering_address.hub1[0]
      peer2_ip  = local.peering_address.hub1[1]
      peer1_asn = var.asn.hub1
      peer2_asn = var.asn.hub1
      lo_ips = [
        "10.1.2.1/25",
        "10.1.12.1/25",
        "10.1.22.1/25",
      ]
    }
  }
}
