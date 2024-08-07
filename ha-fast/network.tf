module "vnet_transit" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = "${var.name}-transit"
  address_space = [cidrsubnet(var.cidr, 2, 0)]

  subnets = {
    "mgmt" = {
      idx = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
    "public" = {
      idx = 1
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.wide-open
    },
    "private" = {
      idx = 2
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.wide-open
    },
    "ha2" = {
      idx = 3
    },
  }
}
