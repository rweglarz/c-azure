provider "azurerm" {
  features {
    virtual_machine_scale_set {
      roll_instances_when_required = false
    }
    # virtual_machine {
    #   skip_shutdown_and_force_delete = true
    # }
  }
  subscription_id = var.subscription_id
}

terraform {
  required_providers {
    azurerm = {
      version = "~>4.14"
    }
    google = {
      version = "~>6.14"
    }
    panos = {
      source = "PaloAltoNetworks/panos"
    }
  }
}
provider "panos" {
  json_config_file = "panorama_creds.json"
}

resource "random_id" "did" {
  byte_length = 3 #to workaround delete recreate cross regions
}
locals {
  name = "${var.name}-${random_id.did.hex}"
}



resource "azurerm_resource_group" "rg" {
  name     = local.name
  location = var.region
}

resource "azurerm_ssh_public_key" "rg" {
  name                = local.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

module "basic" {
  source = "../modules/basic"
  name   = local.name

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  mgmt_cidrs          = [for r in var.mgmt_ips : "${r.cidr}"]
  route_tables_params = {}
}
