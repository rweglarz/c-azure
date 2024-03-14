resource "azurerm_dns_a_record" "this" {
  for_each = {
    t1-onprem = module.linux_onprem.public_ip
  }
  name = each.key
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    each.value
  ]
}
