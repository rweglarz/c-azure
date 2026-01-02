module "vnet_hub2_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.dname}-hub2-spoke1"
  address_space = [local.vnet_cidr.hub2_spoke1]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
    "pe" = {
      idx                               = 1
      private_endpoint_network_policies = "RouteTableEnabled"
    }
  }
}

module "vnet_hub2_spoke2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.dname}-hub2-spoke2"
  address_space = [local.vnet_cidr.hub2_spoke2]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }
}

module "linux_hub2_spoke1" {
  source = "../modules/linux"

  name                = "${var.name}-hub2-spoke1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_hub2_spoke1.subnets.s0.id
  private_ip_address  = cidrhost(module.vnet_hub2_spoke1.subnets.s0.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  size                = var.workload_size
}

module "linux_hub2_spoke2" {
  source = "../modules/linux"

  name                = "${var.name}-hub2-spoke2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_hub2_spoke2.subnets.s0.id
  private_ip_address  = cidrhost(module.vnet_hub2_spoke2.subnets.s0.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  size                = var.workload_size
}

#region spoke1 routing
resource "azurerm_route_table" "hub2_spoke1" {
  name                = "${var.name}-hub2-spoke1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "hub2_spoke1" {
  for_each = var.cloud_ngfw_panorama_config!=null ? toset([
    module.vnet_hub2_spoke1.subnets["pe"].address_prefixes[0],
  ]) : toset([])
  name                   = format("r-%s", replace(each.key, "/", "_"))
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.hub2_spoke1.name
  address_prefix         = each.key
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_palo_alto_next_generation_firewall_virtual_hub_panorama.hub2[0].network_profile[0].ip_of_trust_for_user_defined_routes
}


resource "azurerm_subnet_route_table_association" "hub2_spoke1" {
  subnet_id      = module.vnet_hub2_spoke1.subnets["s0"].id
  route_table_id = azurerm_route_table.hub2_spoke1.id
}
#endregion

