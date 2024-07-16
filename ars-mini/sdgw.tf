locals {
  sdgw_ip = {
    sdgw_A1 = cidrhost(module.vnet_transit.subnets.gwA.address_prefixes[0], 5)
    sdgw_A2 = cidrhost(module.vnet_transit.subnets.gwA.address_prefixes[0], 6)
    sdgw_B  = cidrhost(module.vnet_transit.subnets.gwB.address_prefixes[0], 5)
  }
  sdgw_init = {
    sdgw_A1 = {
      subnet_id = module.vnet_transit.subnets.gwA.id
      router_id = local.sdgw_ip.sdgw_A1
      local_ip  = local.sdgw_ip.sdgw_A1
      local_asn = var.asn.sdgw_A1
      peer1_ip  = local.sdgw_ip.sdgw_A2
      peer2_ip  = local.sdgw_ip.sdgw_B
      peer1_asn = var.asn.sdgw_A2
      peer2_asn = var.asn.sdgw_B
      ars1_ip    = local.private_ips.ars1
      ars2_ip    = local.private_ips.ars2
      ars_asn   = azurerm_route_server.transit.virtual_router_asn
      lo_ips = [
        "10.1.1.1/24",
      ]
    }
    sdgw_A2 = {
      subnet_id = module.vnet_transit.subnets.gwA.id
      router_id = local.sdgw_ip.sdgw_A2
      local_ip  = local.sdgw_ip.sdgw_A2
      local_asn = var.asn.sdgw_A2
      peer1_ip  = local.sdgw_ip.sdgw_A1
      peer2_ip  = local.sdgw_ip.sdgw_B
      peer1_asn = var.asn.sdgw_A1
      peer2_asn = var.asn.sdgw_B
      ars1_ip    = local.private_ips.ars1
      ars2_ip    = local.private_ips.ars2
      ars_asn   = azurerm_route_server.transit.virtual_router_asn
      lo_ips = [
        "10.1.2.1/24",
      ]
    }
    sdgw_B = {
      subnet_id = module.vnet_transit.subnets.gwB.id
      router_id = local.sdgw_ip.sdgw_B
      local_ip  = local.sdgw_ip.sdgw_B
      local_asn = var.asn.sdgw_B
      peer1_ip  = local.sdgw_ip.sdgw_A1
      peer2_ip  = local.sdgw_ip.sdgw_A2
      peer1_asn = var.asn.sdgw_A1
      peer2_asn = var.asn.sdgw_A2
      ars1_ip    = local.private_ips.ars1
      ars2_ip    = local.private_ips.ars2
      ars_asn   = azurerm_route_server.transit.virtual_router_asn
      lo_ips = [
        "10.2.1.1/24",
      ]
    }
  }
}

data "cloudinit_config" "sdgw" {
  for_each      = local.sdgw_init
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
        "netplan apply"
      ]
      packages = [
        "bird",
        "net-tools",
      ]
    })
  }
}

resource "time_sleep" "give_fw_some_time" {
  create_duration = "60s"

  depends_on = [ 
    module.linux_fw 
  ]
}

module "linux_sdgw" {
  for_each = local.sdgw_init
  source   = "../modules/linux"

  name                = format("%s-%s", var.name, replace(each.key, "_", "-"))
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  subnet_id            = each.value.subnet_id
  private_ip_address   = each.value.local_ip
  enable_ip_forwarding = true

  password    = var.password
  public_key  = azurerm_ssh_public_key.rg.public_key
  custom_data = data.cloudinit_config.sdgw[each.key].rendered
  depends_on = [ 
    time_sleep.give_fw_some_time
  ]
}
