provider "azurerm" {
  features {
    virtual_machine_scale_set {
      roll_instances_when_required = false
    }
  }
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.region
}

terraform {
  required_providers {
    azurerm = {
      version = "~>4.0"
    }
    panos = {
      source = "PaloAltoNetworks/panos"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}


resource "azurerm_ssh_public_key" "this" {
  name                = var.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("~/.ssh/id_rsa.pub")
}


module "basic" {
  source = "../modules/basic"
  name   = var.name

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  mgmt_cidrs          = [for r in var.mgmt_ips : "${r.cidr}"]
  route_tables_params = {
    ilb = {
      nh = module.slb_fw_int.frontend_ip_configs.ha
    }
  }
}
