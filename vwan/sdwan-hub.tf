module "hub2_sdwan" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-hub2-sdwan"
  address_space = [local.vnet_cidr.hub2_sdwan]

  subnets = {
    "mgmt" = {
      idx                       = 0
      network_security_group_id = module.basic_rg1.sg_id.mgmt
      associate_nsg             = true
    },
    "internet" = {
      idx                       = 1
      network_security_group_id = module.basic_rg1.sg_id.wide-open
      associate_nsg             = true
    },
    "private" = {
      idx                       = 2
    },
  }
}

module "hub4_sdwan" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name          = "${local.dname}-hub4-sdwan"
  address_space = [local.vnet_cidr.hub4_sdwan]

  subnets = {
    "mgmt" = {
      idx                       = 0
      network_security_group_id = module.basic_rg2.sg_id.mgmt
      associate_nsg             = true
    },
    "internet" = {
      idx                       = 1
      network_security_group_id = module.basic_rg2.sg_id.wide-open
      associate_nsg             = true
    },
    "private" = {
      idx                       = 2
    },
  }
}


locals {
  hub2_sdwan_fw1 = {
    mgmt_ip   = cidrhost(module.hub2_sdwan.subnets.mgmt.address_prefixes[0], 5),
    eth1_1_ip = cidrhost(module.hub2_sdwan.subnets.internet.address_prefixes[0], 5),
    eth1_1_gw = cidrhost(module.hub2_sdwan.subnets.internet.address_prefixes[0], 1),
    eth1_2_ip = cidrhost(module.hub2_sdwan.subnets.private.address_prefixes[0], 5),
    eth1_2_gw = cidrhost(module.hub2_sdwan.subnets.private.address_prefixes[0], 1),
  }
  hub2_sdwan_fw2 = {
    mgmt_ip   = cidrhost(module.hub2_sdwan.subnets.mgmt.address_prefixes[0], 6),
    eth1_1_ip = cidrhost(module.hub2_sdwan.subnets.internet.address_prefixes[0], 6),
    eth1_1_gw = cidrhost(module.hub2_sdwan.subnets.internet.address_prefixes[0], 1),
    eth1_2_ip = cidrhost(module.hub2_sdwan.subnets.private.address_prefixes[0], 6),
    eth1_2_gw = cidrhost(module.hub2_sdwan.subnets.private.address_prefixes[0], 1),
  }
  hub4_sdwan_fw = {
    mgmt_ip   = cidrhost(module.hub4_sdwan.subnets.mgmt.address_prefixes[0], 5),
    eth1_1_ip = cidrhost(module.hub4_sdwan.subnets.internet.address_prefixes[0], 5),
    eth1_1_gw = cidrhost(module.hub4_sdwan.subnets.internet.address_prefixes[0], 1),
    eth1_2_ip = cidrhost(module.hub4_sdwan.subnets.private.address_prefixes[0], 5),
    eth1_2_gw = cidrhost(module.hub4_sdwan.subnets.private.address_prefixes[0], 1),
  }
}


module "hub2_sdwan_fw1" {
  source = "../modules/vmseries"

  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  name                = "${local.dname}-hub2-sdwan-fw1"
  username            = var.username
  password            = var.password
  interfaces = {
    mgmt = {
      device_index       = 0
      subnet_id          = module.hub2_sdwan.subnets.mgmt.id
      private_ip_address = local.hub2_sdwan_fw1["mgmt_ip"]
      public_ip          = true
    }
    internet = {
      device_index         = 1
      subnet_id            = module.hub2_sdwan.subnets.internet.id
      private_ip_address   = local.hub2_sdwan_fw1["eth1_1_ip"]
      enable_ip_forwarding = true
      public_ip            = true
    }
    private = {
      device_index         = 2
      subnet_id            = module.hub2_sdwan.subnets.private.id
      private_ip_address   = local.hub2_sdwan_fw1["eth1_2_ip"]
      enable_ip_forwarding = true
    }
  }

  bootstrap_options = merge(
    local.bootstrap_options["common"],
    local.bootstrap_options["hub2_sdwan_fw1"],
    var.bootstrap_options["hub2_sdwan_fw1"],
  )
}

module "hub2_sdwan_fw2" {
  source = "../modules/vmseries"

  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  name                = "${local.dname}-hub2-sdwan-fw2"
  username            = var.username
  password            = var.password
  interfaces = {
    mgmt = {
      device_index       = 0
      subnet_id          = module.hub2_sdwan.subnets.mgmt.id
      private_ip_address = local.hub2_sdwan_fw2["mgmt_ip"]
      public_ip          = true
    }
    internet = {
      device_index         = 1
      subnet_id            = module.hub2_sdwan.subnets.internet.id
      private_ip_address   = local.hub2_sdwan_fw2["eth1_1_ip"]
      enable_ip_forwarding = true
      public_ip            = true
    }
    private = {
      device_index         = 2
      subnet_id            = module.hub2_sdwan.subnets.private.id
      private_ip_address   = local.hub2_sdwan_fw2["eth1_2_ip"]
      enable_ip_forwarding = true
    }
  }

  bootstrap_options = merge(
    local.bootstrap_options["common"],
    local.bootstrap_options["hub2_sdwan_fw2"],
    var.bootstrap_options["hub2_sdwan_fw2"],
  )
}


module "hub4_sdwan_fw" {
  source = "../modules/vmseries"

  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  name                = "${local.dname}-hub4-sdwan-fw"
  username            = var.username
  password            = var.password
  interfaces = {
    mgmt = {
      device_index       = 0
      subnet_id            = module.hub4_sdwan.subnets.mgmt.id
      private_ip_address = local.hub4_sdwan_fw["mgmt_ip"]
      public_ip          = true
    }
    internet = {
      device_index         = 1
      subnet_id            = module.hub4_sdwan.subnets.internet.id
      private_ip_address   = local.hub4_sdwan_fw["eth1_1_ip"]
      enable_ip_forwarding = true
      public_ip            = true
    }
    private = {
      device_index         = 2
      subnet_id            = module.hub4_sdwan.subnets.private.id
      private_ip_address   = local.hub4_sdwan_fw["eth1_2_ip"]
      enable_ip_forwarding = true
    }
  }

  bootstrap_options = merge(
    local.bootstrap_options["common"],
    local.bootstrap_options["hub4_sdwan_fw"],
    var.bootstrap_options["hub4_sdwan_fw"],
  )
}


