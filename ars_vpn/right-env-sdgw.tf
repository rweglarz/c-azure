module "vnet_right_env_sdgw" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = "${var.name}-right-env-sdgw"
  address_space = local.vnet_address_space.right_env_sdgw

  subnets = {
    "env1" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.right_env_sdgw[0], 3, 2)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "env2" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.right_env_sdgw[0], 3, 3)]
      attach_nsg                = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "RouteServerSubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_env_sdgw[0], 3, 7)]
    },
  }
}


locals {
  sdgw_init_p = {
    env1_sdgw1 = {
      router_id = var.router_ids["right_env1_sdgw1"]
      local_ip  = local.private_ips.right_env1_sdgw1["eth0"]
      local_asn = var.asn["right_env1_sdgw1"]
      peer1_ip  = local.private_ips.right_env_fw1["eth1_2_ip"]
      peer2_ip  = local.private_ips.right_env_fw2["eth1_2_ip"]
      peer1_asn = var.asn["right_env_fw1"]
      peer2_asn = var.asn["right_env_fw2"]
    }
  }
}

data "template_cloudinit_config" "env1_sdgw1" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = jsonencode({
      write_files = [
        {
          path    = "/etc/bird/bird.conf"
          content = templatefile("${path.module}/init/bird.conf.tfpl", local.sdgw_init_p.env1_sdgw1)
        },
        {
          path        = "/var/lib/cloud/scripts/per-once/bird.sh"
          content     = file("${path.module}/init/bird.sh")
          permissions = "0744"
        },
      ]
      packages = [
        "bird",
        "net-tools",
      ]
    })
  }
}


module "right_env1_sdgw1" {
  source = "../modules/linux"

  name                = "${var.name}-right-env1-sdgw1"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.vnet_right_env_sdgw.subnets["env1"].id
  private_ip_address  = local.private_ips.right_env1_sdgw1["eth0"]
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  custom_data         = data.template_cloudinit_config.env1_sdgw1.rendered
}
