resource "azurerm_public_ip" "vng_i1" {
  name                = "${var.name}-vng-i1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "vng_i2" {
  name                = "${var.name}-vng-i2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = "${var.name}-vng"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "HighPerformance"

  ip_configuration {
    name                 = "i1"
    public_ip_address_id = azurerm_public_ip.vng_i1.id
    subnet_id            = module.vnet_sec.subnets["GatewaySubnet"].id
  }
  ip_configuration {
    name                 = "i2"
    public_ip_address_id = azurerm_public_ip.vng_i2.id
    subnet_id            = module.vnet_sec.subnets["GatewaySubnet"].id
  }
  bgp_settings {
    asn = var.asn["vng"]
    peering_addresses {
      ip_configuration_name = "i1"
      apipa_addresses = [
        "169.254.22.1",
        "169.254.22.5"
      ]
    }
    peering_addresses {
      ip_configuration_name = "i2"
      apipa_addresses = [
        "169.254.22.13",
        "169.254.22.17"
      ]
    }
  }
}



resource "azurerm_local_network_gateway" "i1-sc1" {
  name                = "${var.name}-i1-sc1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  gateway_address = var.prisma_access_pub_ips[0]
  bgp_settings {
    asn                 = var.asn["pa"]
    bgp_peering_address = var.prisma_access_bgp_ips[0]
  }
}

resource "azurerm_local_network_gateway" "i2-sc1" {
  name                = "${var.name}-i2-sc2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  gateway_address = var.prisma_access_pub_ips[0]
  bgp_settings {
    asn                 = var.asn["pa"]
    bgp_peering_address = var.prisma_access_bgp_ips[0]
  }
}


resource "azurerm_virtual_network_gateway_connection" "i1-sc1" {
  name                = "${var.name}-i1-sc1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.i1-sc1.id

  enable_bgp = true

  shared_key = var.psk

  custom_bgp_addresses {
    primary   = "169.254.22.1"
    secondary = "169.254.22.13"
  }
}

resource "azurerm_virtual_network_gateway_connection" "i2-sc1" {
  name                = "${var.name}-i2-sc1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.i2-sc1.id

  enable_bgp = true

  shared_key = var.psk

  custom_bgp_addresses {
    primary   = "169.254.22.5"
    secondary = "169.254.22.17"
  }
}

output "vng" {
  value = [
    azurerm_public_ip.vng_i1.ip_address,
    azurerm_public_ip.vng_i2.ip_address,
  ]
}
