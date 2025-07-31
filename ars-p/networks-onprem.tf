module "vnet_onprem" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${var.name}-on-prem"
  address_space = [var.cidr_onprem]

  subnets = {
    mgmt = {
      idx                       = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
    isp1 = {
      idx                       = 1
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.vpn
    },
    isp2 = {
      idx                       = 2
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.vpn
    },
    private = {
      idx                       = 3
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
    workloads = {
      idx                       = 4
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
  }
}

