resource "azurerm_public_ip" "cloud_ngfw" {
  count  = var.cloud_ngfw_public_ingress_ip_number

  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location

  name              = "${var.name}-cngfw-${count.index}"
  allocation_method = "Static"
  sku               = "Standard"
  zones             = [1, 2, 3]
}

resource "azurerm_public_ip" "cloud_ngfw_snat" {
  count  = var.cloud_ngfw_public_egress_ip_number

  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location

  name              = "${var.name}-cngfw-snat-${count.index}"
  allocation_method = "Static"
  sku               = "Standard"
  zones             = [1, 2, 3]
}

locals {
  cngfw_inbound_nats = {
    app01-srv1 = {
      protocol = "TCP"
      frontend_config = {
        public_ip_address_id = azurerm_public_ip.cloud_ngfw[0].id
        port = 80
      }
      backend_config = {
        public_ip_address = module.app01_prod_srv[0].private_ip_address
        port = 80
      }
    }
    app02-srv1 = {
      protocol = "TCP"
      frontend_config = {
        public_ip_address_id = azurerm_public_ip.cloud_ngfw[1].id
        port = 80
      }
      backend_config = {
        public_ip_address = module.app02_srv[0].private_ip_address
        port = 80
      }
    }
  }
}



locals {
  tcngfw = {
    pan_private_ip = one(azurerm_palo_alto_next_generation_firewall_virtual_network_panorama.this[*].network_profile[0].vnet_configuration[0].ip_of_trust_for_user_defined_routes)
    rs_private_ip  = one(azurerm_palo_alto_next_generation_firewall_virtual_network_local_rulestack.this[*].network_profile[0].vnet_configuration[0].ip_of_trust_for_user_defined_routes)
    scm_private_ip = one(azurerm_palo_alto_next_generation_firewall_virtual_network_strata_cloud_manager.this[*].network_profile[0].vnet_configuration[0].ip_of_trust_for_user_defined_routes)
  }
  cngfw = {
    private_ip   = coalesce(local.tcngfw.scm_private_ip, local.tcngfw.pan_private_ip, local.tcngfw.rs_private_ip, var.cloud_ngfw_internal_ip)
    device_group = one(azurerm_palo_alto_next_generation_firewall_virtual_network_panorama.this[*].panorama[0].device_group_name)
  }
}

output "cngfw_public_ip" {
  value = azurerm_public_ip.cloud_ngfw[*].ip_address
}
