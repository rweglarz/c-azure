module "vnet_sdwan" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.dname}-sdwan"
  address_space = [local.vnet_cidr.sdwan]

  subnets = {
    "s0" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
    "s1" = {
      idx                       = 1
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
  }
  vnet_peering = {
    transit = {
      peer_vnet_name          = module.vnet_transit.vnet.name
      peer_vnet_id            = module.vnet_transit.vnet.id
      allow_forwarded_traffic = true
    }
  }
}


locals {
  sdwan_bgp_peers = {
  }
  linux_init_p  = {
    sdwan1 = {
      local_ip  = cidrhost(module.vnet_sdwan.subnets.s0.address_prefixes[0], 6)
      local_asn = var.asn.sdwan1
      peers = {
        fw0 = {
          name = "fw0"
          asn = var.asn.fw
          ip = cidrhost(module.vnet_transit.subnets.tosdwan1.address_prefixes[0], 6 + 0)
        }
        fw1 = {
          name = "fw1"
          asn = var.asn.fw
          ip = cidrhost(module.vnet_transit.subnets.tosdwan1.address_prefixes[0], 6 + 1)
        }
      }
      lo_ips = [
        "10.1.1.1/25",
        "10.1.11.1/25",
        "10.1.111.1/25",
      ]
    }
    sdwan2 = {
      local_ip  = cidrhost(module.vnet_sdwan.subnets.s1.address_prefixes[0], 7)
      local_asn = var.asn.sdwan2
      peers = {
        fw0 = {
          name = "fw0"
          asn = var.asn.fw
          ip = cidrhost(module.vnet_transit.subnets.tosdwan2.address_prefixes[0], 6 + 0)
        }
        fw1 = {
          name = "fw1"
          asn = var.asn.fw
          ip = cidrhost(module.vnet_transit.subnets.tosdwan2.address_prefixes[0], 6 + 1)
        }
      }
      lo_ips = [
        "10.2.2.1/25",
        "10.2.22.1/25",
        "10.2.222.1/25",
      ]
    }
  }
}


data "template_cloudinit_config" "sdwan" {
  count = 2
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = jsonencode({
      write_files = [
        {
          path    = "/etc/bird/bird.conf"
          content = templatefile("${path.module}/init/bird.conf.tfpl", count.index==0 ? local.linux_init_p.sdwan1 : local.linux_init_p.sdwan2)
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
                  addresses  = count.index==0 ? local.linux_init_p.sdwan1.lo_ips : local.linux_init_p.sdwan2.lo_ips
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
        "fping",
        "net-tools",
      ]
    })
  }
}



module "linux_sdwan1" {
  source = "../modules/linux"

  name                = "${local.dname}-sdwan1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_sdwan.subnets.s0.id
  private_ip_address  = cidrhost(module.vnet_sdwan.subnets.s0.address_prefixes[0], 6)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key

  enable_ip_forwarding = true
  custom_data          = data.template_cloudinit_config.sdwan[0].rendered
}

module "linux_sdwan2" {
  source = "../modules/linux"

  name                = "${local.dname}-sdwan2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_sdwan.subnets.s1.id
  private_ip_address  = cidrhost(module.vnet_sdwan.subnets.s1.address_prefixes[0], 7)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key

  enable_ip_forwarding = true
  custom_data          = data.template_cloudinit_config.sdwan[1].rendered
}

resource "azurerm_subnet_route_table_association" "sdwan1" {
  subnet_id      = module.vnet_sdwan.subnets.s0.id
  route_table_id = module.basic.route_table_id.private-via-nh.fw_ilb
}

resource "azurerm_subnet_route_table_association" "sdwan2" {
  subnet_id      = module.vnet_sdwan.subnets.s1.id
  route_table_id = module.basic.route_table_id.private-via-nh.fw_ilb
}
