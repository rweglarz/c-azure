module "vnet_hub1_sec" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.dname}-hub1-sec"
  address_space = [local.vnet_cidr.hub1_sec]

  subnets = {
    "public" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
    },
    "private" = {
      idx                       = 1
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
    },
    "mgmt" = {
      idx                       = 2
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }
}


module "vnet_hub1_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.dname}-hub1-spoke1"
  address_space = [local.vnet_cidr.hub1_spoke1]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }

  vnet_peering = {
    hub1_sec = {
      peer_vnet_name          = module.vnet_hub1_sec.vnet.name
      peer_vnet_id            = module.vnet_hub1_sec.vnet.id
      allow_forwarded_traffic = true
    }
  }
}


module "vnet_hub1_sdwan" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.dname}-hub1-sdwan"
  address_space = [local.vnet_cidr.hub1_sdwan]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }
}


resource "azurerm_subnet_route_table_association" "hub1_spoke1" {
  subnet_id      = module.vnet_hub1_spoke1.subnets.s0.id
  route_table_id = module.basic.route_table_id.private-via-fw.hub1
}




module "linux_hub1_spoke1" {
  source = "../modules/linux"

  name                = "${var.name}-hub1-spoke1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_hub1_spoke1.subnets.s0.id
  private_ip_address  = cidrhost(module.vnet_hub1_spoke1.subnets.s0.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
}



resource "azurerm_public_ip" "hub1_natgw" {
  name                = "${local.dname}-hub1-nat-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "hub1_natgw" {
  name                    = "${local.dname}-hub1-nat-gateway"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "hub1_natgw" {
  nat_gateway_id       = azurerm_nat_gateway.hub1_natgw.id
  public_ip_address_id = azurerm_public_ip.hub1_natgw.id
}

resource "azurerm_subnet_nat_gateway_association" "hub1_natgw_mgmt" {
  subnet_id      = module.vnet_hub1_sec.subnets.mgmt.id
  nat_gateway_id = azurerm_nat_gateway.hub1_natgw.id
}

