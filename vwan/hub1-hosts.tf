module "hub1_sec_spoke1_h" {
  source = "../modules/linux"

  name                = "${local.dname}-hub1-sec-spoke1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  subnet_id           = azurerm_subnet.hub1_sec_spoke1_s1.id
  private_ip_address  = cidrhost(azurerm_subnet.hub1_sec_spoke1_s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg1.public_key
  security_group      = azurerm_network_security_group.rg1_mgmt.id
  associate_nsg       = true
}

module "hub1_spoke1_h" {
  source = "../modules/linux"

  name                = "${local.dname}-hub1-spoke1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  subnet_id           = azurerm_subnet.hub1_spoke1_s1.id
  private_ip_address  = cidrhost(azurerm_subnet.hub1_spoke1_s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg1.public_key
  security_group      = azurerm_network_security_group.rg1_mgmt.id
  associate_nsg       = true
}

module "hub1_spoke2_h" {
  source = "../modules/linux"

  name                = "${local.dname}-hub1-spoke2"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  subnet_id           = azurerm_subnet.hub1_spoke2_s1.id
  private_ip_address  = cidrhost(azurerm_subnet.hub1_spoke2_s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg1.public_key
  security_group      = azurerm_network_security_group.rg1_mgmt.id
  associate_nsg       = true
}

