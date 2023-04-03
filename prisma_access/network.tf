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
    "internet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 1)]
    },
    "internal" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 2)]
    },
    "jump" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.sec[0], 3, 3)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "RouteServerSubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 6)]
    },
    "GatewaySubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.sec[0], 3, 7)]
    },
  }
}

module "vnet_panorama" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-panorama"
  address_space = local.vnet_address_space.panorama

  subnets = {
    "panorama" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.panorama[0], 3, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
  }
}


resource "azurerm_virtual_network_peering" "vnet_sec-vnet_pan" {
  name                      = "vnet-sec--vnet-pan"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.vnet_sec.vnet.name
  remote_virtual_network_id = module.vnet_panorama.vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "vnet_pan-vnet_sec" {
  name                      = "vnet-pan--vnet-sec"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = module.vnet_panorama.vnet.name
  remote_virtual_network_id = module.vnet_sec.vnet.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = true
  depends_on = [
    azurerm_virtual_network_peering.vnet_sec-vnet_pan
  ]
}



resource "azurerm_public_ip" "ngw" {
  name                = "${var.name}-ngw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "ngw" {
  name                    = "${var.name}-ngw"
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
resource "azurerm_subnet_nat_gateway_association" "internet" {
  subnet_id      = module.vnet_sec.subnets["internet"].id
  nat_gateway_id = azurerm_nat_gateway.ngw.id
}


output "nat_gw_ip" {
  value = azurerm_public_ip.ngw.ip_address
}
