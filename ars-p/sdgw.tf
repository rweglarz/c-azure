resource "azurerm_public_ip" "partner_sdgw" {
  for_each            = toset(["partner1", "partner2"])
  name                = "${var.name}-sdgw-${each.key}"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

locals {
  partners = {
    partner1 = {
      subnet_id          = module.vnet_partner1.subnets["sdgw"].id
      private_ip_address = cidrhost(module.vnet_partner1.subnets["sdgw"].address_prefixes[0], 5)
      asn                = var.asn["partner1"]
      lo_ips             = ["10.22.1.254/24"]
      bgp_source_ip      = "169.254.31.1"
      router_id          = cidrhost(module.vnet_partner1.subnets["sdgw"].address_prefixes[0], 5)
      local_ip           = cidrhost(module.vnet_partner1.subnets["sdgw"].address_prefixes[0], 5)
      local_id           = azurerm_public_ip.partner_sdgw["partner1"].ip_address
      public_ip_id       = azurerm_public_ip.partner_sdgw["partner1"].id

      peers = {
        vng_c1 = {
          peer_ip  = "169.254.21.5"
          peer_asn = var.asn["ars"]
          if_id    = 101
        }
        vng_c2 = {
          peer_ip  = "169.254.21.7"
          peer_asn = var.asn["ars"]
          if_id    = 102
        }
      }

      tunnels = {
        vng_c1 = {
          peer_ip = azurerm_public_ip.vng["c1"].ip_address
          if_id   = 101
        }
        vng_c2 = {
          peer_ip = azurerm_public_ip.vng["c2"].ip_address
          if_id   = 102
        }
      }
    }
    partner2 = {
      subnet_id          = module.vnet_partner2.subnets["sdgw"].id
      private_ip_address = cidrhost(module.vnet_partner2.subnets["sdgw"].address_prefixes[0], 5)
      asn                = var.asn["partner2"]
      lo_ips             = ["10.22.2.254/24"]
      bgp_source_ip      = "169.254.32.1"
      router_id          = cidrhost(module.vnet_partner2.subnets["sdgw"].address_prefixes[0], 5)
      local_ip           = cidrhost(module.vnet_partner2.subnets["sdgw"].address_prefixes[0], 5)
      local_id           = azurerm_public_ip.partner_sdgw["partner2"].ip_address
      public_ip_id       = azurerm_public_ip.partner_sdgw["partner2"].id

      peers = {
        vng_c1 = {
          peer_ip  = "169.254.21.6"
          peer_asn = var.asn["ars"]
          if_id    = 101
        }
        vng_c2 = {
          peer_ip  = "169.254.21.8"
          peer_asn = var.asn["ars"]
          if_id    = 102
        }
      }

      tunnels = {
        vng_c1 = {
          peer_ip = azurerm_public_ip.vng["c1"].ip_address
          if_id   = 101
        }
        vng_c2 = {
          peer_ip = azurerm_public_ip.vng["c2"].ip_address
          if_id   = 102
        }
      }
    }
  }
}

data "cloudinit_config" "partner_sdgw" {
  for_each      = local.partners
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = jsonencode({
      write_files = [
        {
          path    = "/etc/bird/bird.conf"
          content = templatefile("${path.module}/init/bird-partner.conf.tfpl", {
            router_id     = each.value.router_id
            local_asn     = each.value.asn
            bgp_source_ip = each.value.bgp_source_ip
            peers         = each.value.peers
          })
        },
        {
          path        = "/var/lib/cloud/scripts/per-once/bird.sh"
          content     = file("${path.module}/init/bird.sh")
          permissions = "0744"
        },
        {
          path        = "/var/lib/cloud/scripts/per-boot/vpn.sh"
          content     = templatefile("${path.module}/init/vpn.sh.tfpl", each.value)
          permissions = "0744"
        },
        {
          path    = "/etc/swanctl/swanctl.conf"
          content = templatefile("${path.module}/init/swanctl.conf.tfpl", {
            local_ip  = each.value.private_ip_address
            local_id  = each.value.local_id
            vpn_psk   = random_bytes.psk.hex
            tunnels   = each.value.tunnels
          })
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
        "/var/lib/cloud/scripts/per-boot/vpn.sh",
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

module "linux_sdgw" {
  for_each = local.partners
  source   = "../modules/linux"

  name                = format("%s-sdgw-%s", var.name, each.key)
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  subnet_id            = each.value.subnet_id
  private_ip_address   = each.value.private_ip_address
  enable_ip_forwarding = true

  password    = var.password
  public_key  = azurerm_ssh_public_key.rg1.public_key
  custom_data = data.cloudinit_config.partner_sdgw[each.key].rendered

  associate_public_ip = true
  create_public_ip    = false
  public_ip_id        = each.value.public_ip_id
}

resource "azurerm_local_network_gateway" "partner" {
  for_each            = local.partners
  name                = "${var.name}-${each.key}"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  gateway_address     = each.value.local_id
  bgp_settings {
    asn                 = each.value.asn
    bgp_peering_address = each.value.bgp_source_ip
  }
}

resource "azurerm_virtual_network_gateway_connection" "partner" {
  for_each            = local.partners
  name                = "${var.name}-${each.key}"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.transit.id
  local_network_gateway_id   = azurerm_local_network_gateway.partner[each.key].id

  bgp_enabled = true
  custom_bgp_addresses {
    primary   = each.value.peers.vng_c1.peer_ip
    secondary = each.value.peers.vng_c2.peer_ip
  }
  shared_key = random_bytes.psk.hex
}
