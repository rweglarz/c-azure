module "hub4_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name          = "${local.dname}-hub4-spoke1"
  address_space = [local.vnet_cidr.hub4_spoke1]

  subnets = {
    "s1" = {
      idx                       = 0
      network_security_group_id = azurerm_network_security_group.rg2_mgmt.id
      associate_nsg             = true
    },
  }
}

module "hub4_spoke2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name          = "${local.dname}-hub4-spoke2"
  address_space = [local.vnet_cidr.hub4_spoke2]

  subnets = {
    "s1" = {
      idx                       = 0
      network_security_group_id = azurerm_network_security_group.rg2_mgmt.id
      associate_nsg             = true
    },
  }
}
