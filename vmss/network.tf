module "vnet_sec" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-sec"
  address_space = [local.cidr.sec]

  subnets = {
    "mgmt" = {
      idx                       = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "public" = {
      idx                       = 1
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["wide-open"]
    },
    "private" = {
      idx                       = 2
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["wide-open"]
    },
    "dmz" = {
      idx                       = 3
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["wide-open"]
    },
    "appgw1" = {
      idx                       = 4
    },
  }
}



module "vnet_app1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-app1"
  address_space = [local.cidr.app1]

  subnets = {
    "app" = {
      idx = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
  }

  vnet_peering = {
    transit = {
      peer_vnet_name          = module.vnet_sec.vnet.name
      peer_vnet_id            = module.vnet_sec.vnet.id
      allow_forwarded_traffic = true
    }
  }
}



module "vnet_app2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-app2"
  address_space = [local.cidr.app2]

  subnets = {
    "app" = {
      idx = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
  }

  vnet_peering = {
    transit = {
      peer_vnet_name          = module.vnet_sec.vnet.name
      peer_vnet_id            = module.vnet_sec.vnet.id
      allow_forwarded_traffic = true
    }
  }
}



module "vnet_dmz" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-dmz"
  address_space = [local.cidr.dmz]

  subnets = {
    "app" = {
      idx = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
  }

  vnet_peering = {
    transit = {
      peer_vnet_name          = module.vnet_sec.vnet.name
      peer_vnet_id            = module.vnet_sec.vnet.id
      allow_forwarded_traffic = true
    }
  }
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
  subnet_id      = module.vnet_sec.subnets.mgmt.id
  nat_gateway_id = azurerm_nat_gateway.ngw.id
}
resource "azurerm_subnet_nat_gateway_association" "sec" {
  subnet_id      = module.vnet_sec.subnets.public.id
  nat_gateway_id = azurerm_nat_gateway.ngw.id
}



resource "azurerm_subnet_route_table_association" "this" {
  for_each = {
    app1 = {
      subnet_id = module.vnet_app1.subnets.app.id
      rt_id     = module.basic.route_table_id.mgmt-via-igw-dg-via-nh.via_private
    }
    app2 = {
      subnet_id = module.vnet_app2.subnets.app.id
      rt_id     = module.basic.route_table_id.mgmt-via-igw-dg-via-nh.via_private
    }
    dmz = {
      subnet_id = module.vnet_dmz.subnets.app.id
      rt_id     = module.basic.route_table_id.mgmt-via-igw-dg-via-nh.via_dmz
    }
  }

  subnet_id      = each.value.subnet_id
  route_table_id = each.value.rt_id
}
