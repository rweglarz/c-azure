module "vnet_transit" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.dname}-transit"
  address_space = [local.vnet_cidr.transit]

  subnets = {
    "mgmt" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
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
    "tosdwan1" = {
      idx                       = 3
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
    },
    "tosdwan2" = {
      idx                       = 4
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
    },
  }
}

resource "azurerm_subnet_route_table_association" "tosdwan1" {
  subnet_id      = module.vnet_transit.subnets.tosdwan1.id
  route_table_id = module.basic.route_table_id.private-via-nh.sdwan1
}

resource "azurerm_subnet_route_table_association" "tosdwan2" {
  subnet_id      = module.vnet_transit.subnets.tosdwan2.id
  route_table_id = module.basic.route_table_id.private-via-nh.sdwan2
}




resource "azurerm_public_ip" "transit_natgw" {
  name                = "${local.dname}-transit-nat-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "transit_natgw" {
  name                    = "${local.dname}-transit-nat-gateway"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "transit_natgw" {
  nat_gateway_id       = azurerm_nat_gateway.transit_natgw.id
  public_ip_address_id = azurerm_public_ip.transit_natgw.id
}

resource "azurerm_subnet_nat_gateway_association" "transit_natgw_mgmt" {
  subnet_id      = module.vnet_transit.subnets.mgmt.id
  nat_gateway_id = azurerm_nat_gateway.transit_natgw.id
}
