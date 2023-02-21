resource "azurerm_lb" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "obew"
    subnet_id                     = var.subnet_id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_probe" "this" {
  name            = "tcp-443"
  loadbalancer_id = azurerm_lb.this.id
  protocol        = "Tcp"
  port            = 443
}

resource "azurerm_lb_backend_address_pool" "obew" {
  name            = "obew"
  loadbalancer_id = azurerm_lb.this.id
}

resource "azurerm_lb_rule" "obew" {
  name = "obew"

  loadbalancer_id                = azurerm_lb.this.id
  frontend_ip_configuration_name = "obew"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.obew.id]
  probe_id                       = azurerm_lb_probe.this.id

  protocol      = "All"
  frontend_port = 0
  backend_port  = 0
}
