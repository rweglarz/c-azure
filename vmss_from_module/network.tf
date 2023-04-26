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
      address_prefixes = [cidrsubnet(local.vnet_address_space.app1[0], 1, 0)]
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



resource "azurerm_subnet_route_table_association" "app1" {
  subnet_id      = module.vnet_app1.subnets["app"].id
  route_table_id = module.basic.route_table_id["mgmt-via-igw"].ilb
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

