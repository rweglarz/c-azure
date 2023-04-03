module "vmss" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-vmseries-modules//modules/vmss"

  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  name_prefix             = var.name
  password                = var.password #default username panadmin
  subnet_mgmt             = module.vnet_sec.subnets["mgmt"]
  subnet_public           = module.vnet_sec.subnets["internet"]
  subnet_private          = module.vnet_sec.subnets["internal"]
  create_mgmt_pip         = false
  public_backend_pool_id  = azurerm_lb_backend_address_pool.ext.id
  private_backend_pool_id = azurerm_lb_backend_address_pool.oew.id
  bootstrap_options = join(",", compact(concat(
    [for k, v in var.bootstrap_options["common"] : "${k}=${v}"],
    [for k, v in var.bootstrap_options["fw"] : "${k}=${v}"],
  )))
  img_sku     = "byol"
  img_version = "10.1.9"
}
