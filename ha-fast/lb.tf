resource "azurerm_public_ip" "fw_ext_snat_1" {
  name                = "${var.name}-fw-ext-nat-1"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}



module "slb_fw_ext" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-swfw-modules//modules/loadbalancer?ref=v3.0.2"

  name                = "${var.name}-fw-ext"
  resource_group_name = azurerm_resource_group.this.name
  region              = azurerm_resource_group.this.location

  backend_name = "fws"

  frontend_ips = {
    ext-fw = {
      name             = "ext-fw"
      public_ip_name   = "${var.name}-ext-fw"
      create_public_ip = true
      in_rules = {
        udp500 = {
          name     = "ext-fw-500"
          port     = 500
          protocol = "Udp"
          health_probe_key = "mdefault"
        }
        udp4500 = {
          name     = "ext-fw-4500"
          port     = 4500
          protocol = "Udp"
          health_probe_key = "mdefault"
        }
      }
    }
    ext-1 = {
      name             = "ext-1-n"
      public_ip_name   = "${var.name}-ext-1"
      create_public_ip = true
      in_rules = {
        http = {
          name     = "ext-1-r"
          port     = 80
          protocol = "Tcp"
          health_probe_key = "mdefault"
        }
      }
    }
    out = {
      name             = "outbound"
      public_ip_name   = azurerm_public_ip.fw_ext_snat_1.name
      create_public_ip = false
      out_rules = {
        out = {
          name                     = "out"
          protocol                 = "All"
          allocated_outbound_ports = 32000
          idle_timeout_in_minutes  = 5
        }
      }
    }
  }

  health_probes = {
    mdefault = {
      name     = "mdefault"
      protocol = "Http"
      port     = 80

      request_path        = "/unauth/php/health.php"
      probe_threshold     = 2
      interval_in_seconds = 5
    }
  }

  depends_on = [
    azurerm_public_ip.fw_ext_snat_1,
  ]
}



module "slb_fw_int" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-swfw-modules//modules/loadbalancer?ref=v3.0.2"

  name                = "${var.name}-fw-int"
  resource_group_name = azurerm_resource_group.this.name
  region              = azurerm_resource_group.this.location

  backend_name = "fws"

  frontend_ips = {
    ha = {
      name               = "ha-n"
      subnet_id          = module.vnet_transit.subnets.private.id
      private_ip_address = cidrhost(module.vnet_transit.subnets.private.address_prefixes[0], 4)
      in_rules = {
        har = {
          name             = "ha-r"
          port             = 0
          protocol         = "All"
          health_probe_key = "mdefault"
        }
      }
    }
  }

  health_probes = {
    mdefault = {
      name     = "mdefault"
      protocol = "Http"
      port     = 54321

      request_path        = "/unauth/php/health.php"
      probe_threshold     = 2
      interval_in_seconds = 5
    }
  }
}
