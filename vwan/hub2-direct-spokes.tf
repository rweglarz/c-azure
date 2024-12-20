module "hub2_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-hub2-spoke1"
  address_space = [local.vnet_cidr.hub2_spoke1]
  bgp_community = "12076:20021"

  dns_servers = var.cloud_ngfw_panorama_config.hub2==null ? [] : [
    azurerm_palo_alto_next_generation_firewall_virtual_hub_panorama.hub2[0].network_profile[0].ip_of_trust_for_user_defined_routes
  ]

  subnets = {
    "s1" = {
      idx                       = 0
      network_security_group_id = module.basic_rg1.sg_id.mgmt
      associate_nsg             = true
    },
    "s2" = {
      idx                       = 1
      network_security_group_id = module.basic_rg1.sg_id.mgmt
      associate_nsg             = true
    },
  }
}

module "hub2_spoke2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-hub2-spoke2"
  address_space = [local.vnet_cidr.hub2_spoke2]
  bgp_community = "12076:20021"

  subnets = {
    "s1" = {
      idx                       = 0
      network_security_group_id = module.basic_rg1.sg_id.mgmt
      associate_nsg             = true
    },
  }
}

resource "azurerm_route_table" "hub2_spoke1" {
  name                = "${var.name}-hub2-spoke1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
}

resource "azurerm_route" "hub2_spoke1-local" {
  name = "local"
  resource_group_name    = azurerm_resource_group.rg1.name
  route_table_name       = azurerm_route_table.hub2_spoke1.name
  address_prefix         = tolist(module.hub2_spoke1.vnet.address_space)[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.cloud_ngfw_private_ips.hub2
}

resource "azurerm_subnet_route_table_association" "hub2_spoke1_s1" {
  subnet_id      = module.hub2_spoke1.subnets["s1"].id
  route_table_id = azurerm_route_table.hub2_spoke1.id
}

resource "azurerm_subnet_route_table_association" "hub2_spoke1_s2" {
  subnet_id      = module.hub2_spoke1.subnets["s2"].id
  route_table_id = azurerm_route_table.hub2_spoke1.id
}

resource "azurerm_subnet_route_table_association" "hub2_spoke2_s1" {
  subnet_id      = module.hub2_spoke2.subnets["s1"].id
  route_table_id = module.basic_rg1.route_table_id["only-mgmt-via-igw"].igw
}
