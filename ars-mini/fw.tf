data "cloudinit_config" "fw" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = jsonencode({
      write_files = [
        {
          path    = "/etc/cloud/cloud.cfg.d/99-custom-networking.cfg"
          content = "network: {config: disabled}"
        },
        {
          path        = "/etc/nftables.conf"
          content     = file("${path.module}/init/nftables.conf")
          permissions = "0744"
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
            }
          })
        },
      ]
      runcmd = [
        "netplan apply",
        "sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf",
        "/usr/sbin/sysctl -p",
        "/usr/sbin/nft -f /etc/nftables.conf",
      ]
      packages = [
        "bird",
        "fping",
        "net-tools",
      ]
    })
  }
}


module "linux_fw" {
  source   = "../modules/linux"

  name                = "${var.name}-linux-fw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  subnet_id            = module.vnet_transit.subnets.data.id
  private_ip_address   = local.private_ips.fw
  enable_ip_forwarding = true

  password    = var.password
  public_key  = azurerm_ssh_public_key.rg.public_key
  custom_data = data.cloudinit_config.fw.rendered
}
