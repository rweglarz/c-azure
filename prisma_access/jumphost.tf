module "jumphost" {
  source = "../modules/linux"

  name                = "${var.name}-jumphost"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_sec.subnets["jump"].id
  private_ip_address  = cidrhost(module.vnet_sec.subnets["jump"].address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
}
