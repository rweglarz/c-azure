locals {
  subnet_prefix_length = 27
  vnet_address_space = {
    left_hub          = [cidrsubnet(var.cidr, 4, 0)]
    left_srv1         = [cidrsubnet(var.cidr, 4, 1)]
    left_srv2         = [cidrsubnet(var.cidr, 4, 2)]
    right_hub         = [cidrsubnet(var.cidr, 4, 8)]
    right_srv1        = [cidrsubnet(var.cidr, 4, 9)]
    right_core        = [cidrsubnet(var.cidr, 4, 10)]
    right_core_spoke1 = [cidrsubnet(var.cidr, 4, 11)]
  }
  private_ips = {
    left_hub_fw = {
      mgmt_ip   = cidrhost(module.vnet_left_hub.subnets["mgmt"].address_prefixes[0], 5),
      eth1_1_ip = cidrhost(module.vnet_left_hub.subnets["data"].address_prefixes[0], 5),
      eth1_1_gw = cidrhost(module.vnet_left_hub.subnets["data"].address_prefixes[0], 1),
    }
    left_ipsec_fw1 = {
      mgmt_ip   = cidrhost(module.vnet_left_hub.subnets["mgmt"].address_prefixes[0], 6),
      eth1_1_ip = cidrhost(module.vnet_left_hub.subnets["internet"].address_prefixes[0], 6),
      eth1_1_gw = cidrhost(module.vnet_left_hub.subnets["internet"].address_prefixes[0], 1),
      eth1_2_ip = cidrhost(module.vnet_left_hub.subnets["private"].address_prefixes[0], 6),
      eth1_2_gw = cidrhost(module.vnet_left_hub.subnets["private"].address_prefixes[0], 1),
      tun11_ip  = "169.254.21.1"
    }
    left_ipsec_fw2 = {
      mgmt_ip   = cidrhost(module.vnet_left_hub.subnets["mgmt"].address_prefixes[0], 7),
      eth1_1_ip = cidrhost(module.vnet_left_hub.subnets["internet"].address_prefixes[0], 7),
      eth1_1_gw = cidrhost(module.vnet_left_hub.subnets["internet"].address_prefixes[0], 1),
      eth1_2_ip = cidrhost(module.vnet_left_hub.subnets["private"].address_prefixes[0], 7),
      eth1_2_gw = cidrhost(module.vnet_left_hub.subnets["private"].address_prefixes[0], 1),
      tun11_ip  = "169.254.21.3"
    }
    right_hub_fw = {
      mgmt_ip   = cidrhost(module.vnet_right_hub.subnets["mgmt"].address_prefixes[0], 5),
      eth1_1_ip = cidrhost(module.vnet_right_hub.subnets["data"].address_prefixes[0], 5),
      eth1_1_gw = cidrhost(module.vnet_right_hub.subnets["data"].address_prefixes[0], 1),
    }
  }
  public_ips = {
    left_ipsec_fw1 = [
      one([for k, v in module.left_ipsec_fw1.public_ips : v if length(regexall("internet", k)) > 0]),
    ],
    left_ipsec_fw2 = [
      one([for k, v in module.left_ipsec_fw2.public_ips : v if length(regexall("internet", k)) > 0]),
    ],
    right_vng = [
      azurerm_virtual_network_gateway.right.bgp_settings[0].peering_addresses[0].tunnel_ip_addresses[0],
      azurerm_virtual_network_gateway.right.bgp_settings[0].peering_addresses[1].tunnel_ip_addresses[0],
    ]
  }
}
