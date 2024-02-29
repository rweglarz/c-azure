resource "azurerm_vpn_gateway" "hub2" {
  #name                = "${local.dname}-hub2"
  name                = local.dname
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  virtual_hub_id      = azurerm_virtual_hub.hub2.id
  bgp_settings {
    asn         = var.asn.hub2
    peer_weight = 0
    instance_0_bgp_peering_address {
      custom_ips = var.peering_address.hub2_i0
    }
    instance_1_bgp_peering_address {
      custom_ips = var.peering_address.hub2_i1
    }
  }
  depends_on = [ 
    azurerm_palo_alto_next_generation_firewall_virtual_hub_panorama.hub2
  ]
}



resource "azurerm_vpn_gateway" "hub4" {
  name                = "${local.dname}-hub4"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  virtual_hub_id      = azurerm_virtual_hub.hub4.id
  bgp_settings {
    asn         = var.asn.hub4
    peer_weight = 0
    instance_0_bgp_peering_address {
      custom_ips = var.peering_address.hub4_i0
    }
    instance_1_bgp_peering_address {
      custom_ips = var.peering_address.hub4_i1
    }
  }
  depends_on = [ 
    azurerm_palo_alto_next_generation_firewall_virtual_hub_panorama.hub4
  ]
}


resource "azurerm_vpn_site" "aws1" {
  name                = "aws1-${random_id.did.hex}"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id

  link {
    name       = "isp1"
    ip_address = local.public_ip.aws_fw1[0]
    bgp {
      asn             = var.asn.aws_fw1
      peering_address = var.peering_address.aws_fw1[0]
    }
  }
  link {
    name       = "isp2"
    ip_address = local.public_ip.aws_fw1[1]
    bgp {
      asn             = var.asn.aws_fw1
      peering_address = var.peering_address.aws_fw1[1]
    }
  }
}


resource "azurerm_vpn_gateway_connection" "aws1-hub2" {
  name               = "aws1-hub2-${random_id.did.hex}"
  vpn_gateway_id     = azurerm_vpn_gateway.hub2.id
  remote_vpn_site_id = azurerm_vpn_site.aws1.id

  vpn_link {
    name             = "isp1"
    vpn_site_link_id = azurerm_vpn_site.aws1.link[0].id
    bgp_enabled      = true
    custom_bgp_address {
      ip_address          =  var.peering_address.hub2_i0[0]
      ip_configuration_id = "Instance0"
    }
    custom_bgp_address {
      ip_address          =  var.peering_address.hub2_i1[0]
      ip_configuration_id = "Instance1"
    }
    shared_key = var.psk
  }
  vpn_link {
    name             = "isp2"
    vpn_site_link_id = azurerm_vpn_site.aws1.link[1].id
    bgp_enabled      = true
    custom_bgp_address {
      ip_address          =  var.peering_address.hub2_i0[1]
      ip_configuration_id = "Instance0"
    }
    custom_bgp_address {
      ip_address          =  var.peering_address.hub2_i1[1]
      ip_configuration_id = "Instance1"
    }
    shared_key = var.psk
  }
}
