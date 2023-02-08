resource "azurerm_public_ip" "vng_left_c1" {
  name                = "${var.name}-left-vng-c1"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "vng_left_c2" {
  name                = "${var.name}-left-vng-c2"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "left" {
  name                = "${var.name}-left"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "HighPerformance"

  ip_configuration {
    name                 = "c1"
    public_ip_address_id = azurerm_public_ip.vng_left_c1.id
    subnet_id            = module.vnet_left_hub.subnets["GatewaySubnet"].id
  }
  ip_configuration {
    name                 = "c2"
    public_ip_address_id = azurerm_public_ip.vng_left_c2.id
    subnet_id            = module.vnet_left_hub.subnets["GatewaySubnet"].id
  }
  bgp_settings {
    asn = 65001
    peering_addresses {
      ip_configuration_name = "c1"
      apipa_addresses = [
        "169.254.21.1",
        "169.254.21.2"
      ]
    }
    peering_addresses {
      ip_configuration_name = "c2"
      apipa_addresses = [
        "169.254.21.3",
        "169.254.21.4"
      ]
    }
  }
}

resource "azurerm_local_network_gateway" "right_seen_by_left_1" {
  name                = "${var.name}-right-seen-by-left-1"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  gateway_address = azurerm_virtual_network_gateway.right.bgp_settings[0].peering_addresses[0].tunnel_ip_addresses[0]
  bgp_settings {
    asn                 = 65002
    #bgp_peering_address = "169.254.22.1"
    bgp_peering_address = "172.16.8.68"
  }
}

resource "azurerm_local_network_gateway" "right_seen_by_left_2" {
  name                = "${var.name}-right-seen-by-left-2"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  gateway_address = azurerm_virtual_network_gateway.right.bgp_settings[0].peering_addresses[1].tunnel_ip_addresses[0]
  bgp_settings {
    asn                 = 65002
    #bgp_peering_address = "169.254.22.3"
    bgp_peering_address = "172.16.8.69"
  }
}

resource "azurerm_virtual_network_gateway_connection" "left_right_1" {
  name                = "${var.name}-left-right-1"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.left.id
  local_network_gateway_id   = azurerm_local_network_gateway.right_seen_by_left_1.id

  enable_bgp = true

  shared_key = var.psk
  # custom_bgp_addresses {
  #   primary = "169.254.21.1"
  #   secondary = "169.254.21.3"
  # }
}

resource "azurerm_virtual_network_gateway_connection" "left_right_2" {
  name                = "${var.name}-left-right-2"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.left.id
  local_network_gateway_id   = azurerm_local_network_gateway.right_seen_by_left_2.id

  enable_bgp = true

  shared_key = var.psk

  # custom_bgp_addresses {
  #   primary = "169.254.21.2"
  #   secondary = "169.254.21.4"
  # }
}

resource "azurerm_route_table" "left_vng" {
  name                = "${var.name}-left-vng"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_route" "left_vng-peers_via_fw" {
  for_each = {
    srv1 = module.vnet_left_srv_1.vnet.address_space[0]
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.this.name
  route_table_name       = azurerm_route_table.left_vng.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.private_ips.left_hub_fw["eth1_1_ip"]
}

resource "azurerm_subnet_route_table_association" "left_vng" {
  subnet_id      = module.vnet_left_hub.subnets["GatewaySubnet"].id
  route_table_id = azurerm_route_table.left_vng.id
}
