module "app01_srv1" {
  source = "../modules/linux"

  name                = "${var.name}-app01-srv1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.app01_s01.id
  private_ip_address  = cidrhost(azurerm_subnet.app01_s01.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  associate_nsg       = true
  security_group      = azurerm_network_security_group.mgmt.id
}

module "app02_srv1" {
  source = "../modules/linux"

  name                = "${var.name}-app02-srv1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.app02_s01.id
  private_ip_address  = cidrhost(azurerm_subnet.app02_s01.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
  associate_nsg       = true
  security_group      = azurerm_network_security_group.mgmt.id
}

