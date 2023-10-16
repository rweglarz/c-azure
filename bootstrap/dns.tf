resource "azurerm_dns_a_record" "this" {
  for_each = var.firewalls

  name                = "bs-${each.key}"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.fw[each.key].mgmt_ip_address
  ]
}
