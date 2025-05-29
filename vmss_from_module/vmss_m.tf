resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name}-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "this" {
  name                = "${var.name}-app-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.this.id

  application_type    = "other"
}

output "la_instrumentation_key" {
  value     = azurerm_application_insights.this.instrumentation_key
  sensitive = true
}

locals {
  bootstrap_options = {
    byol = merge(
      var.bootstrap_options_common,
      var.bootstrap_options_byol,
      {
        tplname     = panos_panorama_template_stack.this.name,
        vm-auth-key = panos_vm_auth_key.this.auth_key,
      }
    )
    payg = merge(
      var.bootstrap_options_common,
      var.bootstrap_options_payg,
      {
        tplname     = panos_panorama_template_stack.this.name,
        vm-auth-key = panos_vm_auth_key.this.auth_key,
      }
    )
  }
}



module "vmss_fws" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-swfw-modules//modules/vmss?ref=v3.3.7"
  for_each = var.fw_sets

  name                = "${var.name}-${each.key}"
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
      [for k, v in local.bootstrap_options[each.value.bootstrap_set] : "${k}=${v}"],
    )))
  }

  image = {
    sku     = each.value.sku
    version = each.value.panos_version
  }

  autoscaling_configuration = {
    application_insights_id = azurerm_application_insights.this.id
    default_count           = 0
  }
  autoscaling_profiles      = each.value.autoscaling_profiles
}
