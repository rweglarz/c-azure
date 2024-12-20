locals {
  vm_ip = {
    onprem     = cidrhost(module.vnet_transit.subnets.onprem.address_prefixes[0], 5)
    fw_transit = cidrhost(module.vnet_transit.subnets.fw.address_prefixes[0], 5)
    fw_sec     = cidrhost(module.vnet_sec.subnets.fw.address_prefixes[0], 5)
    avs        = cidrhost(module.vnet_avs.subnets.avs.address_prefixes[0], 5)
  }
  vm_init = {
    onprem = {
      subnet_id = module.vnet_transit.subnets.onprem.id
      router_id = local.vm_ip.onprem
      local_ip  = local.vm_ip.onprem
      local_asn = var.asn.onprem
      local_id  = local.vm_ip.onprem
      vpn_psk   = var.psk
      peers = {
        transit_ars_1 = {
          peer_ip  = tolist(azurerm_route_server.transit.virtual_router_ips)[0]
          peer_asn = 65515
        }
        transit_ars_2 = {
          peer_ip  = tolist(azurerm_route_server.transit.virtual_router_ips)[1]
          peer_asn = 65515
        }
        sec_ars_1 = {
          peer_ip  = tolist(azurerm_route_server.sec.virtual_router_ips)[0]
          peer_asn = 65515
        }
        sec_ars_2 = {
          peer_ip  = tolist(azurerm_route_server.sec.virtual_router_ips)[1]
          peer_asn = 65515
        }
      }
      tunnels = {}
      lo_ips = [
        "10.1.0.1/24",
        "10.1.2.1/24",
      ]
    }
    fw_transit = {
      subnet_id = module.vnet_transit.subnets.fw.id
      router_id = local.vm_ip.fw_transit
      local_ip  = local.vm_ip.fw_transit
      local_id  = local.vm_ip.fw_transit
      local_asn = var.asn.fw_transit
      vpn_psk   = var.psk
      peers = {}
      tunnels = {}
      lo_ips = [
        "10.9.2.1/24",
      ]
    }
    fw_sec = {
      subnet_id = module.vnet_sec.subnets.fw.id
      router_id = local.vm_ip.fw_sec
      local_ip  = local.vm_ip.fw_sec
      local_id  = local.vm_ip.fw_sec
      local_asn = var.asn.fw_sec
      vpn_psk   = var.psk
      peers = {}
      tunnels = {}
      lo_ips = [
        "10.9.2.1/24",
      ]
    }
    avs = {
      subnet_id = module.vnet_avs.subnets.avs.id
      router_id = local.vm_ip.avs
      local_ip  = local.vm_ip.avs
      local_asn = var.asn.avs
      vpn_psk   = var.psk
      local_id  = azurerm_public_ip.avs.ip_address
      public_ip_id = azurerm_public_ip.avs.id
      associate_public_ip = false
      peers = {
        vngi0 = {
          peer_ip  = azurerm_virtual_network_gateway.transit.bgp_settings[0].peering_addresses[0].default_addresses[0]
          peer_asn = 65515
        }
        vngi1 = {
          peer_ip  = azurerm_virtual_network_gateway.transit.bgp_settings[0].peering_addresses[1].default_addresses[0]
          peer_asn = 65515
        }
      }
      tunnels = {
        vngi0 = {
          peer_ip = azurerm_virtual_network_gateway.transit.bgp_settings[0].peering_addresses[0].tunnel_ip_addresses[0]
          if_id   = 101
        }
        vngi1 = {
          peer_ip = azurerm_virtual_network_gateway.transit.bgp_settings[0].peering_addresses[1].tunnel_ip_addresses[0]
          if_id   = 102
        }
      }
      lo_ips = [
        "10.1.1.1/24",
        "10.1.3.1/24",
      ]
    }
  }
}

data "cloudinit_config" "vm" {
  for_each      = local.vm_init
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = jsonencode({
      write_files = [
        {
          path    = "/etc/bird/bird.conf"
          content = templatefile("${path.module}/init/bird.conf.tfpl", each.value)
        },
        {
          path        = "/var/lib/cloud/scripts/per-once/bird.sh"
          content     = file("${path.module}/init/bird.sh")
          permissions = "0744"
        },
        {
          path    = "/etc/swanctl/swanctl.conf"
          content = templatefile("${path.module}/init/swanctl.conf.tfpl", each.value)
        },
        {
          path    = "/etc/cloud/cloud.cfg.d/99-custom-networking.cfg"
          content = "network: {config: disabled}"
        },
        {
          path = "/etc/netplan/90-local.yaml"
          content = yamlencode({
            network = {
              version = 2
              ethernets = {
                eth0 = {
                  dhcp4 = "yes"
                }
              }
              bridges = {
                db0 = {
                  dhcp4      = "no"
                  dhcp6      = "no"
                  accept-ra  = "no"
                  interfaces = []
                  addresses  = each.value.lo_ips
                }
              }
            }
          })
        },
      ]
      runcmd = [
        "netplan apply",
        "swanctl --load-all",
      ]
      packages = [
        "bird",
        "fping",
        "net-tools",
        "strongswan-charon",
        "strongswan-swanctl",
      ]
    })
  }
}

resource "azurerm_public_ip" "avs" {
  name                = "${local.name}-avs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}



module "vm_linux" {
  for_each = local.vm_init
  source   = "../modules/linux"

  name                = format("%s-%s", local.name, replace(each.key, "_", "-"))
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  subnet_id            = each.value.subnet_id
  private_ip_address   = each.value.local_ip
  enable_ip_forwarding = true

  password    = var.password
  public_key  = azurerm_ssh_public_key.rg.public_key
  custom_data = data.cloudinit_config.vm[each.key].rendered
  associate_public_ip = try(each.value.associate_public_ip, true)
  public_ip_id = try(each.value.public_ip_id, null)
}
