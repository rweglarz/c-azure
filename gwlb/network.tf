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
    "gwlb" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 3)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["wide-open"]
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
    "frontend" = {
      idx = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["wide-open"]
    },
    "backend" = {
      idx = 1
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["wide-open"]
    },
    "db" = {
      idx = 2
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
  }
}

module "vnet_sa" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-sa"
  address_space = local.vnet_address_space.sa

  subnets = {
    "s1" = {
      idx = 0
    },
  }
}



resource "azurerm_public_ip" "this" {
  name                = "${var.name}-natgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "this" {
  name                    = "${var.name}-natgw"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.this.id
}
resource "azurerm_subnet_nat_gateway_association" "this" {
  subnet_id      = module.vnet_sec.subnets["mgmt"].id
  nat_gateway_id = azurerm_nat_gateway.this.id
}


output "natgateway" {
  value = azurerm_public_ip.this.ip_address
}



resource "azurerm_virtual_network_peering" "sec-app1" {
  name                      = "${var.name}-sec-app1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.vnet_sec.name
  remote_virtual_network_id = module.vnet_app1.id
}
resource "azurerm_virtual_network_peering" "app1-sec" {
  name                      = "${var.name}-app1-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.vnet_app1.name
  remote_virtual_network_id = module.vnet_sec.id
  allow_forwarded_traffic   = true
}


resource "azurerm_subnet_route_table_association" "app1_frontend" {
  subnet_id      = module.vnet_app1.subnets["frontend"].id
  route_table_id = module.basic.route_table_id["private-via-fw"].ilb
}

resource "azurerm_subnet_route_table_association" "app1_backend" {
  subnet_id      = module.vnet_app1.subnets["backend"].id
  route_table_id = module.basic.route_table_id["all-via-fw"].ilb
}
