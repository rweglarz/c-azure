module "srv_app1_frontend1" {
  source = "../modules/linux"

  name                = "${var.name}-srv-app1-frontend1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_app1.subnets["frontend"].id
  private_ip_address  = cidrhost(module.vnet_app1.subnets["frontend"].address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id["wide-open"]
  associate_nsg       = true
  associate_public_ip = false
}

resource "azurerm_network_interface_backend_address_pool_association" "srv_app1_frontend1" {
  network_interface_id    = module.srv_app1_frontend1.network_interface_id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.srv.id
}

module "srv_app1_backend1" {
  source = "../modules/linux"

  name                = "${var.name}-srv-app1-backend1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_app1.subnets["backend"].id
  private_ip_address  = cidrhost(module.vnet_app1.subnets["backend"].address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id["wide-open"]
  associate_nsg       = true
  associate_public_ip = false
}

