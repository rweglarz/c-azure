module "app01_prod_srv" {
  source = "../modules/linux"

  count = var.server_count

  name                = "${var.name}-app01-prod-srv${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.app01_s01.id
  private_ip_address  = cidrhost(one(azurerm_subnet.app01_s01.address_prefixes), 7+count.index)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  associate_nsg       = true
  security_group      = azurerm_network_security_group.mgmt.id
  size                = var.server_size
  tags = {
    env = "prod"
  }
}

module "app01_dev_srv" {
  source = "../modules/linux"

  count = var.server_count

  name                = "${var.name}-app01-dev-srv${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.app01_s01.id
  private_ip_address  = cidrhost(one(azurerm_subnet.app01_s01.address_prefixes), 12+count.index)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  associate_nsg       = true
  security_group      = azurerm_network_security_group.mgmt.id
  size                = var.server_size
  tags = {
    env = "dev"
  }
}

module "app02_srv" {
  source = "../modules/linux"

  count = var.server_count

  name                = "${var.name}-app02-srv${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.app02_s01.id
  private_ip_address  = cidrhost(one(azurerm_subnet.app02_s01.address_prefixes), 5+count.index)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  associate_nsg       = true
  security_group      = azurerm_network_security_group.mgmt.id
  size                = var.server_size
  tags = {
    env = "prod"
  }
}
