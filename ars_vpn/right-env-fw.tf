module "vnet_right_env_fw" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${var.name}-right-env-fw"
  address_space = local.vnet_address_space.right_env_fw

  subnets = {
    "mgmt" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.right_env_fw[0], 3, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic_rg1.sg_id["mgmt"]
    },
    "core" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_env_fw[0], 3, 1)]
    },
    "env1" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_env_fw[0], 3, 2)]
    },
    "env2" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_env_fw[0], 3, 3)]
    },
    "RouteServerSubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_env_fw[0], 3, 7)]
    },
  }
}



resource "azurerm_public_ip" "right_env_fw_asr" {
  name                = "${var.name}-right-env-fw-asr"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_route_server" "right_env_fw" {
  name                             = "${var.name}-right-env_fw"
  resource_group_name              = azurerm_resource_group.rg1.name
  location                         = azurerm_resource_group.rg1.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.right_env_fw_asr.id
  subnet_id                        = module.vnet_right_env_fw.subnets["RouteServerSubnet"].id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_route_server_bgp_connection" "right_env_fw-right_env_fw1" {
  name            = "right_env_fw1"
  route_server_id = azurerm_route_server.right_env_fw.id
  peer_asn        = var.asn["right_env_fw1"]
  peer_ip         = local.private_ips.right_env_fw1["eth1_1_ip"]
}



module "right_env_fw1" {
  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name  = "${var.name}-right-env-fw1"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.vnet_right_env_fw.subnets["mgmt"].id
      private_ip_address = local.private_ips.right_env_fw1["mgmt_ip"]
    }
    core = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.vnet_right_env_fw.subnets["core"].id
      private_ip_address = local.private_ips.right_env_fw1["eth1_1_ip"]
    }
    env1 = {
      device_index       = 2
      subnet_id          = module.vnet_right_env_fw.subnets["env1"].id
      private_ip_address = local.private_ips.right_env_fw1["eth1_2_ip"]
    }
    env2 = {
      device_index       = 3
      subnet_id          = module.vnet_right_env_fw.subnets["env2"].id
      private_ip_address = local.private_ips.right_env_fw1["eth1_3_ip"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    local.bootstrap_options["right_env_fw1"],
  )
}


resource "azurerm_virtual_network_peering" "vnet_right_hub-vnet_right_env_fw" {
  name                      = "right-hub--right-env_fw"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = module.vnet_right_hub.vnet.name
  remote_virtual_network_id = module.vnet_right_env_fw.vnet.id
}

resource "azurerm_virtual_network_peering" "vnet_right_env_fw-vnet_right_hub" {
  name                      = "right-env-fw--right-hub"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = module.vnet_right_env_fw.vnet.name
  remote_virtual_network_id = module.vnet_right_hub.vnet.id
  depends_on = [
    azurerm_virtual_network_peering.vnet_right_hub-vnet_right_env_fw
  ]
}


resource "azurerm_route_table" "right_env_fw_core" {
  name                          = "${var.name}-right-env-fw-core"
  resource_group_name           = azurerm_resource_group.rg1.name
  location                      = azurerm_resource_group.rg1.location
}

resource "azurerm_route" "right_hub_env_fw_core" {
  for_each = {
    left = "172.16.0.0/21"
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.rg1.name
  route_table_name       = azurerm_route_table.right_env_fw_core.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.private_ips.right_hub_fw["eth1_1_ip"]
}

resource "azurerm_subnet_route_table_association" "right_env_fw_core" {
  subnet_id      = module.vnet_right_env_fw.subnets["core"].id
  route_table_id = azurerm_route_table.right_env_fw_core.id
}
