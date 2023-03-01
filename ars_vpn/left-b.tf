module "vnet_left_b_hub" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name          = "${var.name}-left-b-hub"
  address_space = local.vnet_address_space.left_b_hub

  subnets = {
    "mgmt" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.left_b_hub[0], 3, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic_rg2.sg_id["mgmt"]
    },
    "data" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.left_b_hub[0], 3, 1)]
    },
    "RouteServerSubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.left_b_hub[0], 3, 3)]
    },
    "internet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.left_b_hub[0], 3, 4)]
    },
    "private" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.left_b_hub[0], 3, 5)]
    },
  }
}

module "ilb_left_b_hub" {
  source = "../modules/ilb"

  name                = "${var.name}-left-b-hub"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  subnet_id           = module.vnet_left_b_hub.subnets["data"].id
  private_ip_address  = local.private_ips.left_b_hub_ilb["obew"]
}


resource "panos_panorama_template_stack" "azure_left_b_hub_fw" {
  name         = "azure-ars-left-b-hub-fw"
  default_vsys = "vsys1"
  templates = [
    module.cfg_left_b_hub_fw.template_name,
    "vm common",
  ]
  description = "pat:acp"
}

resource "panos_panorama_template_stack" "azure_left_b_ipsec_fw1" {
  name         = "azure-ars-left-b-ipsec-fw1"
  default_vsys = "vsys1"
  templates = [
    module.cfg_left_b_ipsec_fw1.template_name,
    "vm common",
  ]
  description = "pat:acp"
}

resource "panos_panorama_template_stack" "azure_left_b_ipsec_fw2" {
  name         = "azure-ars-left-b-ipsec-fw2"
  default_vsys = "vsys1"
  templates = [
    module.cfg_left_b_ipsec_fw2.template_name,
    "vm common",
  ]
  description = "pat:acp"
}






module "cfg_left_b_hub_fw" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-ars-left-b-hub-fw-t"

  interfaces = {
    "ethernet1/1" = {
      enable_dhcp               = true
      create_dhcp_default_route = true

      zone               = "data"
      management_profile = "hc-azure"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.private_ips.left_b_hub_fw["eth1_1_gw"]
    }
  }
  enable_ecmp = false
}


module "left_b_hub_fw" {
  for_each = var.left_b_hub_fws

  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name  = "${var.name}-left-b-hub-fw-${each.key}"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index = 0
      public_ip    = true
      subnet_id    = module.vnet_left_b_hub.subnets["mgmt"].id
    }
    data = {
      device_index = 1
      public_ip    = true
      subnet_id    = module.vnet_left_b_hub.subnets["data"].id

      load_balancer_backend_address_pool_id = module.ilb_left_b_hub.backend_address_pool_ids["obew"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    local.bootstrap_options["left_b_hub_fw"],
  )
}



module "cfg_left_b_ipsec_fw1" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-ars-left-b-ipsec-fw1-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.private_ips.left_b_ipsec_fw1["eth1_1_ip"], local.subnet_prefix_length)]
      zone       = "internet"
    }
    "ethernet1/2" = {
      static_ips = [format("%s/%s", local.private_ips.left_b_ipsec_fw1["eth1_2_ip"], local.subnet_prefix_length)]
      zone       = "private"
    }
    "tunnel.11" = {
      static_ips = [format("%s/%s", local.private_ips.left_b_ipsec_fw1["tun11_ip"], 32)]
      zone       = "private"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.private_ips.left_b_ipsec_fw1["eth1_1_gw"]
    }
    left-b-hub = {
      destination = module.vnet_left_b_hub.vnet.address_space[0]
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.private_ips.left_b_ipsec_fw1["eth1_2_gw"]
    }
    c1 = {
      destination = "169.254.22.1/32"
      interface   = "tunnel.11"
    }
  }
  enable_ecmp = false
}


module "left_b_ipsec_fw1" {
  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name  = "${var.name}-left-b-ipsec-fw1"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.vnet_left_b_hub.subnets["mgmt"].id
      private_ip_address = local.private_ips.left_b_ipsec_fw1["mgmt_ip"]
    }
    internet = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.vnet_left_b_hub.subnets["internet"].id
      private_ip_address = local.private_ips.left_b_ipsec_fw1["eth1_1_ip"]
    }
    private = {
      device_index       = 2
      subnet_id          = module.vnet_left_b_hub.subnets["private"].id
      private_ip_address = local.private_ips.left_b_ipsec_fw1["eth1_2_ip"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    local.bootstrap_options["left_b_ipsec_fw1"],
  )
}

module "cfg_left_b_ipsec_fw2" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-ars-left-b-ipsec-fw2-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.private_ips.left_b_ipsec_fw2["eth1_1_ip"], local.subnet_prefix_length)]
      zone       = "internet"
    }
    "ethernet1/2" = {
      static_ips = [format("%s/%s", local.private_ips.left_b_ipsec_fw2["eth1_2_ip"], local.subnet_prefix_length)]
      zone       = "private"
    }
    "tunnel.11" = {
      static_ips = [format("%s/%s", local.private_ips.left_b_ipsec_fw2["tun11_ip"], 32)]
      zone       = "private"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.private_ips.left_b_ipsec_fw2["eth1_1_gw"]
    }
    left-b-hub = {
      destination = module.vnet_left_b_hub.vnet.address_space[0]
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.private_ips.left_b_ipsec_fw2["eth1_2_gw"]
    }
    c2 = {
      destination = "169.254.22.3/32"
      interface   = "tunnel.11"
    }
  }
  enable_ecmp = false
}


module "left_b_ipsec_fw2" {
  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name  = "${var.name}-left-b-ipsec-fw2"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.vnet_left_b_hub.subnets["mgmt"].id
      private_ip_address = local.private_ips.left_b_ipsec_fw2["mgmt_ip"]
    }
    internet = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.vnet_left_b_hub.subnets["internet"].id
      private_ip_address = local.private_ips.left_b_ipsec_fw2["eth1_1_ip"]
    }
    private = {
      device_index       = 2
      subnet_id          = module.vnet_left_b_hub.subnets["private"].id
      private_ip_address = local.private_ips.left_b_ipsec_fw2["eth1_2_ip"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    local.bootstrap_options["left_b_ipsec_fw2"],
  )
}



module "tunnel-left_b_ipsec_fw1-vng_right_c1" {
  source = "../../ce-common/modules/pan_tunnel"

  peers = {
    left = {
      name = "left_b_ipsec_fw1"
      ip   = local.public_ips["left_b_ipsec_fw1"][0]
      interface = {
        phys   = "ethernet1/1"
        tunnel = "tunnel.11"
      }
      id = {
        type  = "ipaddr"
        value = local.public_ips["left_b_ipsec_fw1"][0]
      }
      template = module.cfg_left_b_ipsec_fw1.template_name
    }
    right = {
      name = "vng_right_c1"
      ip   = local.public_ips["right_vng"][0]
      interface = {
        phys   = "ethernet1/1"
        tunnel = "tunnel.11"
      }
      id = {
        type  = "ipaddr"
        value = local.public_ips["right_vng"][0]
      }
      template         = module.cfg_left_b_ipsec_fw1.template_name
      do_not_configure = true
    }
  }
  psk = var.psk
}

module "tunnel-left_b_ipsec_fw2-vng_right_c2" {
  source = "../../ce-common/modules/pan_tunnel"

  peers = {
    left = {
      name = "left_b_ipsec_fw2"
      ip   = local.public_ips["left_b_ipsec_fw2"][0]
      interface = {
        phys   = "ethernet1/1"
        tunnel = "tunnel.11"
      }
      id = {
        type  = "ipaddr"
        value = local.public_ips["left_b_ipsec_fw2"][0]
      }
      template = module.cfg_left_b_ipsec_fw2.template_name
    }
    right = {
      name = "vng_right_c2"
      ip   = local.public_ips["right_vng"][0]
      interface = {
        phys   = "ethernet1/1"
        tunnel = "tunnel.11"
      }
      id = {
        type  = "ipaddr"
        value = local.public_ips["right_vng"][0]
      }
      template         = module.cfg_left_b_ipsec_fw2.template_name
      do_not_configure = true
    }
  }
  psk = var.psk
}


resource "azurerm_public_ip" "left_b_hub_asr" {
  name                = "${var.name}-left-b-hub-asr"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_route_server" "left_b_hub" {
  name                             = "${var.name}-left-b-hub"
  resource_group_name              = azurerm_resource_group.rg2.name
  location                         = azurerm_resource_group.rg2.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.left_b_hub_asr.id
  subnet_id                        = module.vnet_left_b_hub.subnets["RouteServerSubnet"].id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_route_server_bgp_connection" "left_b_hub-left_b_ipsec_fw1" {
  name            = "left_b_ipsec_fw1"
  route_server_id = azurerm_route_server.left_b_hub.id
  peer_asn        = var.asn["left_b_ipsec_fw1"]
  peer_ip         = local.private_ips.left_b_ipsec_fw1["eth1_2_ip"]
}

resource "azurerm_route_server_bgp_connection" "left_b_hub-left_b_ipsec_fw2" {
  name            = "left_b_ipsec_fw2"
  route_server_id = azurerm_route_server.left_b_hub.id
  peer_asn        = var.asn["left_b_ipsec_fw2"]
  peer_ip         = local.private_ips.left_b_ipsec_fw2["eth1_2_ip"]
}



resource "azurerm_route_table" "left_b_hub_private" {
  name                          = "${var.name}-left-b-hub-private"
  resource_group_name           = azurerm_resource_group.rg2.name
  location                      = azurerm_resource_group.rg2.location
  disable_bgp_route_propagation = true
}

resource "azurerm_route" "left_b_hub_private" {
  for_each = {
    srv1 = local.vnet_address_space["left_b_srv1"][0],
    srv2 = local.vnet_address_space["left_b_srv2"][0],
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.rg2.name
  route_table_name       = azurerm_route_table.left_b_hub_private.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.private_ips.left_b_hub_ilb["obew"]
}

resource "azurerm_subnet_route_table_association" "left_b_hub_private" {
  subnet_id      = module.vnet_left_b_hub.subnets["private"].id
  route_table_id = azurerm_route_table.left_b_hub_private.id
}
