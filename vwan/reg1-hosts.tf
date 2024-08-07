module "hub1_sec_spoke1_h" {
  source = "../modules/linux"

  name                = "${local.dname}-hub1-sec-spoke1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  subnet_id           = module.hub1_sec_spoke1.subnets.s1.id
  private_ip_address  = cidrhost(module.hub1_sec_spoke1.subnets.s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg1.public_key
  security_group      = module.basic_rg1.sg_id.mgmt
  associate_nsg       = true
  tags = {
    rwe-region = "region1"
  }
}

module "hub2_spoke1_s1_h" {
  source = "../modules/linux"

  name                = "${local.dname}-hub2-spoke1-s1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  subnet_id           = module.hub2_spoke1.subnets.s1.id
  private_ip_address  = cidrhost(module.hub2_spoke1.subnets.s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg1.public_key
  security_group      = module.basic_rg1.sg_id.mgmt
  associate_nsg       = true
  tags = {
    rwe-region = "region1"
    rwe-github = "yes"
  }
}

module "hub2_spoke1_s2_h" {
  source = "../modules/linux"

  name                = "${local.dname}-hub2-spoke1-s2"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  subnet_id           = module.hub2_spoke1.subnets.s2.id
  private_ip_address  = cidrhost(module.hub2_spoke1.subnets.s2.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg1.public_key
  security_group      = module.basic_rg1.sg_id.mgmt
  associate_nsg       = true
  tags = {
    rwe-region = "region1"
  }
}

module "hub2_spoke2_h" {
  source = "../modules/linux"

  name                = "${local.dname}-hub2-spoke2"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  subnet_id           = module.hub2_spoke2.subnets.s1.id
  private_ip_address  = cidrhost(module.hub2_spoke2.subnets.s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg1.public_key
  security_group      = module.basic_rg1.sg_id.mgmt
  associate_nsg       = true
  tags = {
    rwe-region = "region1"
  }
}

module "sdwan_spoke1_h" {
  source = "../modules/linux"

  name                = "${local.dname}-sdwan-spoke1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  subnet_id           = module.sdwan_spoke1.subnets.s1.id
  private_ip_address  = cidrhost(module.sdwan_spoke1.subnets.s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg1.public_key
  security_group      = module.basic_rg1.sg_id.mgmt
  associate_nsg       = true
  tags = {
    rwe-region = "region1"
  }
}
