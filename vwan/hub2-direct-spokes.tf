module "hub2_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-hub2-spoke1"
  address_space = [local.vnet_cidr.hub2_spoke1]

  subnets = {
    "s1" = {
      idx                       = 0
      network_security_group_id = azurerm_network_security_group.rg1_mgmt.id
      associate_nsg             = true
    },
    "s2" = {
      idx                       = 1
      network_security_group_id = azurerm_network_security_group.rg1_mgmt.id
      associate_nsg             = true
    },
  }
}

module "hub2_spoke2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-hub2-spoke2"
  address_space = [local.vnet_cidr.hub2_spoke2]

  subnets = {
    "s1" = {
      idx                       = 0
      network_security_group_id = azurerm_network_security_group.rg1_mgmt.id
      associate_nsg             = true
    },
  }
}
