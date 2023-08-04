resource "azurerm_lb" "fw_gwlb" {
  name                = "${var.name}-fw-gwlb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Gateway"

  frontend_ip_configuration {
    name                          = "gwlb"
    subnet_id                     = module.vnet_sec.subnets["gwlb"].id
    private_ip_address            = cidrhost(module.vnet_sec.subnets["gwlb"].address_prefixes[0], 5)
    private_ip_address_allocation = "Static"
  }
}


resource "azurerm_lb_probe" "gwlb" {
  name            = "tcp-probe-gwlb"
  loadbalancer_id = azurerm_lb.fw_gwlb.id
  protocol        = "Tcp"
  port            = 54321
}


resource "azurerm_lb_rule" "gwlb_r1" {
  name = "${var.name}-gwlb-r1"

  loadbalancer_id                = azurerm_lb.fw_gwlb.id
  frontend_ip_configuration_name = "gwlb"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.fw_gwlb.id]
  probe_id                       = azurerm_lb_probe.gwlb.id

  disable_outbound_snat = true

  protocol      = "All"
  frontend_port = 0
  backend_port  = 0
}

resource "azurerm_lb_backend_address_pool" "fw_gwlb" {
  name            = "${var.name}-fw-gwlb"
  loadbalancer_id = azurerm_lb.fw_gwlb.id
  tunnel_interface {
    identifier = 800
    type  = "Internal"
    protocol = "VXLAN"
    port = "2000"
  }
  tunnel_interface {
    identifier = 801
    type  = "External"
    protocol = "VXLAN"
    port = "2001"
  }
}

output "gateway_load_balancer_frontend_ip_configuration_id" {
  value = azurerm_lb.fw_gwlb.frontend_ip_configuration[0].id
}
