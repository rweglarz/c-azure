module "vnet_left_u_srv_1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${var.name}-left-u-srv-1"
  address_space = local.vnet_address_space.left_u_srv1

  subnets = {
    "s1" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.left_u_srv1[0], 4, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic_rg1.sg_id["mgmt"]
    },
    "s2" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.left_u_srv1[0], 4, 1)]
      associate_nsg             = true
      network_security_group_id = module.basic_rg1.sg_id["mgmt"]
    },
  }
}

module "vnet_left_u_srv_2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${var.name}-left-u-srv-2"
  address_space = local.vnet_address_space.left_u_srv2

  subnets = {
    "s1" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.left_u_srv2[0], 4, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic_rg1.sg_id["mgmt"]
    },
    "s2" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.left_u_srv2[0], 4, 1)]
      associate_nsg             = true
      network_security_group_id = module.basic_rg1.sg_id["mgmt"]
    },
  }
}


module "vnet_left_b_srv_1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name          = "${var.name}-left-b-srv-1"
  address_space = local.vnet_address_space.left_b_srv1

  subnets = {
    "s1" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.left_b_srv1[0], 4, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic_rg2.sg_id["mgmt"]
    },
    "s2" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.left_b_srv1[0], 4, 1)]
      associate_nsg             = true
      network_security_group_id = module.basic_rg2.sg_id["mgmt"]
    },
  }
}


module "vnet_right_srv_1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${var.name}-right-srv-1"
  address_space = local.vnet_address_space.right_srv1

  subnets = {
    "s1" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.right_srv1[0], 4, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic_rg1.sg_id["mgmt"]
    },
    "s2" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.right_srv1[0], 4, 1)]
      associate_nsg             = true
      network_security_group_id = module.basic_rg1.sg_id["mgmt"]
    },
  }
}


module "vnet_peering-left_u_srv_1-left_u_hub" {
  source = "../modules/vnet_peering"

  on_local = {
    resource_group_name     = azurerm_resource_group.rg1.name
    virtual_network_name    = module.vnet_left_u_srv_1.vnet.name
    virtual_network_id      = module.vnet_left_u_srv_1.vnet.id
    use_remote_gateways     = true
    allow_forwarded_traffic = true
  }

  on_remote = {
    resource_group_name    = azurerm_resource_group.rg1.name
    virtual_network_name   = module.vnet_left_u_hub.vnet.name
    virtual_network_id     = module.vnet_left_u_hub.vnet.id
    allow_gateway_transit  = true
  }
}


module "vnet_peering-left_b_srv_1-left_b_hub" {
  source = "../modules/vnet_peering"

  on_local = {
    resource_group_name     = azurerm_resource_group.rg2.name
    virtual_network_name    = module.vnet_left_b_srv_1.vnet.name
    virtual_network_id      = module.vnet_left_b_srv_1.vnet.id
    use_remote_gateways     = true
    allow_forwarded_traffic = true
  }

  on_remote = {
    resource_group_name    = azurerm_resource_group.rg2.name
    virtual_network_name   = module.vnet_left_b_hub.vnet.name
    virtual_network_id     = module.vnet_left_b_hub.vnet.id
    allow_gateway_transit  = true
  }
}


module "vnet_peering-right_srv_1-right_hub" {
  source = "../modules/vnet_peering"

  on_local = {
    resource_group_name     = azurerm_resource_group.rg1.name
    virtual_network_name    = module.vnet_right_srv_1.vnet.name
    virtual_network_id      = module.vnet_right_srv_1.vnet.id
    use_remote_gateways     = true
  }

  on_remote = {
    resource_group_name    = azurerm_resource_group.rg1.name
    virtual_network_name   = module.vnet_right_hub.vnet.name
    virtual_network_id     = module.vnet_right_hub.vnet.id
    allow_gateway_transit  = true
  }

  depends_on = [ 
    azurerm_virtual_network_gateway.right
   ]
}


resource "azurerm_subnet_route_table_association" "left_u_srv1" {
  subnet_id      = module.vnet_left_u_srv_1.subnets["s1"].id
  route_table_id = module.basic_rg1.route_table_id["private-via-fw"]["left_u"]
}

resource "azurerm_subnet_route_table_association" "left_b_srv1" {
  subnet_id      = module.vnet_left_b_srv_1.subnets["s1"].id
  route_table_id = module.basic_rg2.route_table_id["private-via-fw"]["left_b"]
}





module "linux_left_u_srv11" {
  source = "../modules/linux"

  name                = "${var.name}-left-u-srv11"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  subnet_id           = module.vnet_left_u_srv_1.subnets["s1"].id
  private_ip_address  = cidrhost(module.vnet_left_u_srv_1.subnets["s1"].address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg1.public_key
}

module "linux_left_b_srv11" {
  source = "../modules/linux"

  name                = "${var.name}-left-b-srv11"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  subnet_id           = module.vnet_left_b_srv_1.subnets["s1"].id
  private_ip_address  = cidrhost(module.vnet_left_b_srv_1.subnets["s1"].address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg2.public_key
}

module "linux_right_srv11" {
  source = "../modules/linux"

  name                = "${var.name}-right-srv11"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  subnet_id           = module.vnet_right_srv_1.subnets["s1"].id
  private_ip_address  = cidrhost(module.vnet_right_srv_1.subnets["s1"].address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg1.public_key
}
