resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.dname}-la"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "vmss" {
  name                = "${local.dname}-app-insights-vmss"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "other"
}


resource "azurerm_lb" "hub1_fw_int" {
  name                = "${local.dname}-hub1-fw-int"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "ilb"
    subnet_id                     = module.vnet_hub1_sec.subnets["private"].id
    private_ip_address            = local.private_ip.hub1_sec_lb
    private_ip_address_allocation = "Static"
  }
}


resource "azurerm_lb_probe" "hub1_fw_int" {
  name            = "tcp-probe-54321"
  loadbalancer_id = azurerm_lb.hub1_fw_int.id
  protocol        = "Http"
  request_path    = "/unauth/php/health.php"
  port            = 54321
}


resource "azurerm_lb_backend_address_pool" "hub1_fw_int" {
  name            = "${local.dname}-hub1-fw-int"
  loadbalancer_id = azurerm_lb.hub1_fw_int.id
}


resource "azurerm_lb_rule" "hub1_fw_int" {
  name = "rule1"

  loadbalancer_id                = azurerm_lb.hub1_fw_int.id
  frontend_ip_configuration_name = "ilb"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.hub1_fw_int.id]
  probe_id                       = azurerm_lb_probe.hub1_fw_int.id

  disable_outbound_snat = true

  protocol      = "All"
  frontend_port = 0
  backend_port  = 0
}



module "hub1_vmss" {
  source = "github.com/PaloAltoNetworks/terraform-azurerm-swfw-modules//modules/vmss?ref=v3.3.8"
  # source = "../modules/vmss"

  name                = "${var.name}-hub1-fw"
  region              = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  authentication = {
    username                        = "panadmin"
    password                        = var.password
    disable_password_authentication = false
    ssh_keys                        = [azurerm_ssh_public_key.this.public_key]
  }

  interfaces = [
    {
      name              = "mgmt"
      subnet_id         =  module.vnet_hub1_sec.subnets["mgmt"].id
      ip_configurations = {
        primary = {
          primary          = true
          create_public_ip = false
        }
      }
    },
    {
      name              = "public"
      subnet_id         =  module.vnet_hub1_sec.subnets["public"].id
      create_public_ip  = true   # todo remove in 3.4.x
      ip_configurations = {
        primary = {
          primary          = true
          create_public_ip = true
        }
      }
      lb_backend_pool_ids = []
      appgw_backend_pool_ids = []
    },
    {
      name              = "private"
      subnet_id         =  module.vnet_hub1_sec.subnets["private"].id
      ip_configurations = {
        primary = {
          primary          = true
          create_public_ip = false
        }
      }
      lb_backend_pool_ids = [
        azurerm_lb_backend_address_pool.hub1_fw_int.id
      ]
      appgw_backend_pool_ids = []
    },
  ]

  virtual_machine_scale_set = {
    size  = "Standard_D3_v2"
    zones = [1,2,3]

    bootstrap_options = join(";", concat(
      [for k, v in var.bootstrap_options: "${k}=${v}"],
      [
        "tplname=${panos_panorama_template_stack.hub1.name}",
        "vm-auth-key=${panos_vm_auth_key.this.auth_key}",
      ]
    ))
  }

  image = {
    sku     = var.fw_sku
    version = var.fw_panos_version
  }

  autoscaling_configuration = {
    application_insights_id = azurerm_application_insights.vmss.id
    default_count           = 1
  }
  # autoscaling_profiles      = each.value.autoscaling_profiles
  depends_on = [
    google_compute_firewall.pan
  ]
}
