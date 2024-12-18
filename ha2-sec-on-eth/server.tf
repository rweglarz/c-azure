module "vm_peered_srv5" {
  source = "../modules/linux"

  name                = "${local.name}-peered-srv5"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_srv5.subnets.s0.id
  private_ip_address  = cidrhost(module.vnet_srv5.subnets.s0.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
}

module "vm_peered_srv6" {
  source = "../modules/linux"

  name                = "${local.name}-peered-srv6"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_srv6.subnets.s0.id
  private_ip_address  = cidrhost(module.vnet_srv6.subnets.s0.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
}

module "vm_sec_srv0" {
  source = "../modules/linux"

  name                = "${local.name}-sec-srv0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_sec.subnets.srv0.id
  private_ip_address  = cidrhost(module.vnet_sec.subnets.srv0.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
}

module "vm_sec_srv1" {
  source = "../modules/linux"

  name                = "${local.name}-sec-srv1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_sec.subnets.srv1.id
  private_ip_address  = cidrhost(module.vnet_sec.subnets.srv1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rwe.public_key
}

output "servers" {
  value = {
    srv0 = module.vm_sec_srv0.private_ip_address
    srv1 = module.vm_sec_srv1.private_ip_address
    srv5 = module.vm_peered_srv5.private_ip_address
    srv6 = module.vm_peered_srv6.private_ip_address
  }
}