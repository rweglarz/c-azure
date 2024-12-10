resource "panos_device_group" "hub1" {
  name = "azure-vwan-hub1"
}

resource "panos_device_group_parent" "hub1" {
    device_group = panos_device_group.hub1.name
    parent = "azure-vwan"

    lifecycle { create_before_destroy = true }
}

resource "panos_panorama_template_stack" "hub1_sec_fw" {
  name         = "azure-vwan-hub1-sec-fw-ts"
  default_vsys = "vsys1"
  templates = [
    "azure-2-if",
    "vm common",
  ]
  description = "pat:acp"
}

resource "panos_panorama_template_variable" "hub1_sec_fw" {
  for_each = {
    eth1-1-gw = cidrhost(module.hub1_sec.subnets.public.address_prefixes[0], 1)
    eth1-2-gw = cidrhost(module.hub1_sec.subnets.private.address_prefixes[0], 1)
  }
  template_stack = panos_panorama_template_stack.hub1_sec_fw.name
  name           = format("$%s", each.key)
  type           = "ip-netmask"
  value          = each.value
}


resource "panos_panorama_nat_rule_group" "hub1" {
  device_group = panos_device_group.hub1.name
  rule {
    name = "inbound pub hc dnat"
    original_packet {
      source_zones          = ["public"]
      destination_zone      = "public"
      source_addresses      = ["azure health probe"]
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
      source_addresses      = ["azure health probe"]
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

#   rule {
#     name = "ext-1"
#     original_packet {
#       source_zones     = ["public"]
#       destination_zone = "public"
#       source_addresses = ["any"]
#       destination_addresses = [
#         panos_address_object.pub_ext_1.name
#       ]
#     }
#     translated_packet {
#       source {
#         dynamic_ip_and_port {
#           interface_address {
#             interface = "ethernet1/2"
#           }
#         }
#       }
#       destination {
#         static_translation {
#           address = module.srv_app11.private_ip_address
#         }
#       }
#     }
#   }
 
  rule {
    name = "outbound"
    original_packet {
      source_zones          = ["private"]
      destination_zone      = "public"
      source_addresses      = ["any"]
      destination_addresses = ["any"]
      service               = "any"
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

  lifecycle { create_before_destroy = true }
}
