resource "azurerm_public_ip" "lb_ext" {
  name                = "PublicIPForLB"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}


resource "azurerm_lb" "fw-ext" {
  name                = "${var.name}-lb-ext"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "ilb-ext"
    public_ip_address_id = azurerm_public_ip.lb_ext.id
  }
}
resource "azurerm_lb" "fw-int" {
  name                = "${var.name}-lb-int"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "ilb-srv-a"
    subnet_id                     = azurerm_subnet.data[1].id
    private_ip_address            = cidrhost(azurerm_subnet.data[1].address_prefixes[0], 5)
    private_ip_address_allocation = "Static"
  }
  frontend_ip_configuration {
    name                          = "ilb-srv-b"
    subnet_id                     = azurerm_subnet.data[2].id
    private_ip_address            = cidrhost(azurerm_subnet.data[2].address_prefixes[0], 5)
    private_ip_address_allocation = "Static"
  }
}


resource "azurerm_lb_probe" "fw-ext" {
  name            = "tcp-probe"
  loadbalancer_id = azurerm_lb.fw-ext.id
  protocol        = "Tcp"
  port            = 443
}
resource "azurerm_lb_probe" "fw-int" {
  name            = "tcp-probe"
  loadbalancer_id = azurerm_lb.fw-int.id
  protocol        = "Tcp"
  port            = 443
}


resource "azurerm_lb_rule" "ext" {
  name = "${var.name}-lb-r-ext"

  loadbalancer_id                = azurerm_lb.fw-ext.id
  frontend_ip_configuration_name = "ilb-ext"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ext.id]
  probe_id                       = azurerm_lb_probe.fw-ext.id

  disable_outbound_snat = true

  protocol      = "Tcp"
  frontend_port = 80
  backend_port  = 80
}
resource "azurerm_lb_backend_address_pool" "ext" {
  name            = "${var.name}-ext"
  loadbalancer_id = azurerm_lb.fw-ext.id
}


resource "azurerm_lb_rule" "srv-a" {
  name = "${var.name}-lb-r-srv-a"

  loadbalancer_id                = azurerm_lb.fw-int.id
  frontend_ip_configuration_name = "ilb-srv-a"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.srv-a.id]
  probe_id                       = azurerm_lb_probe.fw-int.id

  disable_outbound_snat = true

  protocol      = "All"
  frontend_port = 0
  backend_port  = 0
}
resource "azurerm_lb_rule" "srv-b" {
  name = "${var.name}-lb-r-srv-b"

  loadbalancer_id                = azurerm_lb.fw-int.id
  frontend_ip_configuration_name = "ilb-srv-b"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.srv-b.id]
  probe_id                       = azurerm_lb_probe.fw-int.id

  disable_outbound_snat = true

  protocol      = "All"
  frontend_port = 0
  backend_port  = 0
}

resource "azurerm_lb_backend_address_pool" "srv-a" {
  name            = "${var.name}-srv-a"
  loadbalancer_id = azurerm_lb.fw-int.id
}
resource "azurerm_lb_backend_address_pool" "srv-b" {
  name            = "${var.name}-srv-b"
  loadbalancer_id = azurerm_lb.fw-int.id
}

locals {
  lbsp = [
    azurerm_lb_backend_address_pool.ext.id,
    azurerm_lb_backend_address_pool.srv-a.id,
    azurerm_lb_backend_address_pool.srv-b.id,
  ]
}


output "lb_ext_ip" {
  value = azurerm_public_ip.lb_ext.ip_address
}
