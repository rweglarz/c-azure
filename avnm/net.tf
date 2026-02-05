module "sec" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-sec"
  address_space = [cidrsubnet(var.cidr, 8, 0)]

  subnets = {
    "mgmt" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.wide-open
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
  tags = { env = "security" }
}


module "app_vnets" {
  for_each = {
    prod_1 = {
      cidr = cidrsubnet(var.cidr, 8, 16+1)
      tags = { env = "prod" }
    }
    prod_2 = {
      cidr = cidrsubnet(var.cidr, 8, 16+2)
      tags = { env = "prod" }
    }
    prod_3 = {
      cidr = cidrsubnet(var.cidr, 8, 16+3)
      tags = { env = "prod" }
    }
    dev_1 = {
      cidr = cidrsubnet(var.cidr, 8, 32+1)
      tags = { env = "dev12" }
    }
    dev_2 = {
      cidr = cidrsubnet(var.cidr, 8, 32+2)
      tags = { env = "dev12" }
    }
    dev_3 = {
      cidr = cidrsubnet(var.cidr, 8, 32+3)
      tags = { env = "dev34" }
    }
    dev_4 = {
      cidr = cidrsubnet(var.cidr, 8, 32+4)
      tags = { env = "dev34" }
    }
  }
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-${each.key}"
  address_space = [each.value.cidr]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
    },
    "sprivate" = {
      idx                       = 1
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
      tags                      = ["private"]
    },
    "spublic" = {
      idx                       = 2
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
      tags                      = ["public"]
    },
  }
  tags = each.value.tags
}

