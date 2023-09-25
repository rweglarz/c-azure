module "vnet_aks" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-aks"
  address_space = [var.vnet_cidr]

  subnets = {
    "fw_prv" = {
      address_prefixes          = [cidrsubnet(var.vnet_cidr, 5, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["wide-open"]
    },
    "fw_pub" = {
      address_prefixes          = [cidrsubnet(var.vnet_cidr, 5, 1)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["wide-open"]
    },
    "aks1" = {
      address_prefixes = [cidrsubnet(var.vnet_cidr, 5, 2)]
    },
    "appgw1" = {
      address_prefixes = [cidrsubnet(var.vnet_cidr, 5, 3)]
    },
  }
}



resource "azurerm_route_table" "aks" {
  name                = "${var.name}-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "aks_dg" {
  name                   = "dg"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.aks.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "Internet"
}

resource "azurerm_route" "aks_appgw1" {
  count = var.fw_prv_ip!=null ? 1 : 0

  name                   = "appgw"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.aks.name
  address_prefix         = module.vnet_aks.subnets.appgw1.address_prefixes[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.fw_prv_ip
}

resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = module.vnet_aks.subnets.aks1.id
  route_table_id = azurerm_route_table.aks.id
}



resource "azurerm_route_table" "appgw" {
  name                = "${var.name}-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "appgw_aks1" {
  count = var.fw_prv_ip!=null ? 1 : 0
  name                   = "aks"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.appgw.name
  address_prefix         = module.vnet_aks.subnets.aks1.address_prefixes[0]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.fw_prv_ip
}

resource "azurerm_subnet_route_table_association" "appgw1" {
  subnet_id      = module.vnet_aks.subnets.appgw1.id
  route_table_id = azurerm_route_table.appgw.id
}



resource "azurerm_public_ip" "natgw" {
  name                = "${var.name}-natgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "natgw" {
  name                    = "${var.name}-natgw"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "natgw" {
  nat_gateway_id       = azurerm_nat_gateway.natgw.id
  public_ip_address_id = azurerm_public_ip.natgw.id
}

resource "azurerm_subnet_nat_gateway_association" "aks1" {
  subnet_id      = module.vnet_aks.subnets.aks1.id
  nat_gateway_id = azurerm_nat_gateway.natgw.id
}



output "natgw_ip" {
  value = azurerm_public_ip.natgw.ip_address
}
