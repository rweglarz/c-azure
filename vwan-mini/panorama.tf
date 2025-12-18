resource "panos_vm_auth_key" "this" {
  hours = 7200
  lifecycle {
    create_before_destroy = true
  }
}

resource "panos_panorama_template_stack" "hub1" {
  name = "azure-uvwan-hub1-ts"
  templates = [
    "azure-2-if",
    "vm common"
  ]
  description = "pat:acp"

  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_template_variable" "hub1" {
  for_each = {
    "$eth1-1-gw" = cidrhost(module.vnet_hub1_sec.subnets["public"].address_prefixes[0], 1)
    "$eth1-2-gw" = cidrhost(module.vnet_hub1_sec.subnets["private"].address_prefixes[0], 1)
  }
  template_stack = panos_panorama_template_stack.hub1.name
  name           = each.key
  type           = "ip-netmask"
  value          = each.value

  lifecycle { create_before_destroy = true }
}


data "panos_device_group" "this" {
  name = "azure-vwan"
}

resource "panos_panorama_nat_rule_group" "this" {
  device_group = data.panos_device_group.this.name
  rule {
    name = "inbound pub hc dnat"
    original_packet {
      source_zones          = ["public"]
      destination_zone      = "public"
      source_addresses      = ["azure health check"]
      destination_addresses = ["any"]
      service               = "tcp-health-check-54321"
    }
    translated_packet {
      source {
      }
      destination {
        dynamic_translation {
          address = "192.0.2.1"
          port    = 80
        }
      }
    }
  }
  rule {
    name = "inbound prv hc dnat"
    original_packet {
      source_zones          = ["private"]
      destination_zone      = "private"
      source_addresses      = ["azure health check"]
      destination_addresses = ["any"]
      service               = "tcp-health-check-54321"
    }
    translated_packet {
      source {
      }
      destination {
        dynamic_translation {
          address = "192.0.2.1"
          port    = 80
        }
      }
    }
  }

  lifecycle { create_before_destroy = true }
}
