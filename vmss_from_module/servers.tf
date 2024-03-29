module "srv_app11" {
  source = "../modules/linux"

  name                = "${var.name}-srv-app11"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_app1.subnets["app"].id
  private_ip_address  = cidrhost(module.vnet_app1.subnets["app"].address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id["mgmt"]
  associate_nsg       = true
}

module "srv_app12" {
  source = "../modules/linux"

  name                = "${var.name}-srv-app12"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_app1.subnets["app"].id
  private_ip_address  = cidrhost(module.vnet_app1.subnets["app"].address_prefixes[0], 6)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id["mgmt"]
  associate_nsg       = true
}

module "srv_db1" {
  source = "../modules/linux"

  name                = "${var.name}-srv-db1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_app1.subnets["db"].id
  private_ip_address  = cidrhost(module.vnet_app1.subnets["db"].address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id["mgmt"]
  associate_nsg       = true
}

module "srv_app2" {
  source = "../modules/linux"

  name                = "${var.name}-srv-app2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_app2.subnets["app"].id
  private_ip_address  = cidrhost(module.vnet_app2.subnets["app"].address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id["mgmt"]
  associate_nsg       = true
}
