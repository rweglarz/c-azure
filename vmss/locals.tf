locals {
  bootstrap_options_bnd = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["bnd"],
  )
  bootstrap_options_byol = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["byol"],
  )
  cidr = {
    sec  = cidrsubnet(var.cidr, 5,  0)
    app1 = cidrsubnet(var.cidr, 5,  1)
    app2 = cidrsubnet(var.cidr, 5,  2)
    dmz  = cidrsubnet(var.cidr, 5, 31)
  }
}
