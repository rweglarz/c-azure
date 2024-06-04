module "vnet_right_env_sdgw" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${var.name}-right-env-sdgw"
  address_space = local.vnet_address_space.right_env_sdgw

  subnets = {
    "env1" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.right_env_sdgw[0], 3, 2)]
      associate_nsg             = true
      network_security_group_id = module.basic_rg1.sg_id["mgmt"]
    },
    "env2" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.right_env_sdgw[0], 3, 3)]
      attach_nsg                = true
      network_security_group_id = module.basic_rg1.sg_id["mgmt"]
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
      lo_ips = [
        "10.1.1.1/25",
        "10.1.1.3/25",
      ]
    }
    env1_sdgw2 = {
      router_id = var.router_ids["right_env1_sdgw2"]
      local_ip  = local.private_ips.right_env1_sdgw2["eth0"]
      local_asn = var.asn["right_env1_sdgw2"]
      peer1_ip  = local.private_ips.right_env_fw1["eth1_2_ip"]
      peer2_ip  = local.private_ips.right_env_fw2["eth1_2_ip"]
      peer1_asn = var.asn["right_env_fw1"]
      peer2_asn = var.asn["right_env_fw2"]
      lo_ips = [
        "10.1.1.2/25",
        "10.1.1.3/25",
        "10.1.33.1/25",
      ]
    }
  }
}

data "cloudinit_config" "sdgw" {
  for_each      = local.sdgw_init_p
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


module "linux_right_env1_sdgw" {
  for_each = { for k, v in local.sdgw_init_p : k => v if length(regexall("env1", k)) > 0 }
  source   = "../modules/linux"

  name                = format("%s-right-%s", var.name, replace(each.key, "_", "-"))
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  subnet_id            = module.vnet_right_env_sdgw.subnets["env1"].id
  private_ip_address   = each.value.local_ip
  enable_ip_forwarding = true

  password    = var.password
  public_key  = azurerm_ssh_public_key.rg1.public_key
  custom_data = data.cloudinit_config.sdgw[each.key].rendered
}


resource "azurerm_virtual_network_peering" "vnet_right_env_fw-vnet_right_env_sdgw" {
  name                      = "right-env-fw--right-env-sdgw"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = module.vnet_right_env_fw.vnet.name
  remote_virtual_network_id = module.vnet_right_env_sdgw.vnet.id
}

resource "azurerm_virtual_network_peering" "vnet_right_env_sdgw-vnet_right_env_fw" {
  name                      = "right-env-sdgw--right-env-fw"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = module.vnet_right_env_sdgw.vnet.name
  remote_virtual_network_id = module.vnet_right_env_fw.vnet.id
  depends_on = [
    azurerm_virtual_network_peering.vnet_right_env_fw-vnet_right_env_sdgw
  ]
}


resource "azurerm_route_table" "right_env1_sdgw" {
  name                = "${var.name}-right-env1-sdgw"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
}

resource "azurerm_route" "right_env1_sdgw" {
  for_each = {
    envs = "10.0.0.0/8"
    left = "172.16.0.0/21"
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.rg1.name
  route_table_name       = azurerm_route_table.right_env1_sdgw.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.private_ips.right_env_fw1["eth1_2_ip"]
}

resource "azurerm_subnet_route_table_association" "right_env1_sdgw" {
  subnet_id      = module.vnet_right_env_sdgw.subnets["env1"].id
  route_table_id = azurerm_route_table.right_env1_sdgw.id
}
