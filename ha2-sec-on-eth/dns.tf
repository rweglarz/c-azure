resource "azurerm_dns_a_record" "this" {
  for_each = {
    "ha-fw0"  = azurerm_public_ip.mgmt[0].ip_address
    "ha-fw1"  = azurerm_public_ip.mgmt[1].ip_address
    "ha-srv0" = module.peered-srv0.public_ip
    "ha-srv1" = module.peered-srv1.public_ip
    "ha-srv5" = module.sec-srv5.public_ip
    "ha-srv6" = module.sec-srv6.public_ip
  }
  name                = each.key
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    each.value
  ]
}
