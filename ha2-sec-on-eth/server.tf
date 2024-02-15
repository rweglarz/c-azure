module "peered-srv0" {
  source = "../modules/linux"

  name                = "${var.name}-peered-srv0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_srv0.subnets.s1.id
  private_ip_address  = cidrhost(module.vnet_srv0.subnets.s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
}

module "peered-srv1" {
  source = "../modules/linux"

  name                = "${var.name}-peered-srv1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_srv1.subnets.s1.id
  private_ip_address  = cidrhost(module.vnet_srv1.subnets.s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
}

module "sec-srv5" {
  source = "../modules/linux"

  name                = "${var.name}-sec-srv5"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_sec.subnets.srv5.id
  private_ip_address  = cidrhost(module.vnet_sec.subnets.srv5.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
}

module "sec-srv6" {
  source = "../modules/linux"

  name                = "${var.name}-sec-srv6"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_sec.subnets.srv6.id
  private_ip_address  = cidrhost(module.vnet_sec.subnets.srv6.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
}
