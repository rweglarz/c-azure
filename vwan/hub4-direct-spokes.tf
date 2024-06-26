module "hub4_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name          = "${local.dname}-hub4-spoke1"
  address_space = [local.vnet_cidr.hub4_spoke1]
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

module "hub4_spoke2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name          = "${local.dname}-hub4-spoke2"
  address_space = [local.vnet_cidr.hub4_spoke2]
  bgp_community = "12076:20042"

  subnets = {
    "s1" = {
      idx                       = 0
      network_security_group_id = module.basic_rg2.sg_id.mgmt
      associate_nsg             = true
    },
    "ext" = {
      idx                       = 1
      network_security_group_id = module.basic_rg2.sg_id.mgmt
      associate_nsg             = true
    },
  }
}

resource "azurerm_subnet_route_table_association" "hub4_spoke1_s1" {
  subnet_id      = module.hub4_spoke1.subnets["s1"].id
  route_table_id = module.basic_rg2.route_table_id["only-mgmt-via-igw"].igw
}

resource "azurerm_subnet_route_table_association" "hub4_spoke1_s2" {
  subnet_id      = module.hub4_spoke1.subnets["s2"].id
  route_table_id = module.basic_rg2.route_table_id["only-mgmt-via-igw"].igw
}

resource "azurerm_subnet_route_table_association" "hub4_spoke2_s1" {
  subnet_id      = module.hub4_spoke2.subnets["s1"].id
  route_table_id = module.basic_rg2.route_table_id["only-mgmt-via-igw"].igw
}

resource "azurerm_subnet_route_table_association" "hub4_spoke2_ext" {
  subnet_id      = module.hub4_spoke2.subnets["ext"].id
  route_table_id = module.basic_rg2.route_table_id["all-via-igw"].igw
}
