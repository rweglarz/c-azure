data "template_cloudinit_config" "hub1_sdwan" {
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
          content = templatefile("${path.module}/init/bird.conf.tfpl", count.index==0 ? local.linux_init_p.sdwan1 : local.linux_init_p.sdwan1)
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

module "linux_hub1_sdwan" {
  count = 2
  source = "../modules/linux"

  name                = "${var.name}-hub1-sdwan-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_hub1_sdwan.subnets.s0.id
  private_ip_address  = count.index==0 ? local.private_ip.hub1_sdwan1 : local.private_ip.hub1_sdwan2
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key

  enable_ip_forwarding = true
  custom_data          = data.template_cloudinit_config.hub1_sdwan[count.index].rendered
}
