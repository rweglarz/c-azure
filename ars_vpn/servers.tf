module "vnet_left_srv_1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = "${var.name}-left-srv-1"
  address_space = local.vnet_address_space.left_srv1

  subnets = {
    "s1" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.left_srv1[0], 4, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "s2" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.left_srv1[0], 4, 1)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
  }
}

module "vnet_left_srv_2" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = "${var.name}-left-srv-2"
  address_space = local.vnet_address_space.left_srv2

  subnets = {
    "s1" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.left_srv2[0], 4, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "s2" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.left_srv2[0], 4, 1)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
  }
}

module "vnet_right_srv_1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = "${var.name}-right-srv-1"
  address_space = local.vnet_address_space.right_srv1

  subnets = {
    "s1" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.right_srv1[0], 4, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "s2" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.right_srv1[0], 4, 1)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
  }
}

resource "azurerm_virtual_network_peering" "vnet_left_hub-vnet_left_srv_1" {
  name                      = "left-hub--left-srv-1"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.vnet_left_hub.vnet.name
  remote_virtual_network_id = module.vnet_left_srv_1.vnet.id
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "vnet_left_srv_1-vnet_left_hub" {
  name                      = "left-srv-1--left-hub"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.vnet_left_srv_1.vnet.name
  remote_virtual_network_id = module.vnet_left_hub.vnet.id
  use_remote_gateways       = true
  depends_on = [
    azurerm_virtual_network_peering.vnet_left_hub-vnet_left_srv_1
  ]
}


resource "azurerm_virtual_network_peering" "vnet_right_hub-vnet_right_srv_1" {
  name                      = "right-hub--right-srv-1"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.vnet_right_hub.vnet.name
  remote_virtual_network_id = module.vnet_right_srv_1.vnet.id
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "vnet_right_srv_1-vnet_right_hub" {
  name                      = "right-srv-1--right-hub"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.vnet_right_srv_1.vnet.name
  remote_virtual_network_id = module.vnet_right_hub.vnet.id
  use_remote_gateways       = true
  depends_on = [
    azurerm_virtual_network_peering.vnet_right_hub-vnet_right_srv_1
  ]
}


resource "azurerm_subnet_route_table_association" "left_srv1" {
  subnet_id      = module.vnet_left_srv_1.subnets["s1"].id
  route_table_id = module.basic.route_table_id["mgmt-via-igw"]["left"]
}





module "srv_left_11" {
  source = "../modules/linux"

  name                = "${var.name}-srv-left-11"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.vnet_left_srv_1.subnets["s1"].id
  private_ip_address  = cidrhost(module.vnet_left_srv_1.subnets["s1"].address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
}

module "srv_right_11" {
  source = "../modules/linux"

  name                = "${var.name}-srv-right-11"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.vnet_right_srv_1.subnets["s1"].id
  private_ip_address  = cidrhost(module.vnet_right_srv_1.subnets["s1"].address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
}
