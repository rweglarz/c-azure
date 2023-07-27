resource "azurerm_lb" "srv" {
  name                = "${var.name}-srv"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "srv-ext"
//   subnet_id                     = azurerm_subnet.data.id
//   private_ip_address            = cidrhost(azurerm_subnet.data.address_prefixes[0], 5)
//   private_ip_address_allocation = "Static"

    public_ip_address_id = azurerm_public_ip.srv.id

    gateway_load_balancer_frontend_ip_configuration_id  = azurerm_lb.fw_gwlb.frontend_ip_configuration[0].id
  }
}

resource "azurerm_public_ip" "srv" {
  name                = "${var.name}-srv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_lb_probe" "srv" {
  name            = "srv-probe"
  loadbalancer_id = azurerm_lb.srv.id
  protocol        = "Tcp"
  port            = 80
}


resource "azurerm_lb_rule" "srv_r1" {
  name = "${var.name}-srv-r1"

  loadbalancer_id                = azurerm_lb.srv.id
  frontend_ip_configuration_name = "srv-ext"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.srv.id]
  probe_id                       = azurerm_lb_probe.srv.id

  disable_outbound_snat = false

  protocol      = "Tcp"
  frontend_port = 80
  backend_port  = 80
}

resource "azurerm_lb_rule" "srv_r2" {
  name = "${var.name}-srv-r2"

  loadbalancer_id                = azurerm_lb.srv.id
  frontend_ip_configuration_name = "srv-ext"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.srv.id]
  probe_id                       = azurerm_lb_probe.srv.id

  disable_outbound_snat = false

  protocol      = "Tcp"
  frontend_port = 443
  backend_port  = 443
}

resource "azurerm_lb_backend_address_pool" "srv" {
  name            = "${var.name}-srv"
  loadbalancer_id = azurerm_lb.srv.id
}

output "server_lb" {
  value = azurerm_public_ip.srv.ip_address
}
