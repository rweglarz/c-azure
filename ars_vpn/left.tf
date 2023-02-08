module "vnet_left_hub" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = "${var.name}-left-hub"
  address_space = local.vnet_address_space.left_hub

  subnets = {
    "mgmt" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.left_hub[0], 3, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "data" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.left_hub[0], 3, 1)]
    },
    "RouteServerSubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.left_hub[0], 3, 3)]
    },
    "internet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.left_hub[0], 3, 4)]
    },
    "private" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.left_hub[0], 3, 5)]
    },
  }
}



resource "panos_panorama_template_stack" "azure_left_hub_fw" {
  name         = "azure-ars-left-hub-fw"
  default_vsys = "vsys1"
  templates = [
    module.cfg_left_hub_fw.template_name,
    "vm common",
  ]
  description = "pat:acp"
}

resource "panos_panorama_template_stack" "azure_left_ipsec_fw1" {
  name         = "azure-ars-left-ipsec-fw1"
  default_vsys = "vsys1"
  templates = [
    module.cfg_left_ipsec_fw1.template_name,
    "vm common",
  ]
  description = "pat:acp"
}

resource "panos_panorama_template_stack" "azure_left_ipsec_fw2" {
  name         = "azure-ars-left-ipsec-fw2"
  default_vsys = "vsys1"
  templates = [
    module.cfg_left_ipsec_fw2.template_name,
    "vm common",
  ]
  description = "pat:acp"
}






module "cfg_left_hub_fw" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-ars-left-hub-fw-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.private_ips.left_hub_fw["eth1_1_ip"], local.subnet_prefix_length)]
      zone       = "data"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.private_ips.left_hub_fw["eth1_1_gw"]
    }
  }
  enable_ecmp = false
}


module "left_hub_fw" {
  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name  = "${var.name}-left-hub-fw"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.vnet_left_hub.subnets["mgmt"].id
      private_ip_address = local.private_ips.left_hub_fw["mgmt_ip"]
    }
    data = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.vnet_left_hub.subnets["data"].id
      private_ip_address = local.private_ips.left_hub_fw["eth1_1_ip"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["left_hub_fw"],
  )
}



module "cfg_left_ipsec_fw1" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-ars-left-ipsec-fw1-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.private_ips.left_ipsec_fw1["eth1_1_ip"], local.subnet_prefix_length)]
      zone       = "internet"
    }
    "ethernet1/2" = {
      static_ips = [format("%s/%s", local.private_ips.left_ipsec_fw1["eth1_2_ip"], local.subnet_prefix_length)]
      zone       = "private"
    }
    "tunnel.11" = {
      static_ips = [format("%s/%s", local.private_ips.left_ipsec_fw1["tun11_ip"], 32)]
      zone       = "private"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.private_ips.left_ipsec_fw1["eth1_1_gw"]
    }
    c1 = {
      destination = "169.254.22.1/32"
      interface   = "tunnel.11"
    }
  }
  enable_ecmp = false
}


module "left_ipsec_fw1" {
  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name  = "${var.name}-left-ipsec-fw1"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.vnet_left_hub.subnets["mgmt"].id
      private_ip_address = local.private_ips.left_ipsec_fw1["mgmt_ip"]
    }
    internet = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.vnet_left_hub.subnets["internet"].id
      private_ip_address = local.private_ips.left_ipsec_fw1["eth1_1_ip"]
    }
    private = {
      device_index       = 2
      subnet_id          = module.vnet_left_hub.subnets["private"].id
      private_ip_address = local.private_ips.left_ipsec_fw1["eth1_2_ip"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["left_ipsec_fw1"],
  )
}

module "cfg_left_ipsec_fw2" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-ars-left-ipsec-fw2-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.private_ips.left_ipsec_fw2["eth1_1_ip"], local.subnet_prefix_length)]
      zone       = "internet"
    }
    "ethernet1/2" = {
      static_ips = [format("%s/%s", local.private_ips.left_ipsec_fw2["eth1_2_ip"], local.subnet_prefix_length)]
      zone       = "private"
    }
    "tunnel.11" = {
      static_ips = [format("%s/%s", local.private_ips.left_ipsec_fw2["tun11_ip"], 32)]
      zone       = "private"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.private_ips.left_ipsec_fw2["eth1_1_gw"]
    }
    c2 = {
      destination = "169.254.22.3/32"
      interface   = "tunnel.11"
    }
  }
  enable_ecmp = false
}


module "left_ipsec_fw2" {
  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name  = "${var.name}-left-ipsec-fw2"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.vnet_left_hub.subnets["mgmt"].id
      private_ip_address = local.private_ips.left_ipsec_fw2["mgmt_ip"]
    }
    internet = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.vnet_left_hub.subnets["internet"].id
      private_ip_address = local.private_ips.left_ipsec_fw2["eth1_1_ip"]
    }
    private = {
      device_index       = 2
      subnet_id          = module.vnet_left_hub.subnets["private"].id
      private_ip_address = local.private_ips.left_ipsec_fw2["eth1_2_ip"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["left_ipsec_fw2"],
  )
}



module "tunnel-left_ipsec_fw1-vng_right_c1" {
  source = "../../ce-common/modules/pan_tunnel"

  peers = {
    left = {
      name = "left_ipsec_fw1"
      ip   = local.public_ips["left_ipsec_fw1"][0]
      interface = {
        phys   = "ethernet1/1"
        tunnel = "tunnel.11"
      }
      id = {
        type  = "ipaddr"
        value = local.public_ips["left_ipsec_fw1"][0]
      }
      template = module.cfg_left_ipsec_fw1.template_name
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
      template = module.cfg_left_ipsec_fw1.template_name
      do_not_configure = true
    }
  }
  psk = var.psk
}

module "tunnel-left_ipsec_fw2-vng_right_c2" {
  source = "../../ce-common/modules/pan_tunnel"

  peers = {
    left = {
      name = "left_ipsec_fw2"
      ip   = local.public_ips["left_ipsec_fw2"][0]
      interface = {
        phys   = "ethernet1/1"
        tunnel = "tunnel.11"
      }
      id = {
        type  = "ipaddr"
        value = local.public_ips["left_ipsec_fw2"][0]
      }
      template = module.cfg_left_ipsec_fw2.template_name
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
      template = module.cfg_left_ipsec_fw2.template_name
      do_not_configure = true
    }
  }
  psk = var.psk
}
