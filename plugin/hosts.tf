module "h1" {
  source = "../modules/linux"

  name                = "${var.name}-h1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.w1_s1.id
  private_ip_address  = cidrhost(azurerm_subnet.w1_s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  associate_nsg       = true
  security_group      = azurerm_network_security_group.hosts.id
}

module "h2" {
  source = "../modules/linux"

  name                = "${var.name}-h2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.w2_s1.id
  private_ip_address  = cidrhost(azurerm_subnet.w2_s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  associate_nsg       = true
  security_group      = azurerm_network_security_group.hosts.id
}
