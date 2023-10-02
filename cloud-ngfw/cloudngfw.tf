resource "azurerm_public_ip" "cloud_ngfw" {
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location

  name              = "${var.name}-cngfw"
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


resource "azurerm_palo_alto_next_generation_firewall_virtual_network_panorama" "this" {
  name                   = var.name
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  panorama_base64_config = var.cloud_ngfw_panorama_config

  network_profile {
    public_ip_address_ids = [
      azurerm_public_ip.cloud_ngfw.id
    ]
    egress_nat_ip_address_ids = var.cloud_ngfw_public_egress_ip_number > 0 ? azurerm_public_ip.cloud_ngfw_snat[*].id : [azurerm_public_ip.cloud_ngfw.id]

    vnet_configuration {
      virtual_network_id  = azurerm_virtual_network.sec.id
      trusted_subnet_id   = azurerm_subnet.private.id
      untrusted_subnet_id = azurerm_subnet.public.id
    }
  }
  destination_nat {
    name = "app01-srv1"
    protocol = "TCP"
    frontend_config {
      public_ip_address_id = azurerm_public_ip.cloud_ngfw.id
      port = 80
    }
    backend_config {
      public_ip_address = module.app01_srv1.private_ip_address
      port = 80
    }
  }

  depends_on = [
    aws_ec2_managed_prefix_list_entry.cloud_ngfw_ips,
    aws_ec2_managed_prefix_list_entry.cloud_ngfw_snat,
  ]
}

locals {
  cngfw = {
    private_ip = azurerm_palo_alto_next_generation_firewall_virtual_network_panorama.this.network_profile[0].vnet_configuration[0].ip_of_trust_for_user_defined_routes
    device_group = azurerm_palo_alto_next_generation_firewall_virtual_network_panorama.this.panorama[0].device_group_name
  }
}

output "cngfw_public_ip" {
  value = azurerm_public_ip.cloud_ngfw.ip_address
}
