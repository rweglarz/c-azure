locals {
  subnet_prefix_length = 27
  vnet_address_space = {
    sec  = [cidrsubnet(var.cidr, 1, 0)]
    app1 = [cidrsubnet(var.cidr, 2, 2)]
    app2 = [cidrsubnet(var.cidr, 2, 3)]
  }
}
