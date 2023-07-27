resource "azurerm_application_insights" "vmss" {
  name                = "${var.name}-app-insights-vmss"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "other"
}


module "vmss" {
  name = var.name
  source = "github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules//modules/vmss?ref=v1.0.3"

  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  disable_password_authentication = false
  password                = var.password #default username panadmin
  interfaces = [
    {
      name       = "mgmt"
      subnet_id  =  module.vnet_sec.subnets["mgmt"].id
      create_pip = false
      lb_backend_pool_ids = []
      appgw_backend_pool_ids = []
    },
    {
      name                = "public"
      subnet_id           =  module.vnet_sec.subnets["public"].id
      create_pip = false
      lb_backend_pool_ids = [
        azurerm_lb_backend_address_pool.fw_ext.id
      ]
      appgw_backend_pool_ids = []
    },
    {
      name      = "private"
      subnet_id =  module.vnet_sec.subnets["private"].id
      create_pip = false
      lb_backend_pool_ids = [
        azurerm_lb_backend_address_pool.fw_int.id
      ]
      appgw_backend_pool_ids = []
    },
    {
      name      = "gwlb"
      subnet_id =  module.vnet_sec.subnets["gwlb"].id
      create_pip = false
      lb_backend_pool_ids = [
        azurerm_lb_backend_address_pool.fw_gwlb.id
      ]
      appgw_backend_pool_ids = []
    },
  ]
  bootstrap_options = join(",", compact(concat(
    [for k, v in var.bootstrap_options : "${k}=${v}"],
  )))

  img_sku     = "byol"
  img_version = "10.1.9" #otherwise it is 10.1.0

  application_insights_id = azurerm_application_insights.vmss.id
  autoscale_metrics = {
    panSessionActive = {
      scaleout_threshold = 500
      scalein_threshold  = 100
    }
  }

  depends_on = [
    azurerm_subnet_nat_gateway_association.this,
  ]
}


# output "metric_key" {
#   value     = module.vmss.metrics_instrumentation_key
#   sensitive = true
# }

