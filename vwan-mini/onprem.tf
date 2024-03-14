module "vnet_onprem" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${local.dname}-onprem"
  address_space = ["10.0.0.0/24"]

  subnets = {
    "public" = {
      idx                       = 0
      network_security_group_id = module.basic.sg_id.mgmt
      associate_nsg             = true
    },
    "private" = {
      idx                       = 1
      network_security_group_id = module.basic.sg_id.wide-open
      associate_nsg             = true
    },
  }
}


data "template_cloudinit_config" "onprem" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = jsonencode({
      write_files = [
        {
          path    = "/etc/bird/bird.conf"
          content = templatefile("${path.module}/init/bird.conf.tfpl", local.linux_init_p.onprem)
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
                  addresses  = local.linux_init_p.onprem.lo_ips
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

module "linux_onprem" {
  source = "../modules/linux"

  name                = "${var.name}-onprem"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_onprem.subnets.public.id
  private_ip_address  = local.private_ip.onprem
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key

  enable_ip_forwarding = true
  custom_data          = data.template_cloudinit_config.onprem.rendered
}
