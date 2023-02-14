module "vnet_right_env_fw" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name          = "${var.name}-right-env-fw"
  address_space = local.vnet_address_space.right_env_fw

  subnets = {
    "mgmt" = {
      address_prefixes          = [cidrsubnet(local.vnet_address_space.right_env_fw[0], 3, 0)]
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id["mgmt"]
    },
    "core" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_env_fw[0], 3, 1)]
    },
    "env1" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_env_fw[0], 3, 2)]
    },
    "env2" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_env_fw[0], 3, 3)]
    },
    "RouteServerSubnet" = {
      address_prefixes = [cidrsubnet(local.vnet_address_space.right_env_fw[0], 3, 7)]
    },
  }
}



resource "azurerm_public_ip" "right_env_fw_asr" {
  name                = "${var.name}-right-env-fw-asr"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_route_server" "right_env_fw" {
  name                             = "${var.name}-right-env_fw"
  resource_group_name              = azurerm_resource_group.this.name
  location                         = azurerm_resource_group.this.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.right_env_fw_asr.id
  subnet_id                        = module.vnet_right_env_fw.subnets["RouteServerSubnet"].id
  branch_to_branch_traffic_enabled = true
}

resource "azurerm_route_server_bgp_connection" "right_env_fw-right_env_fw1" {
  name            = "right_env_fw1"
  route_server_id = azurerm_route_server.right_env_fw.id
  peer_asn        = var.asn["right_env_fw1"]
  peer_ip         = local.private_ips.right_env_fw1["eth1_1_ip"]
}



module "right_env_fw1" {
  source              = "../modules/vmseries"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  name  = "${var.name}-right-env-fw1"
  panos = var.fw_version

  username = var.username
  password = var.password

  interfaces = {
    mgmt = {
      device_index       = 0
      public_ip          = true
      subnet_id          = module.vnet_right_env_fw.subnets["mgmt"].id
      private_ip_address = local.private_ips.right_env_fw1["mgmt_ip"]
    }
    core = {
      device_index       = 1
      public_ip          = true
      subnet_id          = module.vnet_right_env_fw.subnets["core"].id
      private_ip_address = local.private_ips.right_env_fw1["eth1_1_ip"]
    }
    env1 = {
      device_index       = 2
      subnet_id          = module.vnet_right_env_fw.subnets["env1"].id
      private_ip_address = local.private_ips.right_env_fw1["eth1_2_ip"]
    }
    env2 = {
      device_index       = 3
      subnet_id          = module.vnet_right_env_fw.subnets["env2"].id
      private_ip_address = local.private_ips.right_env_fw1["eth1_3_ip"]
    }
  }

  bootstrap_options = merge(
    var.bootstrap_options["common"],
    var.bootstrap_options["right_env_fw1"],
  )
}


resource "azurerm_virtual_network_peering" "vnet_right_hub-vnet_right_env_fw" {
  name                      = "right-hub--right-env_fw"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.vnet_right_hub.vnet.name
  remote_virtual_network_id = module.vnet_right_env_fw.vnet.id
}

resource "azurerm_virtual_network_peering" "vnet_right_env_fw-vnet_right_hub" {
  name                      = "right-env-fw--right-hub"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.vnet_right_env_fw.vnet.name
  remote_virtual_network_id = module.vnet_right_hub.vnet.id
  depends_on = [
    azurerm_virtual_network_peering.vnet_right_hub-vnet_right_env_fw
  ]
}


/*
locals {
    env_r_test = {
      router_id = var.router_ids["right_env_r_test"]
      local_ip  = local.private_ips.right_env_r_test["eth0"]
      local_asn = var.asn["right_vng"]
      peer1_ip  = local.private_ips.right_env_fw1["eth1_2_ip"]
      peer2_ip  = local.private_ips.right_env_fw2["eth1_2_ip"]
      peer1_asn = var.asn["right_env_fw1"]
      peer2_asn = var.asn["right_env_fw2"]
    }
}

data "template_cloudinit_config" "env_r_test" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = jsonencode({
      write_files = [
        {
          path    = "/etc/bird/bird.conf"
          content = templatefile("${path.module}/init/bird.conf.tfpl", local.env_r_test)
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



module "right_env_r_test" {
  source = "../modules/linux"

  name                = "${var.name}-right-env-r-test"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.vnet_right_env_fw.subnets["core"].id
  private_ip_address  = local.private_ips.right_env_r_test["eth0"]
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  custom_data         = data.template_cloudinit_config.env_r_test.rendered
}
*/