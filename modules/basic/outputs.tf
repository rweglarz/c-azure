output "sg_id" {
  value = {
    mgmt      = azurerm_network_security_group.mgmt.id
    wide-open = azurerm_network_security_group.wide_open.id
  }
}

output "route_table_id" {
  value = {
    mgmt-via-igw = {
      for rt,v in azurerm_route_table.split_mgmt:  rt => v.id
    }
    private-via-fw = {
      for rt,v in azurerm_route_table.split_private:  rt => v.id
    }
    all-via-fw = {
      for rt,v in azurerm_route_table.all:  rt => v.id
    }
  }
}
