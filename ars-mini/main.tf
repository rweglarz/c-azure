provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

terraform {
  required_providers {
    azurerm = {
      version = "~>4.30"
    }
    scm = {
      source  = "PaloAltoNetworks/scm"
      version = "~>1.0.7"
    }
  }
}
provider "scm" {
  auth_file = var.scm_auth_file
}


resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.region
}

resource "azurerm_ssh_public_key" "rg" {
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
    fw = {
      nh = local.private_ips.fw
      bgp_route_propagation_enabled = true
    }
  }
}

module "cfg_scm" {
  source = "./cfg-scm"
  count  = var.scm_managed ? 1 : 0

  auth_file            = var.scm_auth_file
  scm_folder           = "azure-ars"
  subnet_prefix_length = local.subnet_prefix_length
  asn                  = var.asn
  private_ips          = local.private_ips
}

