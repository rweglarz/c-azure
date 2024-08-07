resource "panos_panorama_template_stack" "fw" {
  for_each = var.vmseries

  name         = "azure-ha-fast-${each.key}"
  default_vsys = "vsys1"
  templates = [
    module.cfg_fw.template_name,
    "vm-ha-ha2-eth1-3",
    "vm common",
  ]
  description = "pat:acp"
}

module "cfg_fw" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-ha-fast-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips         = ["$eth1_1_ipm"]
      zone               = "public"
      management_profile = "hc-azure"
    }
    "ethernet1/2" = {
      static_ips         = ["$eth1_2_ipm"]
      zone               = "private"
      management_profile = "ping"
    }
    "loopback.1" = {
      static_ips         = [module.slb_fw_ext.frontend_ip_configs.ext-fw]
      zone               = "public"
    }
    "loopback.999" = {
      static_ips         = ["192.0.2.1"]
      zone               = "healthcheck"
      management_profile = "hc-azure"
    }
    "tunnel.10" = {
      zone               = "vpn"
    }
  }
  variables = {
    eth1_1_ipm = "192.168.1.1/32"
    eth1_2_ipm = "192.168.1.2/32"
    eth1_2_ip  = "192.168.1.2"
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets.public.address_prefixes[0], 1)
    }
    r10_8 = {
      destination = "10.0.0.0/8"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets.private.address_prefixes[0], 1)
    }
    r172_12 = {
      destination = "172.16.0.0/12"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets.private.address_prefixes[0], 1)
    }
    azure_hc_1 = {
      destination = "168.63.129.16/32"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets.public.address_prefixes[0], 1)
    }
    azure_hc_2 = {
      destination = "168.63.129.16/32"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets.private.address_prefixes[0], 1)
    }
    vpn = {
      destination = var.cidr_vpn
      interface   = "tunnel.10"
    }
  }
  enable_ecmp = true
}


locals {
  subnet_prefix_length = 27
  fw_v = {
    for fw,v in module.fw : fw => {
        "$ha1-peer-ip"  = local.private_ips[fw].mgmt-peer
        "$ha2-local-ip" = local.private_ips[fw].ha2
        "$ha2-gw"       = local.private_ips[fw].ha2-gw
        "$eth1_1_ipm"   = format("%s/%s", local.private_ips[fw].public, local.subnet_prefix_length)
        "$eth1_2_ipm"   = format("%s/%s", local.private_ips[fw].private, local.subnet_prefix_length)
      }
  }
  fw_v_flat = flatten([
    for fwn,fwv in local.fw_v : [
      for vn,vv in fwv: {
        name = vn
        value = vv
        ts = panos_panorama_template_stack.fw[fwn].name
        fwn = "fw${fwn}-${vn}"
      }
    ]
  ])
}


resource "panos_panorama_template_variable" "this" {
  for_each = { for k,v in local.fw_v_flat: v.fwn => v}
  template_stack = each.value.ts
  name           = each.value.name
  type           = "ip-netmask"
  value          = each.value.value

  lifecycle { create_before_destroy = true }
}



resource "panos_panorama_service_object" "azure_fha_ssh_22" {
  device_group     = "azure-ha-fast"
  name             = "azure-fha-ssh-22"
  protocol         = "tcp"
  destination_port = "22"

  lifecycle { create_before_destroy = true }
}


resource "panos_security_rule_group" "azure_fha" {
  position_keyword = "bottom"
  device_group     = "azure-ha-fast"
  rule {
    name                  = "ipsec ping allow"
    audit_comment         = ""
    source_zones          = ["any"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications = [
      "ipsec",
      "ping",
    ]
    services    = ["application-default"]
    categories  = ["any"]
    action      = "allow"
    log_setting = "panka"
  }
  rule {
    name                  = "from servers"
    audit_comment         = ""
    source_zones          = ["private"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = "panka"
  }
}

resource "panos_panorama_nat_rule_group" "this" {
  device_group = "azure-ha-fast"
  rule {
    name = "inbound private hc dnat"
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
  rule {
    name = "default outbound snat"
    original_packet {
      source_zones          = ["private"]
      destination_zone      = "public"
      source_addresses      = ["172.16.0.0/12"]
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
#   rule {
#     name = "inbound srv0"
#     original_packet {
#       source_zones          = [panos_zone.azure_fha_internet.name]
#       destination_zone      = panos_zone.azure_fha_internet.name
#       source_addresses      = ["any"]
#       destination_addresses = [azurerm_public_ip.ingress.ip_address]
#       service               = panos_panorama_service_object.azure_fha_ssh_22.name
#     }
#     translated_packet {
#       source {
#       }
#       destination {
#         static_translation {
#           address = module.srv0.private_ip_address
#         }
#       }
#     }
#   }
}


module "tunnel-linux" {
  source = "../../ce-common/modules/pan_tunnel"

  peers = {
    left = {
      name = "fw"
      ip   = module.slb_fw_ext.frontend_ip_configs.ext-fw
      interface = {
        phys   = "loopback.1"
        tunnel = "tunnel.10"
      }
      id = {
        type  = "ipaddr"
        value = module.slb_fw_ext.frontend_ip_configs.ext-fw
      }
      template = module.cfg_fw.template_name
    }
    right = {
      name = "linux"
      ip   = module.vpn_h.public_ip
      interface = {
        phys   = "loopback.1"
        tunnel = "tunnel.10"
      }
      id = {
        type  = "ipaddr"
        value = module.vpn_h.public_ip
      }
      template = module.cfg_fw.template_name
      do_not_configure = true
    }
  }
  psk = var.vpn_psk
}
