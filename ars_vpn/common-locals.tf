locals {
  subnet_prefix_length = 27
  vnet_address_space = {
    left_u_hub     = [cidrsubnet(var.cidr, 4, 0)]
    left_u_srv1    = [cidrsubnet(var.cidr, 4, 1)]
    left_u_srv2    = [cidrsubnet(var.cidr, 4, 2)]
    left_b_hub     = [cidrsubnet(var.cidr, 4, 4)]
    left_b_srv1    = [cidrsubnet(var.cidr, 4, 5)]
    left_b_srv2    = [cidrsubnet(var.cidr, 4, 6)]
    right_hub      = [cidrsubnet(var.cidr, 4, 8)]
    right_srv1     = [cidrsubnet(var.cidr, 4, 9)]
    right_env_fw   = [cidrsubnet(var.cidr, 4, 12)]
    right_env_sdgw = [cidrsubnet(var.cidr, 4, 13)]
  }
  private_ips = {
    left_u_hub_ilb = {
      obew   = cidrhost(module.vnet_left_u_hub.subnets["data"].address_prefixes[0], 4),
    }
    left_u_hub_fw = {
      mgmt_ip   = cidrhost(module.vnet_left_u_hub.subnets["mgmt"].address_prefixes[0], 5),
      eth1_1_ip = cidrhost(module.vnet_left_u_hub.subnets["data"].address_prefixes[0], 5),
      eth1_1_gw = cidrhost(module.vnet_left_u_hub.subnets["data"].address_prefixes[0], 1),
    }
    left_u_ipsec_fw1 = {
      mgmt_ip   = cidrhost(module.vnet_left_u_hub.subnets["mgmt"].address_prefixes[0], 6),
      eth1_1_ip = cidrhost(module.vnet_left_u_hub.subnets["internet"].address_prefixes[0], 6),
      eth1_1_gw = cidrhost(module.vnet_left_u_hub.subnets["internet"].address_prefixes[0], 1),
      eth1_2_ip = cidrhost(module.vnet_left_u_hub.subnets["private"].address_prefixes[0], 6),
      eth1_2_gw = cidrhost(module.vnet_left_u_hub.subnets["private"].address_prefixes[0], 1),
      tun11_ip  = "169.254.21.1"
    }
    left_u_ipsec_fw2 = {
      mgmt_ip   = cidrhost(module.vnet_left_u_hub.subnets["mgmt"].address_prefixes[0], 7),
      eth1_1_ip = cidrhost(module.vnet_left_u_hub.subnets["internet"].address_prefixes[0], 7),
      eth1_1_gw = cidrhost(module.vnet_left_u_hub.subnets["internet"].address_prefixes[0], 1),
      eth1_2_ip = cidrhost(module.vnet_left_u_hub.subnets["private"].address_prefixes[0], 7),
      eth1_2_gw = cidrhost(module.vnet_left_u_hub.subnets["private"].address_prefixes[0], 1),
      tun11_ip  = "169.254.21.3"
    }
    right_hub_fw = {
      mgmt_ip   = cidrhost(module.vnet_right_hub.subnets["mgmt"].address_prefixes[0], 5),
      eth1_1_ip = cidrhost(module.vnet_right_hub.subnets["data"].address_prefixes[0], 5),
      eth1_1_gw = cidrhost(module.vnet_right_hub.subnets["data"].address_prefixes[0], 1),
    }
    right_env_fw1 = {
      mgmt_ip   = cidrhost(module.vnet_right_env_fw.subnets["mgmt"].address_prefixes[0], 5),
      eth1_1_ip = cidrhost(module.vnet_right_env_fw.subnets["core"].address_prefixes[0], 5),
      eth1_1_gw = cidrhost(module.vnet_right_env_fw.subnets["core"].address_prefixes[0], 1),
      eth1_2_ip = cidrhost(module.vnet_right_env_fw.subnets["env1"].address_prefixes[0], 5),
      eth1_2_gw = cidrhost(module.vnet_right_env_fw.subnets["env1"].address_prefixes[0], 1),
      eth1_3_ip = cidrhost(module.vnet_right_env_fw.subnets["env2"].address_prefixes[0], 5),
      eth1_3_gw = cidrhost(module.vnet_right_env_fw.subnets["env2"].address_prefixes[0], 1),
    }
    right_env_fw2 = {
      mgmt_ip   = cidrhost(module.vnet_right_env_fw.subnets["mgmt"].address_prefixes[0], 6),
      eth1_1_ip = cidrhost(module.vnet_right_env_fw.subnets["core"].address_prefixes[0], 6),
      eth1_1_gw = cidrhost(module.vnet_right_env_fw.subnets["core"].address_prefixes[0], 1),
      eth1_2_ip = cidrhost(module.vnet_right_env_fw.subnets["env1"].address_prefixes[0], 6),
      eth1_2_gw = cidrhost(module.vnet_right_env_fw.subnets["env1"].address_prefixes[0], 1),
      eth1_3_ip = cidrhost(module.vnet_right_env_fw.subnets["env2"].address_prefixes[0], 6),
      eth1_3_gw = cidrhost(module.vnet_right_env_fw.subnets["env2"].address_prefixes[0], 1),
    }
    right_env_r_test = {
      eth0 = cidrhost(module.vnet_right_env_fw.subnets["core"].address_prefixes[0], 9)
    }
    right_env1_sdgw1 = {
      eth0 = cidrhost(module.vnet_right_env_sdgw.subnets["env1"].address_prefixes[0], 5)
    }
    right_env1_sdgw2 = {
      eth0 = cidrhost(module.vnet_right_env_sdgw.subnets["env1"].address_prefixes[0], 6)
    }
  }
  public_ips = {
    left_u_ipsec_fw1 = [
      one([for k, v in module.left_u_ipsec_fw1.public_ips : v if length(regexall("internet", k)) > 0]),
    ],
    left_u_ipsec_fw2 = [
      one([for k, v in module.left_u_ipsec_fw2.public_ips : v if length(regexall("internet", k)) > 0]),
    ],
    right_vng = [
      azurerm_virtual_network_gateway.right.bgp_settings[0].peering_addresses[0].tunnel_ip_addresses[0],
      azurerm_virtual_network_gateway.right.bgp_settings[0].peering_addresses[1].tunnel_ip_addresses[0],
    ]
  }
}
