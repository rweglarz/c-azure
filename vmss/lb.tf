locals {
  lbsp = {
    public = {
      subnet   = module.vnet_sec.subnets.public
      backends = [azurerm_lb_backend_address_pool.public.id],
    }
    private = {
      subnet   = module.vnet_sec.subnets.private
      backends = [azurerm_lb_backend_address_pool.private.id]
    }
    dmz = {
      subnet   = module.vnet_sec.subnets.dmz
      backends = [azurerm_lb_backend_address_pool.dmz.id],
    }
  }
  lb_fe = { for fe in azurerm_lb.fw_int.frontend_ip_configuration: fe.name => fe }
}



resource "azurerm_public_ip" "lb_ext" {
  name                = "${var.name}-lb-ext"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}



resource "azurerm_lb" "fw_ext" {
  name                = "${var.name}-lb-ext"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "lb-ext"
    public_ip_address_id = azurerm_public_ip.lb_ext.id
  }
}

resource "azurerm_lb" "fw_int" {
  name                = "${var.name}-lb-int"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "private"
    subnet_id                     = module.vnet_sec.subnets.private.id
    private_ip_address            = cidrhost(module.vnet_sec.subnets.private.address_prefixes[0], 5)
    private_ip_address_allocation = "Static"
  }

  frontend_ip_configuration {
    name                          = "dmz"
    subnet_id                     = module.vnet_sec.subnets.dmz.id
    private_ip_address            = cidrhost(module.vnet_sec.subnets.dmz.address_prefixes[0], 5)
    private_ip_address_allocation = "Static"
  }
}



resource "azurerm_lb_probe" "fw_ext" {
  name            = "tcp-probe"
  loadbalancer_id = azurerm_lb.fw_ext.id
  protocol        = "Tcp"
  port            = 54321
}

resource "azurerm_lb_probe" "fw_int" {
  name            = "tcp-probe"
  loadbalancer_id = azurerm_lb.fw_int.id
  protocol        = "Tcp"
  port            = 54321
}



resource "azurerm_lb_rule" "fw_ext-80" {
  name = "ext-80"

  loadbalancer_id                = azurerm_lb.fw_ext.id
  frontend_ip_configuration_name = "lb-ext"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.public.id]
  probe_id                       = azurerm_lb_probe.fw_ext.id

  disable_outbound_snat = true

  protocol      = "Tcp"
  frontend_port = 80
  backend_port  = 80
}

resource "azurerm_lb_rule" "ext-22" {
  name = "ext-22"

  loadbalancer_id                = azurerm_lb.fw_ext.id
  frontend_ip_configuration_name = "lb-ext"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.public.id]
  probe_id                       = azurerm_lb_probe.fw_ext.id

  disable_outbound_snat = true

  protocol            = "Tcp"
  frontend_port       = 22
  backend_port        = 22
  floating_ip_enabled = true
}

resource "azurerm_lb_backend_address_pool" "public" {
  name            = "${var.name}-public"
  loadbalancer_id = azurerm_lb.fw_ext.id
}

resource "azurerm_lb_backend_address_pool" "private" {
  name            = "${var.name}-private"
  loadbalancer_id = azurerm_lb.fw_int.id
}

resource "azurerm_lb_backend_address_pool" "dmz" {
  name            = "${var.name}-dmz"
  loadbalancer_id = azurerm_lb.fw_int.id
}


resource "azurerm_lb_rule" "private" {
  name = "private"

  loadbalancer_id                = azurerm_lb.fw_int.id
  frontend_ip_configuration_name = "private"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.private.id]
  probe_id                       = azurerm_lb_probe.fw_int.id

  disable_outbound_snat = true

  protocol      = "All"
  frontend_port = 0
  backend_port  = 0
}

resource "azurerm_lb_rule" "dmz" {
  name = "dmz"

  loadbalancer_id                = azurerm_lb.fw_int.id
  frontend_ip_configuration_name = "dmz"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.dmz.id]
  probe_id                       = azurerm_lb_probe.fw_int.id

  disable_outbound_snat = true

  protocol      = "All"
  frontend_port = 0
  backend_port  = 0
}



output "lb_ext_ip" {
  value = azurerm_public_ip.lb_ext.ip_address
}
