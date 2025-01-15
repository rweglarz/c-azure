resource "azurerm_public_ip" "fw_ext_snat_1" {
  name                = "${var.name}-fw-ext-nat-1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}



module "slb_fw_ext" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-swfw-modules//modules/loadbalancer?ref=v3.2.1"
  #source = "PaloAltoNetworks/swfw-modules/azurerm//modules/loadbalancer"
  #version = "3.0.2"

  name                = "${var.name}-fw-ext"
  resource_group_name = azurerm_resource_group.rg.name
  region              = azurerm_resource_group.rg.location

  backend_name = "fws"

  frontend_ips = {
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
    ext-2 = {
      name             = "ext-2-n"
      public_ip_name   = "${var.name}-ext-2"
      create_public_ip = true
      in_rules = {
        http = {
          name     = "ext-2-r"
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
          allocated_outbound_ports = 8192
          idle_timeout_in_minutes  = 10
        }
      }
    }
  }

  health_probes = {
    mdefault = {
      name     = "r-default"
      protocol = "Http"
      port     = 54321

      request_path        = "/unauth/php/health.php"
      probe_threshold     = 3
      interval_in_seconds = 5
    }
  }

  depends_on = [
    azurerm_public_ip.fw_ext_snat_1,
  ]
}



module "slb_fw_int" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-swfw-modules//modules/loadbalancer?ref=v3.2.1"
  #source = "PaloAltoNetworks/swfw-modules/azurerm//modules/loadbalancer"
  #version = "3.0.2"

  name                = "${var.name}-fw-int"
  resource_group_name = azurerm_resource_group.rg.name
  region              = azurerm_resource_group.rg.location

  backend_name = "fws"

  frontend_ips = {
    ha = {
      name               = "ha-n"
      subnet_id          = module.vnet_sec.subnets["private"].id
      private_ip_address = cidrhost(module.vnet_sec.subnets["private"].address_prefixes[0], 5)
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
      name     = "r-default"
      protocol = "Http"
      port     = 54321

      request_path        = "/unauth/php/health.php"
      probe_threshold     = 3
      interval_in_seconds = 5
    }
  }
}
