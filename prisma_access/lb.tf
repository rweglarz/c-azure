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
    name                 = "ilb-ext"
    public_ip_address_id = azurerm_public_ip.lb_ext.id
  }
}

resource "azurerm_lb" "fw_int" {
  name                = "${var.name}-lb-int"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "inbound"
    subnet_id                     = module.vnet_sec.subnets["internet"].id
    private_ip_address            = cidrhost(module.vnet_sec.subnets["internet"].address_prefixes[0], 5)
    private_ip_address_allocation = "Static"
  }

  frontend_ip_configuration {
    name                          = "oew"
    subnet_id                     = module.vnet_sec.subnets["internal"].id
    private_ip_address            = cidrhost(module.vnet_sec.subnets["internal"].address_prefixes[0], 5)
    private_ip_address_allocation = "Static"
  }
}



resource "azurerm_lb_probe" "fw_ext" {
  name            = "tcp-probe"
  loadbalancer_id = azurerm_lb.fw_ext.id
  protocol        = "Tcp"
  port            = 443
}

resource "azurerm_lb_probe" "fw_int" {
  name            = "tcp-probe"
  loadbalancer_id = azurerm_lb.fw_int.id
  protocol        = "Tcp"
  port            = 443
}



resource "azurerm_lb_rule" "fw_ext-80" {
  name = "ext-80"

  loadbalancer_id                = azurerm_lb.fw_ext.id
  frontend_ip_configuration_name = "ilb-ext"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ext.id]
  probe_id                       = azurerm_lb_probe.fw_ext.id

  disable_outbound_snat = true

  protocol      = "Tcp"
  frontend_port = 80
  backend_port  = 80
}

resource "azurerm_lb_backend_address_pool" "ext" {
  name            = "${var.name}-ext"
  loadbalancer_id = azurerm_lb.fw_ext.id
}

resource "azurerm_lb_backend_address_pool" "inbound" {
  name            = "${var.name}-inbound"
  loadbalancer_id = azurerm_lb.fw_int.id
}

resource "azurerm_lb_backend_address_pool" "oew" {
  name            = "${var.name}-oew"
  loadbalancer_id = azurerm_lb.fw_int.id
}


resource "azurerm_lb_rule" "inbound" {
  name = "inbound"

  loadbalancer_id                = azurerm_lb.fw_int.id
  frontend_ip_configuration_name = "inbound"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.inbound.id]
  probe_id                       = azurerm_lb_probe.fw_int.id

  disable_outbound_snat = true

  protocol      = "All"
  frontend_port = 0
  backend_port  = 0
}

resource "azurerm_lb_rule" "oew" {
  name = "oew"

  loadbalancer_id                = azurerm_lb.fw_int.id
  frontend_ip_configuration_name = "oew"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.oew.id]
  probe_id                       = azurerm_lb_probe.fw_int.id

  disable_outbound_snat = true

  protocol      = "All"
  frontend_port = 0
  backend_port  = 0
}


output "lb_ext_ip" {
  value = azurerm_public_ip.lb_ext.ip_address
}
