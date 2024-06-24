module "hub3_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name          = "${local.dname}-hub3-spoke1"
  address_space = [local.vnet_cidr.hub3_spoke1]
  bgp_community = "12076:20041"

  subnets = {
    "s1" = {
      idx                       = 0
      network_security_group_id = module.basic_rg2.sg_id.mgmt
      associate_nsg             = true
    },
    "s2" = {
      idx                       = 1
      network_security_group_id = module.basic_rg2.sg_id.mgmt
      associate_nsg             = true
    },
  }
}
