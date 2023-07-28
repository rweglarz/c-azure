module "hub4_spoke1_h" {
  source = "../modules/linux"

  name                = "${local.dname}-hub4-spoke1"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  subnet_id           = module.hub4_spoke1.subnets.s1.id
  private_ip_address  = cidrhost(module.hub4_spoke1.subnets.s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg2.public_key
  security_group      = azurerm_network_security_group.rg2_mgmt.id
  associate_nsg       = true
}

module "hub4_spoke2_h" {
  source = "../modules/linux"

  name                = "${local.dname}-hub4-spoke2"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  subnet_id           = module.hub4_spoke2.subnets.s1.id
  private_ip_address  = cidrhost(module.hub4_spoke2.subnets.s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg2.public_key
  security_group      = azurerm_network_security_group.rg2_mgmt.id
  associate_nsg       = true
}

module "sdwan_spoke1_h" {
  source = "../modules/linux"

  name                = "${local.dname}-sdwan-spoke1"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  subnet_id           = module.sdwan_spoke1.subnets.s1.id
  private_ip_address  = cidrhost(module.sdwan_spoke1.subnets.s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg2.public_key
  security_group      = azurerm_network_security_group.rg2_mgmt.id
  associate_nsg       = true
}
