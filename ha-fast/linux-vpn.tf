module "vnet_vpn" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = "${var.name}-vpn"
  address_space = [var.cidr_vpn]

  subnets = {
    "s0" = {
      idx = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.vpn
    },
  }
}


locals {
    linux_vpn = {
      lo_ips = [
        "192.168.1.1/32"
      ]
      private_ip = cidrhost(module.vnet_vpn.subnets.s0.address_prefixes[0], 5)
      local_ip = cidrhost(module.vnet_vpn.subnets.s0.address_prefixes[0], 5)
      local_id = module.vpn_h.public_ip
      peer_ip = module.slb_fw_ext.frontend_ip_configs.ext-fw
      vpn_psk = var.vpn_psk
    }
}

data "cloudinit_config" "linux" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = yamlencode({
      write_files = [
        {
          path    = "/etc/swanctl/swanctl.conf"
          content = templatefile("${path.module}/init/swanctl.conf.tfpl", local.linux_vpn)
        },
        {
          path    = "/etc/cloud/cloud.cfg.d/99-custom-networking.cfg"
          content = "network: {config: disabled}"
        },
        {
          path    = "/etc/systemd/network/xfrm101.netdev"
          content = <<-EOT
            [NetDev]
            Name=xfrm101
            Kind=xfrm

            [Xfrm]
            InterfaceId=101
            EOT
        },
        {
          path    = "/etc/systemd/network/xfrm101.network"
          content = <<-EOT
            [Match]
            Name=lo

            [Network]
            Xfrm=xfrm101
            EOT
        },
        {
          path    = "/etc/systemd/network/xfrm101-route.network"
          content = <<-EOT
            [Match]
            Name=xfrm101

            [Route]
            Destination=172.16.0.0/12
            Scope=link
            EOT
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
                  addresses  = local.linux_vpn.lo_ips
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
        "fping",
        "net-tools",
        "strongswan",
        "strongswan-swanctl",
      ]
    })
  }
}


module "vpn_h" {
  source = "../modules/linux"

  name                = "${var.name}-vpn"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.vnet_vpn.subnets.s0.id
  private_ip_address  = local.linux_vpn.private_ip
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  custom_data         = data.cloudinit_config.linux.rendered
}
