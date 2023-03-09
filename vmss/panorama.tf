resource "panos_device_group" "vmss" {
  name = "azure-vmss-3"

  lifecycle { create_before_destroy = true }
}

resource "panos_device_group" "bnd" {
  name = "azure-vmss-3-bnd"

  lifecycle { create_before_destroy = true }

  depends_on = [
    panos_device_group.vmss
  ]
}

resource "panos_device_group" "byol" {
  name = "azure-vmss-3-byol"

  lifecycle { create_before_destroy = true }

  depends_on = [
    panos_device_group.vmss
  ]
}

resource "panos_device_group_parent" "bnd" {
  device_group = panos_device_group.bnd.name
  parent       = panos_device_group.vmss.name

  lifecycle { create_before_destroy = true }
}

resource "panos_device_group_parent" "byol" {
  device_group = panos_device_group.byol.name
  parent       = panos_device_group.vmss.name

  lifecycle { create_before_destroy = true }
}



resource "panos_panorama_service_object" "tcp_22" {
  device_group     = panos_device_group.vmss.name
  name             = "tcp-22"
  protocol         = "tcp"
  destination_port = "22"

  lifecycle { create_before_destroy = true }
}


resource "panos_panorama_nat_rule_group" "this" {
  device_group = panos_device_group.vmss.name
  rule {
    name = "tf outbound"
    original_packet {
      source_zones          = ["dmz", "internal"]
      destination_zone      = "untrust"
      source_addresses      = ["any"]
      destination_addresses = ["any"]
    }
    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = "ethernet1/1"
          }
        }
      }
      destination {
      }
    }
  }
  rule {
    name = "tf inbound"
    original_packet {
      source_zones     = ["untrust"]
      destination_zone = "untrust"
      source_addresses = ["any"]
      destination_addresses = [
        azurerm_public_ip.lb_ext.ip_address
      ]
      service = panos_panorama_service_object.tcp_22.name
    }
    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = "ethernet1/2"
          }
        }
      }
      destination {
        static_translation {
          address = module.srv_sec.private_ip_address
        }
      }
    }
  }

  lifecycle { create_before_destroy = true }
}
