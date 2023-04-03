locals {
  vnet_address_space = {
    sec      = [cidrsubnet(var.vnet_cidr, 1, 0)]
    panorama = [cidrsubnet(var.vnet_cidr, 1, 1)]
  }
  private_ips = {
    fw = {
      eth1_1_gw = cidrhost(module.vnet_sec.subnets["internet"].address_prefixes[0], 1),
      eth1_2_gw = cidrhost(module.vnet_sec.subnets["internal"].address_prefixes[0], 1),
    }
  }

}
