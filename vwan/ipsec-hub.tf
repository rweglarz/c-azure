module "ipsec_hub1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-ipsec-hub1"
  address_space = local.vnet_address_space.ipsec_hub1

  subnets = {
    "mgmt" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.ipsec_hub1[0], 4, 0)]
      network_security_group_id = azurerm_network_security_group.rg1_mgmt.id
    },
    "internet" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.ipsec_hub1[0], 4, 1)]
      network_security_group_id = azurerm_network_security_group.rg1_all.id
    },
    "private" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.ipsec_hub1[0], 4, 2)]
    },
  }
}



locals {
  ipsec_hub1_fw1 = {
    mgmt_ip   = cidrhost(module.ipsec_hub1.subnets["mgmt"].address_prefixes[0], 5),
    eth1_1_ip = cidrhost(module.ipsec_hub1.subnets["internet"].address_prefixes[0], 5),
    eth1_1_gw = cidrhost(module.ipsec_hub1.subnets["internet"].address_prefixes[0], 1),
    eth1_2_ip = cidrhost(module.ipsec_hub1.subnets["private"].address_prefixes[0], 5),
    eth1_2_gw = cidrhost(module.ipsec_hub1.subnets["private"].address_prefixes[0], 1),
  }
  ipsec_hub1_fw2 = {
    mgmt_ip   = cidrhost(module.ipsec_hub1.subnets["mgmt"].address_prefixes[0], 6),
    eth1_1_ip = cidrhost(module.ipsec_hub1.subnets["internet"].address_prefixes[0], 6),
    eth1_1_gw = cidrhost(module.ipsec_hub1.subnets["internet"].address_prefixes[0], 1),
    eth1_2_ip = cidrhost(module.ipsec_hub1.subnets["private"].address_prefixes[0], 6),
    eth1_2_gw = cidrhost(module.ipsec_hub1.subnets["private"].address_prefixes[0], 1),
  }
}


resource "panos_panorama_template_stack" "azure_vwan_ipsec_hub1_fw1" {
  name         = "azure-vwan-ipsec-hub1-fw1"
  default_vsys = "vsys1"
  templates = [
    module.cfg_ipsec_hub1_fw1.template_name,
    "vm common",
  ]
  description = "pat:acp"
}

resource "panos_panorama_template_stack" "azure_vwan_ipsec_hub1_fw2" {
  name         = "azure-vwan-ipsec-hub1-fw2"
  default_vsys = "vsys1"
  templates = [
    module.cfg_ipsec_hub1_fw2.template_name,
    "vm common",
  ]
  description = "pat:acp"
}





module "cfg_ipsec_hub1_fw1" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-vwan-ipsec-hub1-fw1-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.ipsec_hub1_fw1["eth1_1_ip"], local.subnet_prefix_length)]
      zone       = "internet"
    }
    "ethernet1/2" = {
      static_ips = [format("%s/%s", local.ipsec_hub1_fw1["eth1_2_ip"], local.subnet_prefix_length)]
      zone       = "private"
    }
    "tunnel.21" = {
      zone       = "vpn"
      static_ips = [var.peering_address["ipsec_hub1_fw1-tun21"][0]]
    }
    "tunnel.22" = {
      zone = "vpn"
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.ipsec_hub1_fw1["eth1_1_gw"]
    }
    vnet = {
      destination = module.ipsec_hub1.vnet.address_space[0]
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.ipsec_hub1_fw1["eth1_2_gw"]
    }
    hub1 = {
      destination = azurerm_virtual_hub.hub1.address_prefix
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.ipsec_hub1_fw1["eth1_2_gw"]
    }
    hub2 = {
      destination = azurerm_virtual_hub.hub2.address_prefix
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.ipsec_hub1_fw1["eth1_2_gw"]
    }
    spoke1 = {
      destination = "172.16.34.0/24"
      interface   = "tunnel.21"
    }
    spoke1n = {
      destination = "10.66.66.32/28"
      interface   = "tunnel.21"
    }
  }
  enable_ecmp = false
}

module "cfg_ipsec_hub1_fw2" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-vwan-ipsec-hub1-fw2-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.ipsec_hub1_fw2["eth1_1_ip"], local.subnet_prefix_length)]
      zone       = "internet"
    }
    "ethernet1/2" = {
      static_ips = [format("%s/%s", local.ipsec_hub1_fw2["eth1_2_ip"], local.subnet_prefix_length)]
      zone       = "private"
    }
    "tunnel.21" = {
      zone = "vpn"
    }
    "tunnel.22" = {
      zone       = "vpn"
      static_ips = [var.peering_address["ipsec_hub1_fw2-tun22"][0]]
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.ipsec_hub1_fw2["eth1_1_gw"]
    }
    vnet = {
      destination = module.ipsec_hub1.vnet.address_space[0]
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.ipsec_hub1_fw2["eth1_2_gw"]
    }
    hub1 = {
      destination = azurerm_virtual_hub.hub1.address_prefix
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.ipsec_hub1_fw2["eth1_2_gw"]
    }
    hub2 = {
      destination = azurerm_virtual_hub.hub2.address_prefix
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.ipsec_hub1_fw2["eth1_2_gw"]
    }
    spoke1 = {
      destination = "172.16.34.0/24"
      interface   = "tunnel.22"
    }
    spoke1n = {
      destination = "10.66.66.32/28"
      interface   = "tunnel.22"
    }
  }
  enable_ecmp = false
}






module "ipsec_hub1_fw1" {
  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name  = "${local.dname}-ipsec-hub1-fw1"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.ipsec_hub1.subnets["mgmt"].id
      private_ip_address = local.ipsec_hub1_fw1["mgmt_ip"]
    }
    internet = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.ipsec_hub1.subnets["internet"].id
      private_ip_address = local.ipsec_hub1_fw1["eth1_1_ip"]
    }
    private = {
      device_index       = 2
      subnet_id          = module.ipsec_hub1.subnets["private"].id
      private_ip_address = local.ipsec_hub1_fw1["eth1_2_ip"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["pan_pub"],
    var.bootstrap_options["ipsec_hub1_fw1"],
  )
}

module "ipsec_hub1_fw2" {
  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name  = "${local.dname}-ipsec-hub1-fw2"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.ipsec_hub1.subnets["mgmt"].id
      private_ip_address = local.ipsec_hub1_fw2["mgmt_ip"]
    }
    internet = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.ipsec_hub1.subnets["internet"].id
      private_ip_address = local.ipsec_hub1_fw2["eth1_1_ip"]
    }
    private = {
      device_index       = 2
      subnet_id          = module.ipsec_hub1.subnets["private"].id
      private_ip_address = local.ipsec_hub1_fw2["eth1_2_ip"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["pan_pub"],
    var.bootstrap_options["ipsec_hub1_fw2"],
  )
}




module "tunnel-ipsec_hub1_fw1-ipsec_spoke1_fw" {
  source = "../../ce-common/modules/pan_tunnel"

  peers = {
    left = {
      name = "ipsec_hub1_fw1"
      ip   = local.public_ip["ipsec_hub1_fw1"][0]
      interface = {
        phys   = "ethernet1/1"
        tunnel = "tunnel.21"
      }
      id = {
        #        type  = "ipaddr"
        #        value = local.public_ip["ipsec_hub1_fw1"][0]
        type  = "fqdn"
        value = "vwan-ipsec-hubs.${var.dns_zone_name}"
      }
      enable_tunnel_monitor         = true
      tunnel_monitor_destination_ip = "172.16.34.37"
      #tunnel_monitor_source_ip  = 
      template            = module.cfg_ipsec_hub1_fw1.template_name
      enable_passive_mode = false
    }
    right = {
      name          = "ipsec_spoke1_fw"
      ip            = local.public_ip["ipsec_spoke1_fw"][0]
      peer_ip_type  = "fqdn"
      peer_ip_value = "vwan-ipsec-hubs.${var.dns_zone_name}"
      interface = {
        phys   = "ethernet1/1"
        tunnel = "tunnel.21"
      }
      id = {
        type  = "ipaddr"
        value = local.public_ip["ipsec_spoke1_fw"][0]
      }
      template = module.cfg_ipsec_spoke1_fw.template_name
    }
  }
  psk = var.psk
}

module "tunnel-ipsec_hub1_fw2-ipsec_spoke1_fw" {
  source = "../../ce-common/modules/pan_tunnel"

  peers = {
    left = {
      name = "ipsec_hub1_fw2"
      ip   = local.public_ip["ipsec_hub1_fw2"][0]
      interface = {
        phys   = "ethernet1/1"
        tunnel = "tunnel.22"
      }
      id = {
        #type  = "ipaddr"
        #value = local.public_ip["ipsec_hub1_fw2"][0]
        type  = "fqdn"
        value = "vwan-ipsec-hubs.${var.dns_zone_name}"
      }
      enable_tunnel_monitor         = true
      tunnel_monitor_destination_ip = "172.16.34.37"
      template                      = module.cfg_ipsec_hub1_fw2.template_name
      enable_passive_mode           = false
    }
    right = {
      name          = "ipsec_spoke1_fw"
      ip            = local.public_ip["ipsec_spoke1_fw"][0]
      peer_ip_type  = "fqdn"
      peer_ip_value = "vwan-ipsec-hubs.${var.dns_zone_name}"
      interface = {
        phys   = "ethernet1/1"
        tunnel = "tunnel.21"
      }
      id = {
        type  = "ipaddr"
        value = local.public_ip["ipsec_spoke1_fw"][0]
      }
      template         = module.cfg_ipsec_spoke1_fw.template_name
      do_not_configure = true
    }
  }
  psk = var.psk
}
