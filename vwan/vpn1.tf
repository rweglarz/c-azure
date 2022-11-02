resource "azurerm_vpn_gateway" "hub1-vpn1" {
  name                = "example-vpng"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  virtual_hub_id      = azurerm_virtual_hub.hub1.id
  bgp_settings {
    asn         = 65515
    peer_weight = 0
    instance_0_bgp_peering_address {
      custom_ips = [
        "169.254.21.1",
        "169.254.21.5",
      ]
    }
    instance_1_bgp_peering_address {
      custom_ips = [
        "169.254.22.1",
        "169.254.22.5",
      ]
    }

  }
}

resource "azurerm_vpn_site" "aws1" {
  name                = "aws1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id

  link {
    name       = "isp1"
    ip_address = "3.74.49.148"
    bgp {
      asn             = 65516
      peering_address = "169.254.21.2"
    }
  }
  link {
    name       = "isp2"
    ip_address = "3.120.55.173"
    bgp {
      asn             = 65516
      peering_address = "169.254.22.6"
    }
  }
}


locals {
  psk = "qaz123rweqaz123"
}

resource "azurerm_vpn_gateway_connection" "aws1-hub1" {
  name               = "aws1-hub1"
  vpn_gateway_id     = azurerm_vpn_gateway.hub1-vpn1.id
  remote_vpn_site_id = azurerm_vpn_site.aws1.id

  vpn_link {
    name             = "isp1"
    vpn_site_link_id = azurerm_vpn_site.aws1.link[0].id
    bgp_enabled      = true
    custom_bgp_address {
      ip_address          = "169.254.21.1"
      ip_configuration_id = "Instance0"
    }
    custom_bgp_address {
      ip_address          = "169.254.22.1"
      ip_configuration_id = "Instance1"
    }
    shared_key = local.psk
  }
  vpn_link {
    name             = "isp2"
    vpn_site_link_id = azurerm_vpn_site.aws1.link[1].id
    bgp_enabled      = true
    custom_bgp_address {
      ip_address          = "169.254.21.5"
      ip_configuration_id = "Instance0"
    }
    custom_bgp_address {
      ip_address          = "169.254.22.5"
      ip_configuration_id = "Instance1"
    }
    shared_key = local.psk
  }
}
