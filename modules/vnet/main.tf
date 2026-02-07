resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  bgp_community       = var.bgp_community
  tags                = var.tags
}

resource "azurerm_virtual_network_dns_servers" "this" {
  count  = length(var.dns_servers) > 0 ? 1: 0

  virtual_network_id = azurerm_virtual_network.this.id
  dns_servers        = var.dns_servers
}

locals {
  extra_mask_bits = {
    for k, v in var.subnets: k => lookup(v, "subnet_mask_length", var.subnet_mask_length) - tonumber(split("/", tolist(azurerm_virtual_network.this.address_space)[0])[1])
  }
}


resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = try(each.value.address_prefixes, [cidrsubnet(tolist(azurerm_virtual_network.this.address_space)[0], local.extra_mask_bits[each.key], each.value.idx)])
  service_endpoints    = try(each.value.service_endpoints, [])

  default_outbound_access_enabled   = try(each.value.default_outbound_access_enabled, true)
  private_endpoint_network_policies = try(each.value.private_endpoint_network_policies, "Disabled")
  private_link_service_network_policies_enabled = try(each.value.private_link_service_network_policies_enabled, false)
  
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


resource "azurerm_virtual_network_peering" "on_local" {
  for_each = var.vnet_peering

  name                      = each.value.peer_vnet_name
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = each.value.peer_vnet_id
  allow_forwarded_traffic   = try(each.value.allow_forwarded_traffic, false)
  use_remote_gateways       = try(each.value.use_remote_gateways, false)
}

resource "azurerm_virtual_network_peering" "on_remote" {
  for_each = var.vnet_peering

  name                      = azurerm_virtual_network.this.name
  resource_group_name       = var.resource_group_name
  virtual_network_name      = each.value.peer_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.this.id
  allow_gateway_transit     = try(each.value.use_remote_gateways, false)
}
