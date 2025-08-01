provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

terraform {
  required_providers {
    aws = {
      version = "~>5.58"
    }
    azurerm = {
      version = "~>4.30"
    }
    panos = {
      source = "PaloAltoNetworks/panos"
      version = "~>1.11"
    }
  }
}

provider "panos" {
  json_config_file = "panorama_creds.json"
}


resource "azurerm_resource_group" "rg1" {
  name     = "${var.name}-1"
  location = var.region1
}

resource "azurerm_ssh_public_key" "rg1" {
  name                = var.name
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

module "basic" {
  source = "../modules/basic"
  name   = var.name

  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  mgmt_cidrs          = [for r in var.mgmt_ips : "${r.cidr}"]
  route_tables_params = {
    onprem = {
      nh = local.onprem_fw["eth1_3_ip"]
    }
  }
}

resource "random_bytes" "psk" {
  length = 8
}
