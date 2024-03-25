module "hub4_spoke1_s1_h" {
  source = "../modules/linux"

  name                = "${local.dname}-hub4-spoke1-s1"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  subnet_id           = module.hub4_spoke1.subnets.s1.id
  private_ip_address  = cidrhost(module.hub4_spoke1.subnets.s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg2.public_key
  security_group      = azurerm_network_security_group.rg2_mgmt.id
  associate_nsg       = true
  tags = {
    rwe-region = "region2"
  }
}

module "hub4_spoke1_s2_h" {
  source = "../modules/linux"

  name                = "${local.dname}-hub4-spoke1-s2"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  subnet_id           = module.hub4_spoke1.subnets.s2.id
  private_ip_address  = cidrhost(module.hub4_spoke1.subnets.s2.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg2.public_key
  security_group      = azurerm_network_security_group.rg2_mgmt.id
  associate_nsg       = true
  tags = {
    rwe-region = "region2"
  }
}

module "hub4_spoke2_h_prv" {
  source = "../modules/linux"

  name                = "${local.dname}-hub4-spoke2-prv"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  subnet_id           = module.hub4_spoke2.subnets.s1.id
  private_ip_address  = cidrhost(module.hub4_spoke2.subnets.s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg2.public_key
  security_group      = azurerm_network_security_group.rg2_mgmt.id
  associate_nsg       = true
  tags = {
    rwe-region = "region2"
  }
}

module "hub4_spoke2_h_pub" {
  source = "../modules/linux"

  name                = "${local.dname}-hub4-spoke2-pub"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  subnet_id           = module.hub4_spoke2.subnets.ext.id
  private_ip_address  = cidrhost(module.hub4_spoke2.subnets.ext.address_prefixes[0], 6)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg2.public_key
  security_group      = azurerm_network_security_group.rg2_mgmt.id
  associate_nsg       = true
  associate_public_ip = false
  tags = {
    rwe-region = "region2"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "hub4_spoke2_pub" {
  network_interface_id    = module.hub4_spoke2_h_pub.network_interface_id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.hub4_ext.id
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
  tags = {
    rwe-region = "region2"
  }
}
