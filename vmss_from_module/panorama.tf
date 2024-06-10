data "panos_device_group" "this" {
  name = "azure-vmss-m"
}

resource "panos_panorama_template_stack" "this" {
  name = "azure-vmss-m"
  templates = [
    "azure-2-if",
    "vm common"
  ]
  description = "pat:acp"

  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_template_variable" "eth1_1_gw" {
  template_stack = panos_panorama_template_stack.this.name
  name           = "$eth1_1_gw"
  type           = "ip-netmask"
  value          = cidrhost(module.vnet_sec.subnets["public"].address_prefixes[0], 1)

  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_template_variable" "eth1_2_gw" {
  template_stack = panos_panorama_template_stack.this.name
  name           = "$eth1_2_gw"
  type           = "ip-netmask"
  value          = cidrhost(module.vnet_sec.subnets["private"].address_prefixes[0], 1)

  lifecycle { create_before_destroy = true }
}

resource "panos_address_object" "pub_ext_1" {
  device_group = data.panos_device_group.this.name

  name  = "pub-ext-1"
  value = azurerm_public_ip.fw_lb_ext_1.ip_address

  lifecycle { create_before_destroy = true }
}

resource "panos_address_object" "pub_ext_2" {
  device_group = data.panos_device_group.this.name

  name  = "pub-ext-2"
  value = azurerm_public_ip.fw_lb_ext_2.ip_address

  lifecycle { create_before_destroy = true }
}

resource "panos_security_rule_group" "this" {
  device_group = data.panos_device_group.this.name

  rule {
    name                  = "Azure-HC"
    source_zones          = ["any"]
    source_addresses      = ["azure health probe"]
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = [panos_panorama_service_object.hc.name]
    categories            = ["any"]
    action                = "allow"
    log_setting           = "panka"
  }
  rule {
    name                  = "ext-1"
    source_zones          = ["public"]
    source_addresses      = ["safe ips"]
    source_users          = ["any"]
    destination_zones     = ["private"]
    destination_addresses = [panos_address_object.pub_ext_1.name]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    group                 = "almost default"
    action                = "allow"
    log_setting           = "panka"
  }
  rule {
    name                  = "ext-2"
    source_zones          = ["public"]
    source_addresses      = ["safe ips"]
    source_users          = ["any"]
    destination_zones     = ["private"]
    destination_addresses = [panos_address_object.pub_ext_2.name]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    group                 = "almost default"
    log_setting           = "panka"
    action                = "allow"
  }
  rule {
    name                  = "appgws"
    source_zones          = ["public"]
    source_addresses      = [
      module.vnet_sec.subnets.appgw1.address_prefixes[0],
      module.vnet_sec.subnets.appgw2.address_prefixes[0],
    ]
    source_users          = ["any"]
    destination_zones     = ["private"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
    group                 = "almost default"
    log_setting           = "panka"
  }
  rule {
    name                  = "from internal"
    source_zones          = ["private"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = "panka"
  }


  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_service_object" "hc" {
  device_group     = data.panos_device_group.this.name
  name             = "tcp-health-check"
  protocol         = "tcp"
  destination_port = 54321
  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_service_object" "tcp_81" {
  device_group     = data.panos_device_group.this.name
  name             = "tcp-81"
  protocol         = "tcp"
  destination_port = 81
  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_service_object" "tcp_82" {
  device_group     = data.panos_device_group.this.name
  name             = "tcp-82"
  protocol         = "tcp"
  destination_port = 82
  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_nat_rule_group" "this" {
  device_group = data.panos_device_group.this.name
  rule {
    name = "inbound pub hc dnat"
    original_packet {
      source_zones          = ["public"]
      destination_zone      = "public"
      source_addresses      = ["azure health probe"]
      destination_addresses = ["any"]
      service               = panos_panorama_service_object.hc.name
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
      service               = panos_panorama_service_object.hc.name
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
    name = "ext-1"
    original_packet {
      source_zones     = ["public"]
      destination_zone = "public"
      source_addresses = ["any"]
      destination_addresses = [
        panos_address_object.pub_ext_1.name
      ]
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
          address = module.srv_app11.private_ip_address
        }
      }
    }
  }
  rule {
    name = "ext-2"
    original_packet {
      source_zones     = ["public"]
      destination_zone = "public"
      source_addresses = ["any"]
      destination_addresses = [
        panos_address_object.pub_ext_2.name
      ]
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
          address = module.srv_app2.private_ip_address
        }
      }
    }
  }
  rule {
    name = "appgw-1"
    original_packet {
      source_zones     = ["public"]
      destination_zone = "public"
      source_addresses = ["any"]
      destination_addresses = ["any"]
      service = panos_panorama_service_object.tcp_81.name
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
        dynamic_translation {
          address = module.srv_app11.private_ip_address
          port = 80
        }
      }
    }
  }
  rule {
    name = "appgw-2"
    original_packet {
      source_zones     = ["public"]
      destination_zone = "public"
      source_addresses = ["any"]
      destination_addresses = ["any"]
      service = panos_panorama_service_object.tcp_82.name
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
        dynamic_translation {
          address = module.srv_app2.private_ip_address
          port = 80
        }
      }
    }
  }
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
