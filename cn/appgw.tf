resource "azurerm_public_ip" "appgw" {
  name                = "${var.name}-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

locals {
  backend_address_pool_name      = "${var.name}-beap"
  frontend_port_name             = "${var.name}-feport"
  frontend_ip_configuration_name = "${var.name}-feip"
  listener_name                  = "${var.name}-httplstn"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.name}-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "ip1"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = "empty"
  }


  backend_http_settings {
    name                  = "path1a"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 81
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  url_path_map {
    name = "upm"
    //default_redirect_configuration_name  = local.url_path_map_name
    default_backend_http_settings_name = "path1a"
    default_backend_address_pool_name  = "empty"
    path_rule {
      name                       = "empty"
      backend_address_pool_name  = "empty"
      paths                      = ["/empty", ]
      backend_http_settings_name = "path1a"
    }
  }

  request_routing_rule {
    name               = "generic"
    rule_type          = "PathBasedRouting"
    http_listener_name = local.listener_name
    url_path_map_name  = "upm"
  }

  rewrite_rule_set {
    name = "xff-remove-port"
    rewrite_rule {
      name          = "r1"
      rule_sequence = 1
      request_header_configuration {
        header_name  = "X-Forwarded-For"
        header_value = "1.2.3.4,{var_add_x_forwarded_for_proxy}"
      }
    }
  }
}
