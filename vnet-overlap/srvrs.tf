module "sec_1" {
  source = "../modules/linux"

  name                = "${var.name}-sec-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_sec.subnets.private.id
  private_ip_address  = cidrhost(one(module.vnet_sec.subnets.private.address_prefixes), 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  associate_nsg       = true
  security_group      = module.basic.sg_id.mgmt
  enable_ip_forwarding = true
}

module "net1_app" {
  source = "../modules/linux"

  name                = "${var.name}-net1-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.net1-o1.id
  private_ip_address  = cidrhost(one(azurerm_subnet.net1-o1.address_prefixes), 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  associate_nsg       = true
  security_group      = module.basic.sg_id.wide-open
  associate_public_ip = false
}

module "net1_unique" {
  source = "../modules/linux"

  name                = "${var.name}-net1-unique"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.net1-u1.id
  private_ip_address  = cidrhost(one(azurerm_subnet.net1-u1.address_prefixes), 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  associate_nsg       = true
  security_group      = module.basic.sg_id.mgmt
  enable_ip_forwarding = true
  associate_public_ip = false
}

module "net2_app" {
  source = "../modules/linux"

  name                = "${var.name}-net2-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.net2-o1.id
  private_ip_address  = cidrhost(one(azurerm_subnet.net2-o1.address_prefixes), 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  associate_nsg       = true
  security_group      = module.basic.sg_id.wide-open
  associate_public_ip = false
}

module "net2_unique" {
  source = "../modules/linux"

  name                = "${var.name}-net2-unique"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.net2-u1.id
  private_ip_address  = cidrhost(one(azurerm_subnet.net2-u1.address_prefixes), 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  associate_nsg       = true
  security_group      = module.basic.sg_id.mgmt
  enable_ip_forwarding = true
  associate_public_ip = false
}
