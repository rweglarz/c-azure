resource "azurerm_public_ip" "hub2_fw" {
  name                = "${local.dname}-hub2-fw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1,2,3]
}

resource "azurerm_palo_alto_virtual_network_appliance" "hub2" {
  count = var.cloud_ngfw_panorama_config==null ? 0 : 1

  name           = "${local.dname}-hub2-fw"
  virtual_hub_id = azurerm_virtual_hub.hub2.id
}

resource "azurerm_palo_alto_next_generation_firewall_virtual_hub_panorama" "hub2" {
  count = var.cloud_ngfw_panorama_config==null ? 0 : 1

  name                = "${local.dname}-hub2-fw-2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  network_profile {
    virtual_hub_id               = azurerm_virtual_hub.hub2.id
    network_virtual_appliance_id = azurerm_palo_alto_virtual_network_appliance.hub2[0].id
    egress_nat_ip_address_ids = [
      azurerm_public_ip.hub2_fw.id
    ]
    public_ip_address_ids = [
      azurerm_public_ip.hub2_fw.id
    ]
  }

  # dns_settings {
  #   dns_servers = [
  #     azurerm_private_dns_resolver_inbound_endpoint.hub2.ip_configurations[0].private_ip_address,
  #   ]
  # }

  panorama_base64_config = var.cloud_ngfw_panorama_config
  plan_id  = "panw-cngfw-payg"

  depends_on = [
    google_compute_firewall.pan
  ]
}


resource "azurerm_virtual_hub_routing_intent" "hub2" {
  count = (var.cloud_ngfw_panorama_config!=null && var.configure_hub_routing_intent) ? 1 : 0
  name           = "${local.dname}-hub2"
  virtual_hub_id = azurerm_virtual_hub.hub2.id

  routing_policy {
    name         = "InternetTrafficPolicy"
    destinations = ["Internet"]
    next_hop     = azurerm_palo_alto_virtual_network_appliance.hub2[0].id
  }
  routing_policy {
    name         = "PrivateTrafficPolicy"
    destinations = ["PrivateTraffic"]
    next_hop     = azurerm_palo_alto_virtual_network_appliance.hub2[0].id
  }
  depends_on = [
    azurerm_palo_alto_next_generation_firewall_virtual_hub_panorama.hub2
  ]
}
