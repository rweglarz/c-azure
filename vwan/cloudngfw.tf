resource "azurerm_public_ip" "hub2_fw" {
  name                = "${local.dname}-hub2-fw"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1,2,3]
}

resource "azurerm_palo_alto_virtual_network_appliance" "hub2" {
  name           = "${local.dname}-hub2-fw"
  virtual_hub_id = azurerm_virtual_hub.hub2.id
}

resource "azurerm_palo_alto_next_generation_firewall_virtual_hub_panorama" "hub2" {
  name                = "${local.dname}-hub2-fw"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  network_profile {
    virtual_hub_id               = azurerm_virtual_hub.hub2.id
    network_virtual_appliance_id = azurerm_palo_alto_virtual_network_appliance.hub2.id
    egress_nat_ip_address_ids = [
      azurerm_public_ip.hub2_fw.id
    ]
    public_ip_address_ids = [
      azurerm_public_ip.hub2_fw.id
    ]
  }

  panorama_base64_config = var.cloud_ngfw_panorama_config.hub2

  dns_settings {
    dns_servers = [
      azurerm_private_dns_resolver_inbound_endpoint.hub2.ip_configurations[0].private_ip_address,
    ]
  }

  depends_on = [
    aws_ec2_managed_prefix_list_entry.cloud_ngfw_hub2
  ]
}


resource "azurerm_public_ip" "hub4_fw" {
  name                = "${local.dname}-hub4-fw"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1,2,3]
}

resource "azurerm_palo_alto_virtual_network_appliance" "hub4" {
  name           = "${local.dname}-hub4-fw"
  virtual_hub_id = azurerm_virtual_hub.hub4.id
}

resource "azurerm_palo_alto_next_generation_firewall_virtual_hub_panorama" "hub4" {
  name                = "${local.dname}-hub4-fw"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location

  network_profile {
    virtual_hub_id               = azurerm_virtual_hub.hub4.id
    network_virtual_appliance_id = azurerm_palo_alto_virtual_network_appliance.hub4.id
    egress_nat_ip_address_ids = [
      azurerm_public_ip.hub4_fw.id
    ]
    public_ip_address_ids = [
      azurerm_public_ip.hub4_fw.id
    ]
  }

  panorama_base64_config = var.cloud_ngfw_panorama_config.hub4

  depends_on = [
    aws_ec2_managed_prefix_list_entry.cloud_ngfw_hub4
  ]
}
