resource "azurerm_network_security_group" "mgmt" {
  name                = "${var.name}-mgmt"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                    = "management-inbound"
    priority                = 1000
    direction               = "Inbound"
    access                  = "Allow"
    protocol                = "Tcp"
    source_port_range       = "*"
    destination_port_ranges = ["443", "22"]
    source_address_prefixes = concat(
      [for r in var.mgmt_ips : "${r.cidr}"]
    )
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "all" {
  name                = "${var.name}-all"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "all"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}





resource "azurerm_route_table" "via-fw" {
  name                = "${var.name}-via-fw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "mgmt-via-ig" {
  for_each            = { for e in var.mgmt_ips : e.cidr => e.description }
  name                = replace("mgmt-${each.key}", "/[ \\/]/", "_")
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.via-fw.name
  address_prefix      = each.key
  next_hop_type       = "Internet"
}

resource "azurerm_route" "dg-via-cloud-ngfw" {
  name                   = "dg_cloud_ngfw"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.via-fw.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.cloud_ngfw_internal_ip
}


