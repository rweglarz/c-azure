locals {
  subnet_prefix_length = 27
  vnet_address_space = {
    left_hub   = [cidrsubnet(var.cidr, 4, 0)]
    left_srv1  = [cidrsubnet(var.cidr, 4, 1)]
    left_srv2  = [cidrsubnet(var.cidr, 4, 2)]
    right_hub  = [cidrsubnet(var.cidr, 4, 8)]
    right_srv1 = [cidrsubnet(var.cidr, 4, 9)]
    right_core = [cidrsubnet(var.cidr, 4, 10)]
    right_core_spoke1 = [cidrsubnet(var.cidr, 4, 11)]
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
