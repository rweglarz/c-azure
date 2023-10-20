resource "azurerm_application_gateway" "appgw_regular" {
  count = var.managed_by_agic ? 0 : 1

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
      port = var.use_https ? 443 : 80
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

  dynamic "backend_http_settings" {
    for_each = var.virtual_hosts
    content {
      name                           = backend_http_settings.key
      cookie_based_affinity          = "Disabled"
      path                           = "/"
      port                           = try(backend_http_settings.value.backend_port, var.use_https ? 443 : 80)
      protocol                       = var.use_https ? "Https" : "Http"
      request_timeout                = 10
      trusted_root_certificate_names = var.use_https ? ["trusted-root"] : []
    }
  }

  dynamic "http_listener" {
    for_each = var.virtual_hosts
    content {
      name                           = http_listener.key
      frontend_ip_configuration_name = var.use_public_ip ? "public" : "private"
      frontend_port_name             = var.use_public_ip ? "public" : "private"
      protocol                       = var.use_https ? "Https" : "Http"
      host_names                     = var.tier == "Standard_v2" ? http_listener.value.host_names : null
      ssl_certificate_name           = var.use_https ? "inbound-cert" : null
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.virtual_hosts
    content {
      name                       = request_routing_rule.key
      rule_type                  = "Basic"
      http_listener_name         = request_routing_rule.key
      backend_address_pool_name  = request_routing_rule.key
      backend_http_settings_name = request_routing_rule.key
      priority                   = var.tier == "Standard_v2" ? request_routing_rule.value.priority : null
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = var.tier == "Standard_v2" ? [1] : []
    content {
      name = "xff-extra-ip"
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
  dynamic "rewrite_rule_set" {
    for_each = var.tier == "Standard_v2" ? [1] : []
    content {
      name = "xff"
      rewrite_rule {
        name          = "r1"
        rule_sequence = 1
        request_header_configuration {
          header_name  = "X-Forwarded-For"
          header_value = "{var_add_x_forwarded_for_proxy}"
        }
      }
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.use_https ? [1] : []
    content {
      name     = "inbound-cert"
      data     = var.ssl_certificate_data
      password = var.ssl_certificate_pass
    }
  }

  dynamic "trusted_root_certificate" {
    for_each = var.use_https ? [1] : []
    content {
      name = "trusted-root"
      data = var.trusted_root_certificate_data
    }
  }
}
