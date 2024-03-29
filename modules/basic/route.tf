resource "azurerm_route_table" "split_mgmt" {
  for_each            = var.split_route_tables
  name                = "${var.name}-spilt-mgmt-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  disable_bgp_route_propagation = lookup(each.value, "disable_bgp_route_propagation", false)
}

resource "azurerm_route" "split_mgmt-dg" {
  for_each               = var.split_route_tables
  name                   = "dg_fw"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.split_mgmt[each.key].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = each.value["nh"]
}

locals {
  rt_nh = flatten([
    for rt, v in var.split_route_tables : [
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
  for_each            = var.split_route_tables
  name                = "${var.name}-private-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  disable_bgp_route_propagation = lookup(each.value, "disable_bgp_route_propagation", false)
}

# resource "azurerm_route" "split_private-dg" {
#   for_each               = var.split_route_tables
#   name                   = "dg"
#   resource_group_name    = var.resource_group_name
#   route_table_name       = azurerm_route_table.split_private[each.key].name
#   address_prefix         = "0.0.0.0/0"
#   next_hop_type          = "Internet"
# }

resource "azurerm_route" "split_private-172" {
  for_each               = var.split_route_tables
  name                   = "172.16.0.0_12"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.split_private[each.key].name
  address_prefix         = "172.16.0.0/12"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.split_route_tables[each.key]["nh"]
}

resource "azurerm_route" "split_private-10" {
  for_each               = var.split_route_tables
  name                   = "10.0.0.0_8"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.split_private[each.key].name
  address_prefix         = "10.0.0.0/8"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.split_route_tables[each.key]["nh"]
}

resource "azurerm_route" "split_private-192" {
  for_each               = var.split_route_tables
  name                   = "192.168.0.0_16"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.split_private[each.key].name
  address_prefix         = "192.168.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.split_route_tables[each.key]["nh"]
}

resource "azurerm_route_table" "all_fw" {
  for_each               = var.split_route_tables
  name                = "${var.name}-all-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  disable_bgp_route_propagation = lookup(each.value, "disable_bgp_route_propagation", false)
}

resource "azurerm_route" "all_fw-dg" {
  for_each               = var.split_route_tables
  name                   = "dg_fw"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.all_fw[each.key].name
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
