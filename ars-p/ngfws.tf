locals {
  bootstrap_options = merge(
    { 
      for k,v in local.transit_fws: "transit_${k}" => {
        tplname = panos_panorama_template_stack.transit_fw[k].name
      }
    },
    {
      onprem_fw = {
        tplname = panos_panorama_template_stack.onprem_fw.name
      }
    }

  )
}

module "transit_fw" {
  for_each = local.transit_fws
  source              = "../modules/vmseries"

  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name  = "${var.name}-transit-${each.key}"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.vnet_transit.subnets["mgmt"].id
      private_ip_address = local.transit_fws[each.key]["mgmt_ip"]
    }
    public = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.vnet_transit.subnets["public"].id
      private_ip_address = local.transit_fws[each.key]["eth1_1_ip"]
    }
    private = {
      device_index       = 2
      public_ip          = false
      subnet_id          = module.vnet_transit.subnets["private"].id
      private_ip_address = local.transit_fws[each.key]["eth1_2_ip"]

      load_balancer_backend_address_pool_id = module.ilb_transit.backend_address_pool_ids["obew"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    local.bootstrap_options["transit_${each.key}"],
  )
}



module "onprem_fw" {
  source              = "../modules/vmseries"

  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name  = "${var.name}-onprem-fw"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.vnet_onprem.subnets["mgmt"].id
      private_ip_address = local.onprem_fw["mgmt_ip"]
    }
    isp1 = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.vnet_onprem.subnets["isp1"].id
      private_ip_address = local.onprem_fw["eth1_1_ip"]
    }
    isp2 = {
      device_index       = 2
      public_ip          = true
      subnet_id          = module.vnet_onprem.subnets["isp2"].id
      private_ip_address = local.onprem_fw["eth1_2_ip"]
    }
    private = {
      device_index       = 3
      public_ip          = false
      subnet_id          = module.vnet_onprem.subnets["private"].id
      private_ip_address = local.onprem_fw["eth1_3_ip"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    local.bootstrap_options["onprem_fw"],
  )
}
