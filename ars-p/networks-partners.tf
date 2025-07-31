module "vnet_partner1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${var.name}-partner1"
  address_space = [cidrsubnet(var.cidr_partners, 8, 1)]

  subnets = {
    workloads = {
      idx                       = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
  }
}

module "vnet_partner2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${var.name}-partner2"
  address_space = [cidrsubnet(var.cidr_partners, 8, 2)]

  subnets = {
    workloads = {
      idx                       = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
  }
}
