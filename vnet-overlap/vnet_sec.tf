module "vnet_sec" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.dname}-sec"
  address_space = [var.sec_vnet_cidr]

  subnets = {
    "mgmt" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
    "public" = {
      idx                       = 1
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
    },
    "private" = {
      idx                       = 2
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
    },
  }
}
