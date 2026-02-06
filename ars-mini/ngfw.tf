module "ngfw" {
  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name  = "${var.name}-ngfw"

  username = var.username
  password = var.password
  ssh_key  = azurerm_ssh_public_key.rg.public_key

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.vnet_transit.subnets["mgmt"].id
    }
    private = {
      device_index       = 1
      public_ip          = false
      subnet_id          = module.vnet_transit.subnets["data"].id
      private_ip_address = local.private_ips.ngfw
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.panorama_managed ? {
        tplname = module.cfg_panorama[0].panos_panorama_template_stack_name
    } : {},
    var.scm_managed ? var.bootstrap_options["scm"] : {}
  )
}

resource "azurerm_route_server_bgp_connection" "ngfw" {
  name            = "ngfw"
  route_server_id = azurerm_route_server.transit.id
  peer_asn        = var.asn["ngfw"]
  peer_ip         = local.private_ips.ngfw
}
