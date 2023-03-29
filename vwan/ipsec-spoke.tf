module "ipsec_spoke1" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name          = "${local.dname}-ipsec-spoke1"
  address_space = local.vnet_address_space.ipsec_spoke1

  subnets = {
    "mgmt" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.ipsec_spoke1[0], 4, 0)]
      network_security_group_id = azurerm_network_security_group.rg2_mgmt.id
      associate_nsg             = true
    },
    "internet" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.ipsec_spoke1[0], 4, 1)]
      network_security_group_id = azurerm_network_security_group.rg2_all.id
      associate_nsg             = true
    },
    "private" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.ipsec_spoke1[0], 4, 2)]
    },
  }
}



locals {
  ipsec_spoke1_fw = {
    mgmt_ip   = cidrhost(module.ipsec_spoke1.subnets["mgmt"].address_prefixes[0], 5),
    eth1_1_ip = cidrhost(module.ipsec_spoke1.subnets["internet"].address_prefixes[0], 5),
    eth1_1_gw = cidrhost(module.ipsec_spoke1.subnets["internet"].address_prefixes[0], 1),
    eth1_2_ip = cidrhost(module.ipsec_spoke1.subnets["private"].address_prefixes[0], 5),
    eth1_2_gw = cidrhost(module.ipsec_spoke1.subnets["private"].address_prefixes[0], 1),
  }
}


resource "panos_panorama_template_stack" "azure_vwan_ipsec_spoke1_fw" {
  name         = "azure-vwan-ipsec-spoke1-fw"
  default_vsys = "vsys1"
  templates = [
    module.cfg_ipsec_spoke1_fw.template_name,
    "vm common",
  ]
  description = "pat:acp"
}


module "cfg_ipsec_spoke1_fw" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-vwan-ipsec-spoke1-fw-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips = [format("%s/%s", local.ipsec_spoke1_fw["eth1_1_ip"], local.subnet_prefix_length)]
      zone       = "internet"
    }
    "ethernet1/2" = {
      static_ips = [format("%s/%s", local.ipsec_spoke1_fw["eth1_2_ip"], local.subnet_prefix_length)]
      zone       = "private"
    }
    "tunnel.21" = {
      zone       = "vpn"
      static_ips = [var.peering_address["ipsec_spoke1_fw-tun21"][0]]
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.ipsec_spoke1_fw["eth1_1_gw"]
    }
    prv = {
      destination = module.ipsec_spoke1.vnet.address_space[0]
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.ipsec_spoke1_fw["eth1_2_gw"]
    }
    azure = {
      destination = "172.16.0.0/19"
      interface   = "tunnel.21"
    }
    aws = {
      destination = "172.16.32.0/24"
      interface   = "tunnel.21"
    }
    r169 = {
      destination = "169.254.0.0/16"
      interface   = "tunnel.21"
    }
  }
  enable_ecmp = false
}


module "ipsec_spoke1_fw" {
  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  name  = "${local.dname}-ipsec-spoke1-fw"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.ipsec_spoke1.subnets["mgmt"].id
      private_ip_address = local.ipsec_spoke1_fw["mgmt_ip"]
    }
    internet = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.ipsec_spoke1.subnets["internet"].id
      private_ip_address = local.ipsec_spoke1_fw["eth1_1_ip"]
    }
    private = {
      device_index       = 2
      subnet_id          = module.ipsec_spoke1.subnets["private"].id
      private_ip_address = local.ipsec_spoke1_fw["eth1_2_ip"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["ipsec_spoke1_fw"],
  )
}
