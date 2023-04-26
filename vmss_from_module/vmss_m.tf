module "vmss" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules//modules/vmss"

  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  name_prefix             = var.name
  password                = var.password #default username panadmin
  subnet_mgmt             = module.vnet_sec.subnets["mgmt"]
  subnet_private          = module.vnet_sec.subnets["private"]
  subnet_public           = module.vnet_sec.subnets["public"]
  create_mgmt_pip         = false
  private_backend_pool_id = azurerm_lb_backend_address_pool.fw_int.id
  public_backend_pool_id  = azurerm_lb_backend_address_pool.fw_ext.id
  bootstrap_options = join(",", compact(concat(
    [for k, v in var.bootstrap_options : "${k}=${v}"],
  )))
  img_sku     = "byol"
  img_version = "10.1.9" #otherwise it is 9.1.3
  autoscale_metrics = {
    panSessionActive = {
      scaleout_threshold = 500
      scalein_threshold  = 100
    }
  }
}


output "metric_key" {
  value     = module.vmss.metrics_instrumentation_key
  sensitive = true
}
