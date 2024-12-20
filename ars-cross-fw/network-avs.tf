module "vnet_avs" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.name}-avs"
  address_space = [cidrsubnet(var.cidr, 2, 2)]

  subnets = {
    "avs" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }
}

