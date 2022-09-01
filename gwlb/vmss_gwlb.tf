resource "azurerm_lb" "gwlb" {
  name                = "${var.name}-gwlb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Gateway"

  frontend_ip_configuration {
    name                          = "gwlb"
    subnet_id                     = azurerm_subnet.data.id
    private_ip_address            = cidrhost(azurerm_subnet.data.address_prefixes[0], 5)
    private_ip_address_allocation = "Static"
  }
}


resource "azurerm_lb_probe" "this" {
  name            = "tcp-probe"
  loadbalancer_id = azurerm_lb.gwlb.id
  protocol        = "Tcp"
  port            = 443
}


resource "azurerm_lb_rule" "gwlb_r1" {
  name = "${var.name}-gwlb-r1"

  loadbalancer_id                = azurerm_lb.gwlb.id
  frontend_ip_configuration_name = "gwlb"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.gwlb.id]
  probe_id                       = azurerm_lb_probe.this.id

  disable_outbound_snat = true

  protocol      = "All"
  frontend_port = 0
  backend_port  = 0
}
resource "azurerm_lb_backend_address_pool" "gwlb" {
  name            = "${var.name}-gwlb"
  loadbalancer_id = azurerm_lb.gwlb.id
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

