locals {
  dns_ttl              = 90
  subnet_prefix_length = 28
  vnet_cidr = {
    transit         = cidrsubnet(var.region_cidr, 4, 0)
    sdwan           = cidrsubnet(var.region_cidr, 4, 1)
    spoke1          = cidrsubnet(var.region_cidr, 4, 4)
    spoke2          = cidrsubnet(var.region_cidr, 4, 5)
  }


  public_ip = {
  }
  private_ip = {
    fw_ilb = cidrhost(module.vnet_transit.subnets.private.address_prefixes[0], 5)
  }

}
