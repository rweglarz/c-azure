module "fw" {
  count = var.fw_count
  source = "../modules/vmseries"

  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.dname}-fw${count.index}"
  username            = var.username
  password            = var.password
  size                = "Standard_D4_v2"
  panos = "10.1.12"

  interfaces = {
    mgmt = {
      device_index         = 0
      name                 = "${local.dname}-fw${count.index}-mgmt"
      subnet_id            = module.vnet_transit.subnets.mgmt.id
      private_ip_address   = cidrhost(module.vnet_transit.subnets.mgmt.address_prefixes[0], 6 + count.index)
      public_ip            = false
    }
    public = {
      device_index         = 1
      name                 = "${local.dname}-fw${count.index}-public"
      subnet_id            = module.vnet_transit.subnets.public.id
      private_ip_address   = cidrhost(module.vnet_transit.subnets.public.address_prefixes[0], 6 + count.index)
      enable_ip_forwarding = true
    }
    private = {
      device_index         = 2
      name                 = "${local.dname}-fw${count.index}-private"
      subnet_id            = module.vnet_transit.subnets.private.id
      private_ip_address   = cidrhost(module.vnet_transit.subnets.private.address_prefixes[0], 6 + count.index)
      enable_ip_forwarding = true
      load_balancer_backend_address_pool_id = module.fw_ilb.backend_address_pool_ids.obew
    }
    tosdwan1 = {
      device_index         = 3
      name                 = "${local.dname}-fw${count.index}-tosdwan1"
      subnet_id            = module.vnet_transit.subnets.tosdwan1.id
      private_ip_address   = cidrhost(module.vnet_transit.subnets.tosdwan1.address_prefixes[0], 6 + count.index)
      enable_ip_forwarding = true
    }
    tosdwan2 = {
      device_index         = 4
      name                 = "${local.dname}-fw${count.index}-tosdwan2"
      subnet_id            = module.vnet_transit.subnets.tosdwan2.id
      private_ip_address   = cidrhost(module.vnet_transit.subnets.tosdwan2.address_prefixes[0], 6 + count.index)
      enable_ip_forwarding = true
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options,
    {
       tplname = panos_panorama_template_stack.this[count.index].name,
       vm-auth-key = panos_vm_auth_key.this.auth_key,
    }
  )
}

module "fw_ilb" {
  source = "../modules/ilb"

  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.dname}-fw-ilb"
  private_ip_address  = local.private_ip.fw_ilb
  subnet_id           = module.vnet_transit.subnets.private.id
}
