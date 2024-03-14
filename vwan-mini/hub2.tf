module "vnet_hub2_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.dname}-hub2-spoke1"
  address_space = [local.vnet_cidr.hub2_spoke1]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }
}

module "linux_hub2_spoke1" {
  source = "../modules/linux"

  name                = "${var.name}-hub2-spoke1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_hub2_spoke1.subnets.s0.id
  private_ip_address  = cidrhost(module.vnet_hub2_spoke1.subnets.s0.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
}
