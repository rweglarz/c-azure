module "linux_srv" {
  for_each = merge(
    { for k,v in module.vnet_app: k=> v.subnets["workloads"] },
    { 
      onprem = module.vnet_onprem.subnets["workloads"]
    },
  )
  source = "../modules/linux"

  name                = "${var.name}-srv-${each.key}"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  subnet_id           = each.value.id
  private_ip_address  = cidrhost(each.value.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.rg1.public_key
}
