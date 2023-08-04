output "sg_id" {
  value = {
    mgmt      = azurerm_network_security_group.mgmt.id
    wide-open = azurerm_network_security_group.wide_open.id
  }
}

output "route_table_id" {
  value = {
    # explicit dg via internet
    all-via-igw = {
      "igw" = azurerm_route_table.all.id
    }
    # only mgmt via internet
    only-mgmt-via-igw = {
      "igw" = azurerm_route_table.mgmt.id
    }
    # mgmt to internet, dg to nh
    mgmt-via-igw = {
      for rt,v in azurerm_route_table.split_mgmt:  rt => v.id
    }
    # private to nh
    private-via-fw = {
      for rt,v in azurerm_route_table.split_private:  rt => v.id
    }
    # dg to nh
    all-via-fw = {
      for rt,v in azurerm_route_table.all_fw:  rt => v.id
    }
  }
}
