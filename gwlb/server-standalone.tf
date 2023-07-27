module "srv_sa" {
  source = "../modules/linux"

  name                = "${var.name}-srv-sa"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_sa.subnets["s1"].id
  private_ip_address  = cidrhost(module.vnet_sa.subnets["s1"].address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id["mgmt"]
  associate_nsg       = true
  gwlb_fe_id          = azurerm_lb.fw_gwlb.frontend_ip_configuration[0].id
}

