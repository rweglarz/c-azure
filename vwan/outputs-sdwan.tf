locals {
  public_interface_ids = {
    hub2_sdwan_fw1  = one([for k, v in module.hub2_sdwan_fw1.interfaces : v.ip_configuration[0].public_ip_address_id if length(regexall("internet$", v.name)) > 0])
    hub2_sdwan_fw2  = one([for k, v in module.hub2_sdwan_fw2.interfaces : v.ip_configuration[0].public_ip_address_id if length(regexall("internet$", v.name)) > 0])
    sdwan_spoke1_fw = one([for k, v in module.sdwan_spoke1_fw.interfaces : v.ip_configuration[0].public_ip_address_id if length(regexall("internet$", v.name)) > 0])
  }
  public_interface_names = {
    for k, v in local.public_interface_ids : k => element(split("/", v), length(split("/", v)) - 1)
  }
}


data "azurerm_public_ip" "sdwan_ips" {
  for_each            = local.public_interface_names
  name                = each.value
  resource_group_name = azurerm_resource_group.rg2.name
}


output "ips" {
  value = { for k, v in data.azurerm_public_ip.sdwan_ips : k => v.ip_address }
}
