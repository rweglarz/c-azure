module "vnet_right_hub" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = "${var.name}-right-hub"
  address_space = local.vnet_address_space.right_hub

  subnets = {
    "mgmt" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.right_hub[0], 3, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "data" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_hub[0], 3, 1)]
    },
    "GatewaySubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_hub[0], 3, 2)]
    },
    "RouteServerSubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_hub[0], 3, 3)]
    },
  }
}




resource "panos_panorama_template_stack" "azure_right_hub_fw" {
  name         = "azure-ars-right-hub-fw"
  default_vsys = "vsys1"
  templates = [
    module.cfg_right_hub_fw.template_name,
    "vm common",
  ]
  description = "pat:acp"
}


module "cfg_right_hub_fw" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-ars-right-hub-fw-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.private_ips.right_hub_fw["eth1_1_ip"], local.subnet_prefix_length)]
      zone       = "data"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.private_ips.right_hub_fw["eth1_1_gw"]
    }
  }
  enable_ecmp = false
}


module "right_hub_fw" {
  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name  = "${var.name}-right-hub-fw"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.vnet_right_hub.subnets["mgmt"].id
      private_ip_address = local.private_ips.right_hub_fw["mgmt_ip"]
    }
    data = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.vnet_right_hub.subnets["data"].id
      private_ip_address = local.private_ips.right_hub_fw["eth1_1_ip"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["right_hub_fw"],
  )
}

resource "azurerm_public_ip" "right_hub_asr" {
  name                = "${var.name}-right-hub-asr"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_route_server" "right_hub" {
  name                             = "${var.name}-right-hub"
  resource_group_name              = azurerm_resource_group.this.name
  location                         = azurerm_resource_group.this.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.right_hub_asr.id
  subnet_id                        = module.vnet_right_hub.subnets["RouteServerSubnet"].id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_route_server_bgp_connection" "right_hub-right_env_fw1" {
  name            = "right_env_fw1"
  route_server_id = azurerm_route_server.right_hub.id
  peer_asn        = var.asn["right_env_fw1"]
  peer_ip         = local.private_ips.right_env_fw1["eth1_1_ip"]
}


resource "azurerm_route_table" "right_hub_gateway_subnet" {
  name                          = "${var.name}-right-hub-gateway-subnet"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  disable_bgp_route_propagation = true
}

resource "azurerm_route" "right_hub_gateway_subnet" {
  for_each = {
    envs = "10.0.0.0/8"
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.this.name
  route_table_name       = azurerm_route_table.right_hub_gateway_subnet.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.private_ips.right_hub_fw["eth1_1_ip"]
}

resource "azurerm_subnet_route_table_association" "right_hub_gateway_subnet" {
  subnet_id      = module.vnet_right_hub.subnets["GatewaySubnet"].id
  route_table_id = azurerm_route_table.right_hub_gateway_subnet.id
}
