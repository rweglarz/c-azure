module "linux" {
  source = "../modules/linux"
  for_each = {
    dev1  = module.app_vnets["dev_1"].subnets["sprivate"]
    prod1 = module.app_vnets["prod_1"].subnets["sprivate"]
  }

  name                = "${local.dname}-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = each.value.id
  private_ip_address  = cidrhost(each.value.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id.mgmt
  associate_nsg       = true
  size                = "Standard_B2ts_v2"
}
