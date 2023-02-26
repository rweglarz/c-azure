resource "azurerm_public_ip" "vng_right_c1" {
  name                = "${var.name}-right-vng-c1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "vng_right_c2" {
  name                = "${var.name}-right-vng-c2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "right" {
  name                = "${var.name}-right"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

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
    asn = var.asn["ars"] # it should be 65515 by default but putting it explicitly to work with ARS
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


resource "azurerm_local_network_gateway" "right_left_u_fw1" {
  name                = "${var.name}-right--left-u-fw1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  gateway_address = local.public_ips["left_u_ipsec_fw1"][0]
  bgp_settings {
    asn                 = var.asn["left_u_ipsec_fw1"]
    bgp_peering_address = local.private_ips.left_u_ipsec_fw1["tun11_ip"]
  }
}

resource "azurerm_local_network_gateway" "right_left_u_fw2" {
  name                = "${var.name}-right--left-u-fw2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  gateway_address = local.public_ips["left_u_ipsec_fw2"][0]
  bgp_settings {
    asn                 = var.asn["left_u_ipsec_fw2"]
    bgp_peering_address = local.private_ips.left_u_ipsec_fw2["tun11_ip"]
  }
}

resource "azurerm_virtual_network_gateway_connection" "right_left_u_1" {
  name                = "${var.name}-right-left-u-1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.right.id
  local_network_gateway_id   = azurerm_local_network_gateway.right_left_u_fw1.id

  enable_bgp = true

  shared_key = var.psk

  custom_bgp_addresses {
    primary   = "169.254.22.1"
    secondary = "169.254.22.3"
  }
}

resource "azurerm_virtual_network_gateway_connection" "right_left_u_2" {
  name                = "${var.name}-right-left-u-2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.right.id
  local_network_gateway_id   = azurerm_local_network_gateway.right_left_u_fw2.id

  enable_bgp = true

  shared_key = var.psk

  custom_bgp_addresses {
    primary   = "169.254.22.2"
    secondary = "169.254.22.4"
  }
}


resource "azurerm_local_network_gateway" "right_left_b_fw1" {
  name                = "${var.name}-right--left-b-fw1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  gateway_address = local.public_ips["left_b_ipsec_fw1"][0]
  bgp_settings {
    asn                 = var.asn["left_b_ipsec_fw1"]
    bgp_peering_address = local.private_ips.left_b_ipsec_fw1["tun11_ip"]
  }
}

resource "azurerm_local_network_gateway" "right_left_b_fw2" {
  name                = "${var.name}-right--left-b-fw2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  gateway_address = local.public_ips["left_b_ipsec_fw2"][0]
  bgp_settings {
    asn                 = var.asn["left_b_ipsec_fw2"]
    bgp_peering_address = local.private_ips.left_b_ipsec_fw2["tun11_ip"]
  }
}

resource "azurerm_virtual_network_gateway_connection" "right_left_b_1" {
  name                = "${var.name}-right-left-b-1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.right.id
  local_network_gateway_id   = azurerm_local_network_gateway.right_left_b_fw1.id

  enable_bgp = true

  shared_key = var.psk

  custom_bgp_addresses {
    primary   = "169.254.22.1"
    secondary = "169.254.22.3"
  }
}

resource "azurerm_virtual_network_gateway_connection" "right_left_b_2" {
  name                = "${var.name}-right-left-b-2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.right.id
  local_network_gateway_id   = azurerm_local_network_gateway.right_left_b_fw2.id

  enable_bgp = true

  shared_key = var.psk

  custom_bgp_addresses {
    primary   = "169.254.22.2"
    secondary = "169.254.22.4"
  }
}
