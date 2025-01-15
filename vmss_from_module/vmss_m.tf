resource "azurerm_application_insights" "fw" {
  name                = "${var.name}-app-insights-fw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "other"
}


locals {
  bootstrap_options_byol = merge(
    var.bootstrap_options_common,
    var.bootstrap_options_byol,
    {
      tplname     = panos_panorama_template_stack.this.name,
      vm-auth-key = panos_vm_auth_key.this.auth_key,
    }
  )
}



module "vmss_byol" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-swfw-modules//modules/vmss?ref=v3.2.1"
  #source = "PaloAltoNetworks/swfw-modules/azurerm//modules/vmss"
  #version = "3.0.2"

  name                = "${var.name}-fw-byol"
  region              = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  authentication = {
    username                        = "panadmin"
    password                        = var.password
    disable_password_authentication = false
  }

  interfaces = [
    {
      name       = "mgmt"
      subnet_id  =  module.vnet_sec.subnets["mgmt"].id
    },
    {
      name                = "public"
      subnet_id           =  module.vnet_sec.subnets["public"].id
      lb_backend_pool_ids = [
        module.slb_fw_ext.backend_pool_id
      ]
      appgw_backend_pool_ids = [
        one([for i in module.appgw1.backend_address_pools: i.id if strcontains(i.name, "dummy")]),
        one([for i in module.appgw2.backend_address_pools: i.id if strcontains(i.name, "dummy")]),
      ]
    },
    {
      name       = "private"
      subnet_id  =  module.vnet_sec.subnets["private"].id
      lb_backend_pool_ids = [
        module.slb_fw_int.backend_pool_id
      ]
      appgw_backend_pool_ids = []
    },
  ]

  virtual_machine_scale_set = {
    size  = "Standard_D3_v2"
    zones = [1,2,3]

    bootstrap_options = join(";", compact(concat(
      [for k, v in local.bootstrap_options_byol : "${k}=${v}"],
    )))
  }

  image = {
    sku     = "byol"
    version = var.panos_version
  }

  autoscaling_configuration = {
    application_insights_id = azurerm_application_insights.fw.id
    default_count           = var.byol_count
  }
  autoscaling_profiles      = [
    {
      name          = "default"
      default_count = var.byol_count
      minimum_count = var.byol_count
      maximum_count = var.byol_count
    }
  ]
}
