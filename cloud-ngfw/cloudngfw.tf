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


resource "azurerm_palo_alto_next_generation_firewall_virtual_network_panorama" "this" {
  count = var.cloud_ngfw_panorama_config==null ? 0 : 1
  name                   = "${var.name}-panorama"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  panorama_base64_config = var.cloud_ngfw_panorama_config

  network_profile {
    public_ip_address_ids     = azurerm_public_ip.cloud_ngfw[*].id
    egress_nat_ip_address_ids = var.cloud_ngfw_public_egress_ip_number > 0 ? azurerm_public_ip.cloud_ngfw_snat[*].id : null

    vnet_configuration {
      virtual_network_id  = azurerm_virtual_network.sec.id
      trusted_subnet_id   = azurerm_subnet.private.id
      untrusted_subnet_id = azurerm_subnet.public.id
    }
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
  plan_id  = "panw-cngfw-payg"

  depends_on = [
    google_compute_firewall.pan,
  ]
}

resource "azurerm_palo_alto_next_generation_firewall_virtual_network_local_rulestack" "this" {
  count = (var.cloud_ngfw_panorama_config==null && var.scm_tenant==null)? 1 : 0
  name                   = "${var.name}-rulestack"
  resource_group_name    = azurerm_resource_group.rg.name
  #location               = azurerm_resource_group.rg.location
  rulestack_id           = azurerm_palo_alto_local_rulestack.this.id

  network_profile {
    public_ip_address_ids     = azurerm_public_ip.cloud_ngfw[*].id
    egress_nat_ip_address_ids = var.cloud_ngfw_public_egress_ip_number > 0 ? azurerm_public_ip.cloud_ngfw_snat[*].id : null

    vnet_configuration {
      virtual_network_id  = azurerm_virtual_network.sec.id
      trusted_subnet_id   = azurerm_subnet.private.id
      untrusted_subnet_id = azurerm_subnet.public.id
    }
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

  plan_id  = "panw-cngfw-payg"
}

locals {
  tcngfw = {
    pan_private_ip = one(azurerm_palo_alto_next_generation_firewall_virtual_network_panorama.this[*].network_profile[0].vnet_configuration[0].ip_of_trust_for_user_defined_routes)
    rs_private_ip = one(azurerm_palo_alto_next_generation_firewall_virtual_network_local_rulestack.this[*].network_profile[0].vnet_configuration[0].ip_of_trust_for_user_defined_routes)
  }
  cngfw = {
    private_ip = coalesce(local.tcngfw.pan_private_ip, local.tcngfw.rs_private_ip, var.cloud_ngfw_internal_ip)
    device_group = one(azurerm_palo_alto_next_generation_firewall_virtual_network_panorama.this[*].panorama[0].device_group_name)
  }
}

output "cngfw_public_ip" {
  value = azurerm_public_ip.cloud_ngfw[*].ip_address
}
