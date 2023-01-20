resource "azurerm_application_gateway" "appgw_agic" {
  count = var.managed_by_agic ? 1 : 0

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  dynamic "sku" {
    for_each = var.tier == "Standard" ? [1] : []
    content {
      name     = "Standard_Small"
      tier     = "Standard"
      capacity = 1
    }
  }
  dynamic "sku" {
    for_each = var.tier == "Standard_v2" ? [1] : []
    content {
      name     = "Standard_v2"
      tier     = "Standard_v2"
      capacity = 1
    }
  }

  gateway_ip_configuration {
    name      = "ip1"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "private"
    port = var.use_public_ip ? 44444 : 80
  }
  dynamic "frontend_port" {
    for_each = var.use_public_ip ? [1] : []
    content {
      name = "public"
      port = 80
    }
  }

  frontend_ip_configuration {
    name                          = "private"
    subnet_id                     = var.subnet_id
    private_ip_address            = var.private_ip_address
    private_ip_address_allocation = "Static"
  }
  dynamic "frontend_ip_configuration" {
    for_each = var.tier == "Standard_v2" ? [1] : []
    content {
      name                 = "public"
      public_ip_address_id = azurerm_public_ip.this[0].id
    }
  }

  backend_address_pool {
    name = "empty"
  }
  dynamic "backend_address_pool" {
    for_each = var.virtual_hosts
    content {
      name         = backend_address_pool.key
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }


  backend_http_settings {
    name                  = "path1a"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  dynamic "http_listener" {
    for_each = var.virtual_hosts
    content {
      name                           = http_listener.key
      frontend_ip_configuration_name = var.use_public_ip ? "public" : "private"
      frontend_port_name             = var.use_public_ip ? "public" : "private"
      protocol                       = "Http"
      host_names                     = var.tier == "Standard_v2" ? http_listener.value.host_names : null
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.virtual_hosts
    content {
      name                       = request_routing_rule.key
      rule_type                  = "Basic"
      http_listener_name         = request_routing_rule.key
      backend_address_pool_name  = request_routing_rule.key
      backend_http_settings_name = "path1a"
      priority                   = var.tier == "Standard_v2" ? request_routing_rule.value.priority : null
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = var.tier == "Standard_v2" ? [1] : []
    content {
      name = "xff-remove-port"
      rewrite_rule {
        name          = "r1"
        rule_sequence = 1
        request_header_configuration {
          header_name  = "X-Forwarded-For"
          header_value = "192.0.2.1,{var_add_x_forwarded_for_proxy}"
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      frontend_port,
      http_listener,
      probe,
      request_routing_rule,
      tags,
    ]
  }
}
