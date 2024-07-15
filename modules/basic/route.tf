resource "azurerm_route_table" "split_mgmt" {
  for_each            = var.route_tables_params
  name                = "${var.name}-spilt-mgmt-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location

  bgp_route_propagation_enabled = try(
    each.value.bgp_route_propagation_enabled,
    !each.value.disable_bgp_route_propagation,
    true
  )
}

resource "azurerm_route" "split_mgmt-dg" {
  for_each               = var.route_tables_params
  name                   = "dg_fw"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.split_mgmt[each.key].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = each.value["nh"]
}

locals {
  rt_nh = flatten([
    for rt, v in var.route_tables_params : [
      for e in var.mgmt_cidrs : {
        uid  = format("%s-%s", rt, replace(e, "/\\//", "_"))
        name = replace(e, "/\\//", "_")
        prefix = e
        rt   = rt
        nh   = v.nh
      }
    ]
  ])
  rt_mgmt  = {for e in var.mgmt_cidrs : e => {
      name = replace(e, "/\\//", "_")
      prefix = e
    }
  }
}

resource "azurerm_route" "split_mgmt-mgmt" {
  for_each               = { for nh in local.rt_nh : nh.uid => nh }
  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.split_mgmt[each.value.rt].name
  address_prefix         = each.value.prefix
  next_hop_type          = "Internet"
}



resource "azurerm_route_table" "split_private" {
  for_each            = var.route_tables_params
  name                = "${var.name}-private-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location

  bgp_route_propagation_enabled = try(
    each.value.bgp_route_propagation_enabled,
    each.value.disable_bgp_route_propagation,
    false
  )
}

resource "azurerm_route" "split_private-172" {
  for_each               = var.route_tables_params
  name                   = "172.16.0.0_12"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.split_private[each.key].name
  address_prefix         = "172.16.0.0/12"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.route_tables_params[each.key]["nh"]
}

resource "azurerm_route" "split_private-10" {
  for_each               = var.route_tables_params
  name                   = "10.0.0.0_8"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.split_private[each.key].name
  address_prefix         = "10.0.0.0/8"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.route_tables_params[each.key]["nh"]
}

resource "azurerm_route" "split_private-192" {
  for_each               = var.route_tables_params
  name                   = "192.168.0.0_16"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.split_private[each.key].name
  address_prefix         = "192.168.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.route_tables_params[each.key]["nh"]
}

resource "azurerm_route_table" "all_nh" {
  for_each               = var.route_tables_params
  name                = "${var.name}-all-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location

  bgp_route_propagation_enabled = try(
    each.value.bgp_route_propagation_enabled,
    each.value.disable_bgp_route_propagation,
    false
  )
}

resource "azurerm_route" "all_nh-dg" {
  for_each               = var.route_tables_params
  name                   = "dg_fw"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.all_nh[each.key].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = each.value["nh"]
}


resource "azurerm_route_table" "all" {
  name                = "${var.name}-all"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_route" "all-dg" {
  name                   = "dg_fw"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.all.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "Internet"
}


resource "azurerm_route_table" "mgmt" {
  name                = "${var.name}-only-mgmt"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_route" "mgmt-mgmt" {
  for_each               = local.rt_mgmt
  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.mgmt.name
  address_prefix         = each.value.prefix
  next_hop_type          = "Internet"
}
