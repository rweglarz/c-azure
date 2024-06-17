module "sdwan_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name          = "${local.dname}-sdwan-spoke1"
  address_space = [local.vnet_cidr.sdwan_spoke1]

  subnets = {
    "mgmt" = {
      address_prefixes          = [cidrsubnet(local.vnet_cidr.sdwan_spoke1, 4, 0)]
      network_security_group_id = azurerm_network_security_group.rg2_mgmt.id
      associate_nsg             = true
    },
    "isp1" = {
      address_prefixes          = [cidrsubnet(local.vnet_cidr.sdwan_spoke1, 4, 1)]
      network_security_group_id = azurerm_network_security_group.rg2_all.id
      associate_nsg             = true
    },
    "isp2" = {
      address_prefixes          = [cidrsubnet(local.vnet_cidr.sdwan_spoke1, 4, 2)]
      network_security_group_id = azurerm_network_security_group.rg2_all.id
      associate_nsg             = true
    },
    "private" = {
      address_prefixes          = [cidrsubnet(local.vnet_cidr.sdwan_spoke1, 4, 3)]
      network_security_group_id = azurerm_network_security_group.rg2_all.id
      associate_nsg             = true
    },
    "s1" = {
      address_prefixes = [cidrsubnet(local.vnet_cidr.sdwan_spoke1, 4, 4)]
    },
  }
}

locals {
  sdwan_spoke1_fw = {
    mgmt_ip   = cidrhost(module.sdwan_spoke1.subnets["mgmt"].address_prefixes[0], 5),
    eth1_1_ip = cidrhost(module.sdwan_spoke1.subnets["isp1"].address_prefixes[0], 5),
    eth1_1_gw = cidrhost(module.sdwan_spoke1.subnets["isp1"].address_prefixes[0], 1),
    eth1_2_ip = cidrhost(module.sdwan_spoke1.subnets["isp2"].address_prefixes[0], 5),
    eth1_2_gw = cidrhost(module.sdwan_spoke1.subnets["isp2"].address_prefixes[0], 1),
    eth1_3_ip = cidrhost(module.sdwan_spoke1.subnets["private"].address_prefixes[0], 5),
    eth1_3_gw = cidrhost(module.sdwan_spoke1.subnets["private"].address_prefixes[0], 1),
  }
}


module "sdwan_spoke1_fw" {
  source = "../modules/vmseries"

  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  name                = "${local.dname}-sdwan-spoke1-fw"
  username            = var.username
  password            = var.password
  interfaces = {
    mgmt = {
      device_index       = 0
      name               = "${local.dname}-sdwan-spoke1-fw-mgmt"
      subnet_id          = module.sdwan_spoke1.subnets["mgmt"].id
      private_ip_address = local.sdwan_spoke1_fw["mgmt_ip"]
      public_ip          = true
    }
    isp1 = {
      device_index         = 1
      name                 = "${local.dname}-sdwan-spoke1-fw-isp1"
      subnet_id            = module.sdwan_spoke1.subnets["isp1"].id
      private_ip_address   = local.sdwan_spoke1_fw["eth1_1_ip"]
      enable_ip_forwarding = true
      public_ip            = true
    }
    isp2 = {
      device_index         = 2
      name                 = "${local.dname}-sdwan-spoke1-fw-isp2"
      subnet_id            = module.sdwan_spoke1.subnets["isp2"].id
      private_ip_address   = local.sdwan_spoke1_fw["eth1_2_ip"]
      enable_ip_forwarding = true
      public_ip            = true
    }
    private = {
      device_index         = 3
      name                 = "${local.dname}-sdwan-spoke1-fw-private"
      subnet_id            = module.sdwan_spoke1.subnets["private"].id
      private_ip_address   = local.sdwan_spoke1_fw["eth1_3_ip"]
      enable_ip_forwarding = true
    }
  }

  bootstrap_options = merge(
    local.bootstrap_options["common"],
    local.bootstrap_options["sdwan_spoke1_fw"],
    var.bootstrap_options["sdwan_spoke1_fw"],
  )
}


resource "azurerm_route_table" "sdwan_spoke1" {
  name                = "${var.name}-sdwan-spoke1"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
}

resource "azurerm_route" "sdwan_spoke1-prv" {
  name                   = "prv"
  resource_group_name    = azurerm_resource_group.rg2.name
  route_table_name       = azurerm_route_table.sdwan_spoke1.name
  address_prefix         = "172.16.0.0/12"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.sdwan_spoke1_fw["eth1_3_ip"]
}

resource "azurerm_subnet_route_table_association" "sdwan_spoke1" {
  subnet_id      = module.sdwan_spoke1.subnets["s1"].id
  route_table_id = azurerm_route_table.sdwan_spoke1.id
}
