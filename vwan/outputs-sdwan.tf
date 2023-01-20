data "azurerm_public_ip" "sdwan_ips" {
  for_each            = local.public_interface_names
  name                = each.value
  resource_group_name = azurerm_resource_group.rg2.name
}


output "ips" {
  value = { for k, v in data.azurerm_public_ip.sdwan_ips : k => v.ip_address }
}
