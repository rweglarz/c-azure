locals {
  dns_ttl = 150
  bootstrap_options_built = merge(
    var.panorama1_ip != "" ? { panorama-server = var.panorama1_ip } : {},
    var.panorama2_ip != "" ? { panorama-server-2 = var.panorama2_ip } : {},
  )
  bootstrap_options_bnd = merge(
    local.bootstrap_options_built,
    { dgname = panos_device_group.bnd.name },
    var.bootstrap_options["common"],
    var.bootstrap_options["bnd"],
  )
  bootstrap_options_byol = merge(
    local.bootstrap_options_built,
    { dgname = panos_device_group.byol.name },
    var.bootstrap_options["common"],
    var.bootstrap_options["byol"],
  )
}
