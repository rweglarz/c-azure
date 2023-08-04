resource "azurerm_lb" "hub4_ext" {
  name                = "${var.name}-hub4-lb-ext"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "srv-ext"
    public_ip_address_id = azurerm_public_ip.hub4_ext_lb.id

    gateway_load_balancer_frontend_ip_configuration_id  = var.gateway_load_balancer_frontend_ip_configuration_id
  }
}

resource "azurerm_public_ip" "hub4_ext_lb" {
  name                = "${var.name}-hub4-lb-ext"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_lb_probe" "hub4_ext" {
  name            = "srv-probe"
  loadbalancer_id = azurerm_lb.hub4_ext.id
  protocol        = "Tcp"
  port            = 80
}


resource "azurerm_lb_rule" "hub4_ext_srv_r1" {
  name = "srv-r1"

  loadbalancer_id                = azurerm_lb.hub4_ext.id
  frontend_ip_configuration_name = "srv-ext"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.hub4_ext.id]
  probe_id                       = azurerm_lb_probe.hub4_ext.id

  disable_outbound_snat = false

  protocol      = "Tcp"
  frontend_port = 80
  backend_port  = 80
}

resource "azurerm_lb_backend_address_pool" "hub4_ext" {
  name            = "${var.name}-hub4-lb-ext"
  loadbalancer_id = azurerm_lb.hub4_ext.id
}

output "hub4_ext_lb_ip" {
  value = azurerm_public_ip.hub4_ext_lb.ip_address
}
