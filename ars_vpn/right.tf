module "vnet_right_hub" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = "${var.name}-right-hub"
  address_space = local.vnet_address_space.right_hub

  subnets = {
    "mgmt" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.right_hub[0], 4, 0)]
      attach_nsg                = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "data" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_hub[0], 4, 1)]
    },
    "GatewaySubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_hub[0], 4, 2)]
    },
    "RouteServerSubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_hub[0], 4, 3)]
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
