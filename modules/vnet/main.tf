resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  bgp_community       = var.bgp_community
}

resource "azurerm_virtual_network_dns_servers" "this" {
  count  = length(var.dns_servers) > 0 ? 1: 0

  virtual_network_id = azurerm_virtual_network.this.id
  dns_servers        = var.dns_servers
}

locals {
  extra_mask_bits = {
    for k, v in var.subnets: k => lookup(v, "subnet_mask_length", var.subnet_mask_length) - tonumber(split("/", azurerm_virtual_network.this.address_space[0])[1])
  }
}


resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = try(each.value.address_prefixes, [cidrsubnet(azurerm_virtual_network.this.address_space[0], local.extra_mask_bits[each.key], each.value.idx)])
  service_endpoints    = try(each.value.service_endpoints, [])
  
  dynamic "delegation" {
    for_each = try(contains(each.value.delegations, "dnsResolvers"), false) == true ? [1] : []
    content {
      name = "Microsoft.Network.dnsResolvers"
      service_delegation {
        name    = "Microsoft.Network/dnsResolvers"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
        ]
      }
    }
  }
}


resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = { for k, v in var.subnets : k => v if lookup(v, "associate_nsg", false) == true }

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = each.value.network_security_group_id
}
