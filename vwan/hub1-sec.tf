module "hub1_sec" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-hub1-sec"
  address_space = [local.vnet_cidr.hub1_sec]
  bgp_community = "12076:20019"

  subnets = {
    "mgmt" = {
      idx                       = 0
      network_security_group_id = azurerm_network_security_group.rg1_mgmt.id
      associate_nsg             = true
    },
    "data" = {
      idx                       = 1
      network_security_group_id = azurerm_network_security_group.rg1_all.id
      associate_nsg             = true
    },
  }
}


resource "azurerm_route_table" "hub1_sec_data" {
  name                = "${local.dname}-hub1-sec-data"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
}


resource "azurerm_route_table" "hub1_sec_spokes" {
  name                = "${local.dname}-hub1-sec-spokes"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
}

resource "azurerm_route" "hub1_sec_spokes_172" {
  name                   = "172"
  resource_group_name    = azurerm_resource_group.rg1.name
  route_table_name       = azurerm_route_table.hub1_sec_spokes.name
  address_prefix         = "172.16.0.0/12"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = cidrhost(module.hub1_sec.subnets.data.address_prefixes[0], 5)
}

module "hub1_sec_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-hub1-sec-spoke1"
  address_space = [local.vnet_cidr.hub1_sec_spoke1]
  bgp_community = "12076:20011"

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

module "hub1_sec_spoke2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-hub1-sec-spoke2"
  address_space = [local.vnet_cidr.hub1_sec_spoke2]

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

resource "azurerm_subnet_route_table_association" "hub1_sec_spoke1_s1" {
  subnet_id      = module.hub1_sec_spoke1.subnets.s1.id
  route_table_id = azurerm_route_table.hub1_sec_spokes.id
}



resource "azurerm_virtual_network" "hub1_sec_spoke2" {
  name                = "${local.dname}-hub1-sec-spoke2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [local.vnet_cidr.hub1_sec_spoke2]
}


resource "azurerm_subnet_route_table_association" "hub1_sec_data" {
  subnet_id      = module.hub1_sec.subnets.data.id
  route_table_id = azurerm_route_table.hub1_sec_data.id
}

resource "azurerm_virtual_network_peering" "hub1_sec_spoke1-hub1_sec" {
  name                      = "${local.dname}-hub1-vnet2-hub1-sec"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = module.hub1_sec_spoke1.vnet.name
  remote_virtual_network_id = module.hub1_sec.vnet.id
  allow_forwarded_traffic   = true
}
resource "azurerm_virtual_network_peering" "hub1_sec-hub1_sec_spoke1" {
  name                      = "${local.dname}-hub1-sec-hub1-spoke1"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = module.hub1_sec.vnet.name
  remote_virtual_network_id = module.hub1_sec_spoke1.vnet.id
}


resource "panos_panorama_template_stack" "hub1_sec_fw" {
  name         = "azure-vwan-hub1-sec-fw-ts"
  default_vsys = "vsys1"
  templates = [
    "azure-1-if",
    "vm common",
  ]
  description = "pat:acp"
}

resource "panos_panorama_template_variable" "hub1_sec_fw_eth1_1_gw" {
  template_stack = panos_panorama_template_stack.hub1_sec_fw.name
  name           = "$eth1-1-gw"
  type           = "ip-netmask"
  value          = cidrhost(module.hub1_sec.subnets.data.address_prefixes[0], 1)
}


module "hub1_sec_fw" {
  source = "../modules/vmseries"

  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  name                = "${local.dname}-hub1-sec-fw"
  username            = var.username
  password            = var.password
  interfaces = {
    mgmt = {
      device_index = 0
      subnet_id    = module.hub1_sec.subnets.mgmt.id
      public_ip    = true
    }
    data = {
      device_index         = 1
      subnet_id            = module.hub1_sec.subnets.data.id
      private_ip_address   = cidrhost(module.hub1_sec.subnets.data.address_prefixes[0], 5)
      enable_ip_forwarding = true
    }
  }

  bootstrap_options = merge(
    local.bootstrap_options["common"],
    local.bootstrap_options["hub1_sec_fw"],
  )
}

