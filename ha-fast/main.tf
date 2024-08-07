provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    panos = {
      source = "PaloAltoNetworks/panos"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}


resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
}


resource "azurerm_ssh_public_key" "this" {
  name                = "${var.name}-key"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

module "basic" {
  source = "../modules/basic"
  name   = var.name

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  mgmt_cidrs          = [for r in var.mgmt_ips : "${r.cidr}"]
  route_tables_params = {
    fw = {
      nh = module.slb_fw_int.frontend_ip_configs.ha
    }
  }
}

resource "panos_vm_auth_key" "this" {
  hours = 24*30*6

  lifecycle { create_before_destroy = true }
}
