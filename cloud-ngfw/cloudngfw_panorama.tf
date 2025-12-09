resource "azurerm_palo_alto_next_generation_firewall_virtual_network_panorama" "this" {
  count = (var.cloud_ngfw_panorama_config==null || var.scm_tenant!=null) ? 0 : 1
  name                   = "${var.name}-panorama"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  panorama_base64_config = var.cloud_ngfw_panorama_config

  network_profile {
    public_ip_address_ids     = concat(azurerm_public_ip.cloud_ngfw[*].id, azurerm_public_ip.cloud_ngfw_snat[*].id)
    egress_nat_ip_address_ids = var.cloud_ngfw_public_egress_ip_number > 0 ? azurerm_public_ip.cloud_ngfw_snat[*].id : azurerm_public_ip.cloud_ngfw[*].id

    vnet_configuration {
      virtual_network_id  = azurerm_virtual_network.sec.id
      trusted_subnet_id   = azurerm_subnet.private.id
      untrusted_subnet_id = azurerm_subnet.public.id
    }
    trusted_address_ranges = [
      "100.64.0.0/20"
    ]
  }
  dynamic destination_nat {
    for_each = local.cngfw_inbound_nats
    content {
      name = destination_nat.key
      protocol = destination_nat.value.protocol
      frontend_config {
        public_ip_address_id = destination_nat.value.frontend_config.public_ip_address_id
        port = destination_nat.value.frontend_config.port
      }
      backend_config {
        public_ip_address = destination_nat.value.backend_config.public_ip_address
        port = destination_nat.value.backend_config.port
      }
    }
  }

  dns_settings {
    dns_servers = [
      azurerm_private_dns_resolver_inbound_endpoint.sec.ip_configurations[0].private_ip_address
    ]
  }

  plan_id  = "panw-cngfw-payg"

  depends_on = [
    google_compute_firewall.pan,
  ]
}
