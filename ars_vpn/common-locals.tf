locals {
  subnet_prefix_length = 28
  vnet_address_space = {
    left_hub  = [cidrsubnet(var.cidr, 4, 0)]
    right_hub = [cidrsubnet("10.0.0.0/8", 16, 0)]
  }
  private_ips = {
    left_hub_fw = {
      mgmt_ip   = cidrhost(module.vnet_left_hub.subnets["mgmt"].address_prefixes[0], 5),
      eth1_1_ip = cidrhost(module.vnet_left_hub.subnets["data"].address_prefixes[0], 5),
      eth1_1_gw = cidrhost(module.vnet_left_hub.subnets["data"].address_prefixes[0], 1),
    }
    right_hub_fw = {
      mgmt_ip   = cidrhost(module.vnet_right_hub.subnets["mgmt"].address_prefixes[0], 5),
      eth1_1_ip = cidrhost(module.vnet_right_hub.subnets["data"].address_prefixes[0], 5),
      eth1_1_gw = cidrhost(module.vnet_right_hub.subnets["data"].address_prefixes[0], 1),
    }
  }

}
