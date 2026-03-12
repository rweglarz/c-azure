resource "panos_device_group" "vmss" {
  name = "azure-vmss-3"

  lifecycle { create_before_destroy = true }
}


resource "panos_panorama_nat_rule_group" "this" {
  device_group = panos_device_group.vmss.name
  rule {
    name = "tf outbound"
    original_packet {
      source_zones          = ["dmz", "private"]
      destination_zone      = "public"
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
  dynamic "rule" {
    for_each = ["dmz", "private"]
    content {
      name = "az hc ${rule.value}"
      original_packet {
        source_zones     = ["${rule.value}"]
        destination_zone = "${rule.value}"
        source_addresses = ["azure health check"]
        destination_addresses = ["any"]
        service = "tcp-health-check-54321"
      }
      translated_packet {
        source {}
        destination {
          dynamic_translation {
            address = "169.254.255.1"
            port    = 80
          }
        }
      }
    }
  }

  lifecycle { create_before_destroy = true }
}
