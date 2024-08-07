output "sg_id" {
  value = {
    mgmt      = azurerm_network_security_group.mgmt.id
    wide-open = azurerm_network_security_group.wide_open.id
    vpn       = azurerm_network_security_group.vpn.id
  }
}

output "route_table_id" {
  value = {
    # explicit dg via internet
    dg-via-igw = {
      "igw" = azurerm_route_table.all.id
    }
    # only mgmt via internet
    only-mgmt-via-igw = {
      "igw" = azurerm_route_table.mgmt.id
    }
    # mgmt via internet, dg via nh
    mgmt-via-igw = {
      for rt,v in azurerm_route_table.split_mgmt:  rt => v.id
    }
    mgmt-via-igw-dg-via-nh = {
      for rt,v in azurerm_route_table.split_mgmt:  rt => v.id
    }
    # private via nh, no dg
    private-via-nh = {
      for rt,v in azurerm_route_table.split_private:  rt => v.id
    }
    # dg via nh
    dg-via-nh = {
      for rt,v in azurerm_route_table.all_nh:  rt => v.id
    }
  }
}
