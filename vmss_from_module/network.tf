module "vnet_sec" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-sec"
  address_space = local.vnet_address_space.sec

  subnets = {
    "mgmt" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.sec[0], 3, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "public" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.sec[0], 3, 1)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["wide-open"]
    },
    "private" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 2)]
      # associate_nsg             = true
      # network_security_group_id = module.basic.sg_id["wide-open"]
    },
    "jump" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 3)]
    },
    "appgw1" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 4)]
    },
    "appgw2" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 5)]
    },
  }
}

module "vnet_app1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-app1"
  address_space = local.vnet_address_space.app1

  subnets = {
    "app" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.app1[0], 2, 0)]
    },
    "db" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.app1[0], 2, 1)]
    },
  }
}


module "vnet_app2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-app2"
  address_space = local.vnet_address_space.app2

  subnets = {
    "app" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.app2[0], 1, 0)]
    },
  }
}




resource "azurerm_virtual_network_peering" "sec-app1" {
  name                      = "${var.name}-sec-app1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.vnet_sec.vnet.name
  remote_virtual_network_id = module.vnet_app1.vnet.id
}
resource "azurerm_virtual_network_peering" "app1-sec" {
  name                      = "${var.name}-app1-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.vnet_app1.vnet.name
  remote_virtual_network_id = module.vnet_sec.vnet.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "sec-app2" {
  name                      = "${var.name}-sec-app2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.vnet_sec.vnet.name
  remote_virtual_network_id = module.vnet_app2.vnet.id
}
resource "azurerm_virtual_network_peering" "app2-sec" {
  name                      = "${var.name}-app2-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.vnet_app2.vnet.name
  remote_virtual_network_id = module.vnet_sec.vnet.id
  allow_forwarded_traffic   = true
}



resource "azurerm_route_table" "app1" {
  name                = "${var.name}-app1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "app1-dg" {
  name                   = "dg_fw"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.app1.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_lb.fw_int.frontend_ip_configuration[0].private_ip_address
}

locals {
  mgmt_routes = flatten([
    for e in var.mgmt_ips : {
      name = replace(e.cidr, "/\\//", "_")
      prefix = e.cidr
      nh   = azurerm_lb.fw_int.frontend_ip_configuration[0].private_ip_address
    }
  ])
}

resource "azurerm_route" "app1-mgmt" {
  for_each               = { for nh in local.mgmt_routes : nh.name => nh }
  name                   = each.value.name
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.app1.name
  address_prefix         = each.value.prefix
  next_hop_type          = "Internet"
}

resource "azurerm_route" "app1-apps" {
  name                   = "app-micro-seg"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.app1.name
  address_prefix         = module.vnet_app1.subnets.app.address_prefixes[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_lb.fw_int.frontend_ip_configuration[0].private_ip_address
}




resource "azurerm_subnet_route_table_association" "app1" {
  subnet_id      = module.vnet_app1.subnets["app"].id
  route_table_id = azurerm_route_table.app1.id
}

resource "azurerm_subnet_route_table_association" "app2" {
  subnet_id      = module.vnet_app2.subnets["app"].id
  route_table_id = module.basic.route_table_id["mgmt-via-igw"].ilb
}






resource "azurerm_public_ip" "ngw" {
  name                = "${var.name}-nat-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "ngw" {
  name                    = "${var.name}-nat-gateway"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "ngw" {
  nat_gateway_id       = azurerm_nat_gateway.ngw.id
  public_ip_address_id = azurerm_public_ip.ngw.id
}

resource "azurerm_subnet_nat_gateway_association" "mgmt" {
  subnet_id      = module.vnet_sec.subnets["mgmt"].id
  nat_gateway_id = azurerm_nat_gateway.ngw.id
}

resource "azurerm_subnet_nat_gateway_association" "pub" {
  subnet_id      = module.vnet_sec.subnets["public"].id
  nat_gateway_id = azurerm_nat_gateway.ngw.id
}

