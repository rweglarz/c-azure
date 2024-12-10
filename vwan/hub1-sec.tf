module "hub1_sec" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-hub1-sec"
  address_space = [local.vnet_cidr.hub1_sec]
  bgp_community = "12076:20019"

  subnets = {
    "mgmt" = {
      idx                       = 0
      network_security_group_id = module.basic_rg1.sg_id.mgmt
      associate_nsg             = true
    },
    "public" = {
      idx                       = 1
      network_security_group_id = module.basic_rg1.sg_id.wide-open
      associate_nsg             = true
    },
    "private" = {
      idx                       = 2
      network_security_group_id = module.basic_rg1.sg_id.wide-open
      associate_nsg             = true
    },
  }
}


resource "azurerm_public_ip" "hub1_sec_ngw" {
  name                = "${var.name}-hub1-sec-nat-gateway"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "hub1_sec_ngw" {
  name                    = "${var.name}-hub1-sec-nat-gateway"
  location                = azurerm_resource_group.rg1.location
  resource_group_name     = azurerm_resource_group.rg1.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "hub1_sec_ngfw" {
  nat_gateway_id       = azurerm_nat_gateway.hub1_sec_ngw.id
  public_ip_address_id = azurerm_public_ip.hub1_sec_ngw.id
}

resource "azurerm_subnet_nat_gateway_association" "hub1_sec_mgmt" {
  subnet_id      = module.hub1_sec.subnets.mgmt.id
  nat_gateway_id = azurerm_nat_gateway.hub1_sec_ngw.id
}



resource "azurerm_public_ip" "hub1_sec_snat" {
  name                = "${var.name}-hub1-sec-snat"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}




module "elb_hub1_sec" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-swfw-modules//modules/loadbalancer?ref=v3.2.1"

  name                = "${var.name}-elb-hub1-sec"
  resource_group_name = azurerm_resource_group.rg1.name
  region              = azurerm_resource_group.rg1.location

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
    out = {
      name             = "outbound"
      public_ip_name   = azurerm_public_ip.hub1_sec_snat.name
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
    azurerm_public_ip.hub1_sec_snat,
  ]
}




module "ilb_hub1_sec" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-swfw-modules//modules/loadbalancer?ref=v3.2.1"

  name                = "${var.name}-ilb-hub1-sec"
  resource_group_name = azurerm_resource_group.rg1.name
  region              = azurerm_resource_group.rg1.location

  backend_name = "fws"

  frontend_ips = {
    ha = {
      name               = "ha-n"
      subnet_id          = module.hub1_sec.subnets.private.id
      private_ip_address = local.private_ip.hub1_sec_ilb
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

resource "azurerm_application_insights" "hub1_sec_fw" {
  name                = "${var.name}-hub1-fw-insights"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  application_type    = "other"
}

module "vmss_hub1_sec_fw" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-swfw-modules//modules/vmss?ref=v3.2.1"

  name                = "${var.name}-hub1-fw"
  region              = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  authentication = {
    username                        = var.username
    password                        = var.password
    disable_password_authentication = false
  }

  interfaces = [
    {
      name       = "mgmt"
      subnet_id  =  module.hub1_sec.subnets.mgmt.id
    },
    {
      name                = "public"
      subnet_id           =  module.hub1_sec.subnets.public.id
      lb_backend_pool_ids = [
        module.elb_hub1_sec.backend_pool_id
      ]
      appgw_backend_pool_ids = []
    },
    {
      name       = "private"
      subnet_id  =  module.hub1_sec.subnets.private.id
      lb_backend_pool_ids = [
        module.ilb_hub1_sec.backend_pool_id
      ]
      appgw_backend_pool_ids = []
    },
  ]

  virtual_machine_scale_set = {
    size  = "Standard_D3_v2"
    zones = [1,2,3]

    bootstrap_options = join(";", [for k, v in merge(
        local.bootstrap_options.common,
        local.bootstrap_options.hub1_sec_fw,
      ) : "${k}=${v}" if k !="authcodes"])
  }

  image = {
    sku     = "bundle1"
    version = local.hub1_sec_fw_ver
  }

  autoscaling_configuration = {
    application_insights_id = azurerm_application_insights.hub1_sec_fw.id
    default_count           = local.hub1_sec_fw_count
  }
  autoscaling_profiles      = [
    {
      name          = "default"
      default_count = local.hub1_sec_fw_count
      minimum_count = local.hub1_sec_fw_count
      maximum_count = local.hub1_sec_fw_count
    }
  ]

  depends_on = [ 
    azurerm_subnet_nat_gateway_association.hub1_sec_mgmt,
    panos_panorama_template_stack.hub1_sec_fw,
  ]
}
