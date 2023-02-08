resource "azurerm_public_ip" "vng_right_c1" {
  name                = "${var.name}-right-vng-c1"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "vng_right_c2" {
  name                = "${var.name}-right-vng-c2"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "right" {
  name                = "${var.name}-right"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "HighPerformance"

  ip_configuration {
    name                 = "c1"
    public_ip_address_id = azurerm_public_ip.vng_right_c1.id
    subnet_id            = module.vnet_right_hub.subnets["GatewaySubnet"].id
  }
  ip_configuration {
    name                 = "c2"
    public_ip_address_id = azurerm_public_ip.vng_right_c2.id
    subnet_id            = module.vnet_right_hub.subnets["GatewaySubnet"].id
  }
  bgp_settings {
    asn = 65002 # in theory it should be 65515 but putting it explicitly to work with ARS
    peering_addresses {
      ip_configuration_name = "c1"
      apipa_addresses = [
        "169.254.22.1",
        "169.254.22.2"
      ]
    }
    peering_addresses {
      ip_configuration_name = "c2"
      apipa_addresses = [
        "169.254.22.3",
        "169.254.22.4"
      ]
    }
  }
}

resource "azurerm_local_network_gateway" "left_seen_by_right_1" {
  name                = "${var.name}-left-seen-by-right-1"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  gateway_address = azurerm_virtual_network_gateway.left.bgp_settings[0].peering_addresses[0].tunnel_ip_addresses[0]
  bgp_settings {
    asn                 = 65001
    #bgp_peering_address = "169.254.21.1"
    bgp_peering_address = "172.16.0.68"
  }
}

resource "azurerm_local_network_gateway" "left_seen_by_right_2" {
  name                = "${var.name}-left-seen-by-right-2"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  gateway_address = azurerm_virtual_network_gateway.left.bgp_settings[0].peering_addresses[1].tunnel_ip_addresses[0]
  bgp_settings {
    asn                 = 65001
    #bgp_peering_address = "169.254.21.3"
    bgp_peering_address = "172.16.0.69"
  }
}

resource "azurerm_virtual_network_gateway_connection" "right_left_1" {
  name                = "${var.name}-right-left-1"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.right.id
  local_network_gateway_id   = azurerm_local_network_gateway.left_seen_by_right_1.id

  enable_bgp = true

  shared_key = var.psk

  # custom_bgp_addresses {
  #   primary = "169.254.22.1"
  #   secondary = "169.254.22.3"
  # }
}

resource "azurerm_virtual_network_gateway_connection" "right_left_2" {
  name                = "${var.name}-right-left-2"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.right.id
  local_network_gateway_id   = azurerm_local_network_gateway.left_seen_by_right_2.id

  enable_bgp = true

  shared_key = var.psk

  # custom_bgp_addresses {
  #   primary = "169.254.22.2"
  #   secondary = "169.254.22.4"
  # }
}
