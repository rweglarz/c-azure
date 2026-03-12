module "servers" {
  source = "../modules/linux"

  for_each = {
    app1 = {
      subnet = module.vnet_app1.subnets.app
      ip_idx = 5
    }
    app2 = {
      subnet = module.vnet_app2.subnets.app
      ip_idx = 5
    }
    dmz = {
      subnet = module.vnet_dmz.subnets.app
      ip_idx = 5
    }
  }

  name                = "${var.name}-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = each.value.subnet.id
  private_ip_address  = cidrhost(each.value.subnet.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  # security_group      = module.basic.sg_id["mgmt"]
  associate_nsg       = false
}
